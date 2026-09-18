// Hand Slack deep links clicked in Zen to the Slack Chromium web app via the
// native host. The request is cancelled so the page the link was clicked on
// stays put; a tab that was opened only for the link is closed.

const HOST = "com.omarchy.webapp_url_router";

// Tabs allowed one un-intercepted load, after the hand-off failed.
const bypass = new Set();

async function handOff(tabId, url) {
  let ok = false;
  try {
    ok = (await browser.runtime.sendNativeMessage(HOST, { url })).ok;
  } catch (e) {
    console.error("webapp-url-router: native host failed", e);
  }
  if (!ok) {
    bypass.add(tabId);
    browser.tabs.update(tabId, { url }).catch(() => bypass.delete(tabId));
    return;
  }
  try {
    const tab = await browser.tabs.get(tabId);
    if (!tab.url || tab.url.startsWith("about:")) {
      await browser.tabs.remove(tabId);
    }
  } catch {
    // Tab already gone.
  }
}

browser.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (details.tabId < 0 || bypass.delete(details.tabId)) {
      return {};
    }
    handOff(details.tabId, details.url);
    return { cancel: true };
  },
  {
    urls: [
      "*://app.slack.com/*",
      "*://*.slack.com/archives/*",
      "*://*.slack.com/messages/*",
    ],
    types: ["main_frame"],
  },
  ["blocking"]
);
