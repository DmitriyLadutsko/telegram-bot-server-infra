[
  {
    "id": "deploy",
    "execute-command": "/home/deploy/app/webhook/deploy.sh",
    "command-working-directory": "/home/deploy/app",
    "pass-environment-to-command": [
          { "source": "env", "name": "DOCKER_USERNAME" },
          { "source": "env", "name": "DOCKER_IMAGE_NAME" },
          { "source": "env", "name": "DOCKER_IMAGE" },
          { "source": "payload", "name": "release.tag_name", "envname": "RELEASE_TAG" }
        ],
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
            "type": "value",
            "value": "published",
            "parameter": {
              "source": "payload",
              "name": "action"
            }
          }
        },
        {
          "match": {
            "type": "payload-hmac-sha256",
            "secret": "${WEBHOOK_SECRET}",
            "parameter": {
              "source": "header",
              "name": "X-Hub-Signature-256"
            }
          }
        }
      ]
    }
  }
]
