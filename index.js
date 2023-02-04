require('dotenv').config()
const { App } = require('@slack/bolt');

const app = new App({
    token: process.env.SLACK_BOT_TOKEN,
    signingSecret: process.env.SLACK_SIGNING_SECRET,
    socketMode: true,
    appToken: process.env.SLACK_APP_TOKEN,
    port: process.env.PORT || 3000
});

app.message('hello', async ({ message, say }) => {
    await say(`Hey there <@${message.user}>!`);
});

app.command('/admin', async ({ command, ack, client, respond, logger }) => {
    await ack();

    try {
        await client.chat.postMessage({
            text: `Incoming message for admins from <@${command.user_name}> in <@${command.channel_name}>:\n${command.text}`,
            channel: "admin"
        });
        await respond(`The admins have been messaged, <@${command.user_name}>`);
    }
    catch (error) {
        await respond(`Something went wrong!\n${error}`);
    }
})

app.start()
