require('dotenv').config()
const { App } = require('@slack/bolt');

const app = new App({
    token: process.env.SLACK_BOT_TOKEN,
    signingSecret: process.env.SLACK_SIGNING_SECRET,
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
            text: `Incoming message for admins from <@${command.user_name}> in <#${command.channel_name}>:\n${command.text}`,
            channel: "admin"
        });
        await respond(`The admins have been messaged, <@${command.user_name}>`);
    }
    catch (error) {
        await respond(`Something went wrong!\n${error}`);
    }
})

app.command('/list-private', async ({ command, ack, client, respond }) => {
    await ack();

    try {
        const private_channel_ls = await client.conversations.list({ types: "private_channel" });
        const channel_names = private_channel_ls.channels.filter(e => e.name != "admin").map(e => `- ${e.name}`)
        await respond(`Current private channels:\n${channel_names.join('\n')}\nUse \`/join-private\` to request membership.`)
    }
    catch (error) {
        await respond(`Something went wrong!\n${error}`);
    }
})

app.command('/join-private', async ({ command, ack, client, respond }) => {
    await ack();

    try {
        await client.chat.postMessage({
            text: `<@${command.user_name}> wishes to join this channel. Use \`/invite <@${command.user_name}>\` to let them in`,
            channel: command.text
        })
        await respond(`The channel have been messaged, <@${command.user_name}>, your invitation is being reviewed.`);
    }
    catch (error) {
        await respond(`Something went wrong!\n${error}`);
    }
})

app.start()
