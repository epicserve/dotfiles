// Navigate the open Slack web app window to deep links handed over from Zen,
// instead of letting Chromium open a second --app window.
//
// One native-messaging port stays connected for the life of the browser and
// Chrome keeps this service worker alive while it is open. The host pushes a
// {url} whenever the Zen side leaves a pending deep link, so nothing polls.

const HOST = "com.omarchy.webapp_url_router";
const RETRY_MS = 5000;

let port = null;

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
  if (port) {
    return;
  }
  port = chrome.runtime.connectNative(HOST);
  port.onMessage.addListener((msg) => {
    if (msg && msg.url) {
      navigate(msg.url).catch((e) => console.error("webapp-url-router:", e));
    }
  });
  port.onDisconnect.addListener(() => {
    console.warn("webapp-url-router: port closed", chrome.runtime.lastError?.message || "");
    port = null;
    setTimeout(connect, RETRY_MS);
  });
  port.postMessage({ watch: true });
}

// Chrome only starts a service worker for events it has listeners for, so a
// worker that merely opens a port at top level is never woken at browser
// launch. These make it start on every launch and on (re)install.
chrome.runtime.onStartup.addListener(connect);
chrome.runtime.onInstalled.addListener(connect);
connect();
