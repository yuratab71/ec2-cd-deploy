const https = require("node:https");

const REQUEST_MAX_DELAY = 10000

function build_message(host, path, size) {
  return {
    hostname: host,
    path: path,
    method: "POST",
    headers: {
          "Content-Type": "application/json",
          "Content-Length": size
        }
  }
}

function send_message(path, message) {
  return new Promise((resolve, reject) => {
    const url = new URL(path);

    const body = JSON.stringify({
      username: "AWS CloudWatch",
      embeds: [
        {
          title: message.title,
          description: message.description,
          color: message.color,
          fields: message.fields,
          timestamp: new Date().toISOString()
        }
      ]
    });

    const request = https.request(
      build_message(url.hostname, String(url.pathname + url.search), Buffer.byteLength(body)),
      (res) => {
        let body = "";

        res.on("data", (chunk) => {
          body += chunk;
        });

        res.on("end", () => {
          if (res.statusCode > 300) {
            reject(new Error("Discord returned error status code: ${res.statusCode}"))
          } else {
            resolve();
          }
        });
      }
    );

    request.on("error", reject);

    request.setTimeout(REQUEST_MAX_DELAY, () => {
      request.destroy(new Error("Timeout"));
    });

    request.end(body);
  });
}

/* TESTING
const event = {
  Records: [
    {
      Sns: {
        Message: `{
      "AlarmName": "test",
      "AlarmDescription": "test",
      "NewStateValue": "ALARM",
      "OldStateValue": "OK",
      "NewStateReason": "manual",
      "Region": "us-east-1"
    }`
      }
    }
  ]
}

const DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/<id>/<hash_or_smth>"
*/

exports.handler = async (event) => {
  const path = process.env.DISCORD_WEBHOOK_URL;

  if (!path) {
    throw new Error("DISCORD_WEBHOOK_URL is not defined");
  }

  for (const record of event.Records ?? []) {
    const message = JSON.parse(record.Sns.Message);

    await send_message(path, {
      title: String(message.AlarmName ?? "Unknown"),
      description: String(message.AlarmDescription),
      color: 0xf00,
      fields: [
        {
          name: "State",
          value: String(message.NewStateValue ?? "UNKNOWN"),
          inline: true
        },
        {
          name: "Reason",
          value: String(message.NewStateReason ?? "Unknown")
          .slice(0, 1000)
        }
      ]
    });
  }
};
