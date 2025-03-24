const express = require("express");
const crypto = require("crypto");
const { exec } = require("child_process");
const fs = require("fs");

const app = express();
const PORT = 9000;
const SECRET = process.env.WEBHOOK_SECRET || "super-secret";
const LOG_FILE = "/app/deploy.log";

app.use(express.json({ verify: bufferSaver }));

function bufferSaver(req, res, buf) {
  req.rawBody = buf;
}

app.post("/github-webhook", (req, res) => {
  const signature = req.headers["x-hub-signature-256"];
  const payload = req.rawBody;

  if (!verifySignature(payload, signature, SECRET)) {
    log("⚠️ Invalid signature attempt");
    return res.status(403).send("Invalid signature");
  }

  const event = req.headers["x-github-event"];
  if (event !== "release") {
    log(`📦 Ignored event: ${event}`);
    return res.status(200).send("Ignored");
  }

  if (req.body.action !== "published") {
    log(`🔕 Release event ignored (action = ${req.body.action})`);
    return res.status(200).send("Ignored");
  }

  const releaseName = req.body.release.name || "Unnamed release";
  const tag = req.body.release.tag_name;

  log(`🚀 Published release: ${releaseName} [${tag}]. Starting deploy...`);

  exec("docker-compose pull bot && docker-compose up -d bot", (err, stdout, stderr) => {
    if (err) {
      log(`❌ Deploy failed:\n${stderr}`);
      return res.status(500).send("Deploy failed");
    }

    log(`✅ Deploy succeeded:\n${stdout}`);
    res.status(200).send("Deploy complete");
  });
});

function verifySignature(payload, signature, secret) {
  if (!signature) return false;
  const hmac = crypto.createHmac("sha256", secret);
  const digest = "sha256=" + hmac.update(payload).digest("hex");
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

function log(message) {
  const time = new Date().toISOString();
  const full = `[${time}] ${message}\n`;
  console.log(full);
  fs.appendFileSync(LOG_FILE, full);
}

app.listen(PORT, () => {
  console.log(`📡 Webhook listener is running on port ${PORT}`);
});
