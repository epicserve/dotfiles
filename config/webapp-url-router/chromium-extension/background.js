// Consume a pending Slack deep link and navigate the existing web app tab.
// The native host writes the URL when a Slack window is already open.

const HOST = "com.omarchy.webapp_url_router";

function isSlackTab(tab) {
  const url = tab.url || tab.pendingUrl || "";
  return url.includes("slack.com");
}

async function slackTabId(preferredId) {
  if (preferredId != null) {
    try {
      const tab = await chrome.tabs.get(preferredId);
      if (isSlackTab(tab)) {
        return tab.id;
      }
    } catch {
      // Tab went away; fall through to a search.
    }
  }
  const tabs = await chrome.tabs.query({});
  const slack = tabs.filter(isSlackTab);
  const preferred =
    slack.find((tab) => (tab.url || "").includes("app.slack.com")) || slack[0];
  return preferred ? preferred.id : null;
}

let taking = false;

async function consume(preferredId) {
  if (taking) {
    return;
  }
  taking = true;
  try {
    let resp;
    try {
      resp = await chrome.runtime.sendNativeMessage(HOST, { action: "take" });
    } catch (e) {
      console.error("webapp-url-router: native host take failed", e);
      return;
    }
    const url = resp && resp.url;
    if (!url) {
      return;
    }
    const tabId = await slackTabId(preferredId);
    if (tabId == null) {
      return;
    }
    try {
      const tab = await chrome.tabs.get(tabId);
      if ((tab.url || "") === url) {
        return;
      }
    } catch {
      return;
    }
    await chrome.tabs.update(tabId, { url, active: true });
  } finally {
    taking = false;
  }
}

chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (!msg || msg.action !== "consume") {
    return;
  }
  consume(sender.tab && sender.tab.id).then(() => sendResponse({ ok: true }));
  return true;
});

chrome.windows.onFocusChanged.addListener((windowId) => {
  if (windowId !== chrome.windows.WINDOW_ID_NONE) {
    consume();
  }
});

chrome.tabs.onActivated.addListener(() => consume());

chrome.alarms.create("consume", { periodInMinutes: 0.05 });
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "consume") {
    consume();
  }
});
