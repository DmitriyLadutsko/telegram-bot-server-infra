[
  {
    "id": "deploy-${BOT_DOCKER_SERVICE_NAME}",
    "execute-command": "${APP_DIR}/webhook/deploy.sh",
    "command-working-directory": "${APP_DIR}/bots/${BOT_DOCKER_SERVICE_NAME}",
    "pass-arguments-to-command": [
          { "source": "string", "name": "${APP_DIR}" },
          { "source": "string", "name": "${BOT_DOCKER_SERVICE_NAME}" }
        ],
    "pass-environment-to-command": [
          { "source": "payload", "name": "release.tag_name", "envname": "RELEASE_TAG" },
          { "source": "payload", "name": "repository.name", "envname": "REPOSITORY_NAME" }
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
