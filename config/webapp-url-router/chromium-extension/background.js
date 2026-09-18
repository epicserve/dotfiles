// Navigate the open Slack web app window to deep links handed over from Zen,
// instead of letting Chromium open a second --app window.
//
// One native-messaging port stays connected for the life of the browser and
// Chrome keeps this service worker alive while it is open. The host pushes a
// {url} whenever the Zen side leaves a pending deep link, so nothing polls.

const HOST = "com.omarchy.webapp_url_router";
const RETRY_MS = 5000;

async function slackTab() {
  const tabs = await chrome.tabs.query({ url: "*://*.slack.com/*" });
  return tabs.find((tab) => (tab.url || "").startsWith("https://app.slack.com/")) || tabs[0];
}

async function navigate(url) {
  const tab = await slackTab();
  if (tab && tab.url !== url) {
    await chrome.tabs.update(tab.id, { url, active: true });
  }
}

function connect() {
  const port = chrome.runtime.connectNative(HOST);
  port.onMessage.addListener((msg) => {
    if (msg && msg.url) {
      navigate(msg.url).catch((e) => console.error("webapp-url-router:", e));
    }
  });
  port.onDisconnect.addListener(() => setTimeout(connect, RETRY_MS));
  port.postMessage({ watch: true });
}

connect();
