// Intercept Slack deep links in Zen and hand them to the Slack Chromium web
// app (via the native host -> omarchy-launch-webapp). The request is cancelled
// so a GitHub/Jira tab is not replaced, and a blank new tab is closed.

const HOST = "com.omarchy.webapp_url_router";

const EXCLUDE_HOSTS = new Set([
  "api.slack.com",
  "status.slack.com",
  "docs.slack.com",
  "www.slack.com",
  "files.slack.com",
]);

const APEX_PATH_PREFIXES = [
  "/app_redirect",
  "/archives",
  "/messages",
  "/client",
];

function isSlackWebappUrl(url) {
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
    return false;
  }
  const host = parsed.hostname.toLowerCase();
  if (host === "app.slack.com") {
    return true;
  }
  if (EXCLUDE_HOSTS.has(host)) {
    return false;
  }
  if (host === "slack.com") {
    return APEX_PATH_PREFIXES.some((prefix) => parsed.pathname.startsWith(prefix));
  }
  return host.endsWith(".slack.com");
}

async function launchAndCleanup(tabId, url) {
  try {
    await browser.runtime.sendNativeMessage(HOST, { url });
  } catch (e) {
    console.error("webapp-url-router: native host failed, loading in Zen", e);
    try {
      await browser.tabs.update(tabId, { url });
    } catch {
      // Tab already gone.
    }
    return;
  }

  try {
    const tab = await browser.tabs.get(tabId);
    const tabUrl = tab.url || tab.pendingUrl || "";
    if (
      !tabUrl ||
      tabUrl === "about:blank" ||
      tabUrl.startsWith("about:newtab") ||
      tabUrl.startsWith("about:home") ||
      tabUrl.startsWith("about:privatebrowsing") ||
      tabUrl.startsWith("chrome://") ||
      tabUrl.startsWith("about:zen")
    ) {
      await browser.tabs.remove(tabId);
    }
  } catch {
    // Tab already gone.
  }
}

browser.webRequest.onBeforeRequest.addListener(
  (details) => {
    if (details.type !== "main_frame" || details.tabId < 0) {
      return;
    }
    if (!isSlackWebappUrl(details.url)) {
      return;
    }
    launchAndCleanup(details.tabId, details.url);
    return { cancel: true };
  },
  {
    urls: ["*://app.slack.com/*", "*://*.slack.com/*", "*://slack.com/*"],
  },
  ["blocking"]
);
