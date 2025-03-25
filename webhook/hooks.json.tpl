[
  {
    "id": "deploy",
    "execute-command": "/home/deploy/app/webhook/deploy.sh",
    "command-working-directory": "/home/deploy/app",
    "pass-arguments-to-command": [],
    "trigger-rule": {
      "and": [
        {
          "match": {
            "type": "value",
            "value": "release",
            "parameter": {
              "source": "header",
              "name": "X-GitHub-Event"
            }
          }
        },
        {
          "match": {
            "type": "regex",
            "regex": "released",
            "parameter": {
              "source": "payload",
              "name": "action"
            }
          }
        },
        {
          "match": {
            "type": "payload-hash-sha256",
            "secret": "${WEBHOOK_SECRET}"
          }
        }
      ]
    }
  }
]
