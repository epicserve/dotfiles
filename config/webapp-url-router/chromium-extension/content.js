// Runs in the Slack --app window. Poll while visible so a pending deep link
// is consumed even when Hyprland focus does not fire visibilitychange.
function ping() {
  chrome.runtime.sendMessage({ action: "consume" }).catch(() => {});
}

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "visible") {
    ping();
  }
});
window.addEventListener("focus", ping);

if (document.visibilityState === "visible") {
  ping();
}

setInterval(() => {
  if (document.visibilityState === "visible") {
    ping();
  }
}, 400);
