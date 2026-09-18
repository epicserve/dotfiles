#!/usr/bin/env python3
"""Open Slack links in the Omarchy Slack Chromium web app.

One script, three ways in, told apart by what arrives on stdin:

- Zen extension (sendNativeMessage): one framed {"url": ...}. The link is
  rewritten to an app.slack.com/client URL and either pushed into the open
  Slack window or launched as a new web app window.
- Chromium extension (connectNative): one framed {"watch": true}, after which
  the process lives as long as the port and pushes {"url": ...} whenever the
  Zen side leaves a deep link in the pending file.
- Slack.desktop Exec (nothing on stdin): focus the Slack window or launch it.

Browsers pass their own argv (Chromium the extension origin, Firefox the
manifest path and add-on id), so argv is ignored.
"""
from __future__ import annotations

import fcntl
import json
import os
import select
import shutil
import struct
import subprocess
import sys
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# Keep in sync with SLACK_URL in scripts/setup_webapp_url_router.sh.
SLACK_URL = "https://app.slack.com/client/T07NZL2HG/C07NZPX4H"
SLACK_CLIENT = SLACK_URL.rsplit("/", 1)[0]

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "webapp-url-router"
PENDING = STATE_DIR / "pending.url"
WATCHER_LOCK = STATE_DIR / "watcher.lock"


def canonicalize(url: str) -> str:
    """Rewrite a Slack link to the app.slack.com/client form.

    Workspace permalinks (team.slack.com/archives/C.../p...) redirect to a
    login / "open in the app" interstitial; the client form loads straight
    into the web app and keeps every deep link on one origin.
    """
    parsed = urlparse(url)
    if parsed.hostname == "app.slack.com":
        return url
    parts = [p for p in parsed.path.split("/") if p]
    if len(parts) < 2 or parts[0] not in ("archives", "messages"):
        return SLACK_URL
    channel = parts[1]
    dest = f"{SLACK_CLIENT}/{channel}"
    thread_ts = parse_qs(parsed.query).get("thread_ts", [""])[0]
    if thread_ts:
        return f"{dest}/thread/{channel}-{thread_ts}"
    if len(parts) >= 3 and parts[2].startswith("p") and parts[2][1:].isdigit():
        ts = parts[2][1:]  # p1788559973259499 -> 1788559973.259499
        return f"{dest}/{ts[:-6]}.{ts[-6:]}"
    return dest


def hyprctl(*args: str) -> str:
    try:
        return subprocess.run(["hyprctl", *args], capture_output=True, text=True, check=True).stdout
    except (FileNotFoundError, subprocess.CalledProcessError):
        return ""


def slack_window() -> str | None:
    """Hyprland address of the Chromium --app Slack window, if one is open."""
    try:
        clients = json.loads(hyprctl("clients", "-j") or "[]")
    except json.JSONDecodeError:
        return None
    for client in clients:
        cls = client.get("class", "")
        if cls.startswith("chrome-") and "slack.com" in cls:
            return client.get("address")
    return None


def focus(address: str) -> None:
    target = f"address:{address}"
    if not hyprctl("dispatch", f'hl.dsp.focus({{ window = "{target}" }})'):
        hyprctl("dispatch", "focuswindow", target)


def launch(url: str) -> bool:
    launcher = shutil.which("omarchy-launch-webapp") or "/usr/share/omarchy/bin/omarchy-launch-webapp"
    if not os.path.isfile(launcher):
        return False
    subprocess.Popen([launcher, url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return True


def watcher_alive() -> bool:
    """True while a Chromium extension port holds the watcher lock."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with open(WATCHER_LOCK, "a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return True
    return False


def open_in_slack(url: str) -> bool:
    address = slack_window()
    if address and watcher_alive():
        # The Chromium extension navigates the open window; never start a
        # second --app window for a deep link.
        tmp = PENDING.with_suffix(".tmp")
        tmp.write_text(url)
        tmp.replace(PENDING)
        focus(address)
        return True
    # No Slack window, or Chromium predates the extension being added to
    # chromium-flags.conf: a fresh window still beats a link that goes nowhere.
    return launch(url)


def read_message() -> dict | None:
    head = sys.stdin.buffer.read(4)
    if len(head) < 4:
        return None
    (length,) = struct.unpack("<I", head)
    try:
        msg = json.loads(sys.stdin.buffer.read(length))
    except json.JSONDecodeError:
        return {}
    return msg if isinstance(msg, dict) else {}


def send_message(msg: dict) -> None:
    body = json.dumps(msg).encode()
    sys.stdout.buffer.write(struct.pack("<I", len(body)) + body)
    sys.stdout.buffer.flush()


def watch() -> int:
    """Hold the Chromium port open and push pending deep links through it."""
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    lock = open(WATCHER_LOCK, "a")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 1  # another port is already watching
    while True:
        readable, _, _ = select.select([sys.stdin], [], [], 0.25)
        if readable and not os.read(sys.stdin.fileno(), 4096):
            return 0  # Chromium closed the port
        if PENDING.is_file():
            url = PENDING.read_text().strip()
            PENDING.unlink()
            if url:
                try:
                    send_message({"url": url})
                except BrokenPipeError:
                    return 0


def main() -> int:
    msg = None if sys.stdin is None or sys.stdin.isatty() else read_message()
    if msg is None:
        # Launcher / Slack.desktop: focus the open window or start one.
        address = slack_window()
        if address:
            focus(address)
            return 0
        return 0 if launch(SLACK_URL) else 1
    if msg.get("watch"):
        return watch()
    url = msg.get("url")
    ok = isinstance(url, str) and url.startswith(("http://", "https://")) and open_in_slack(canonicalize(url))
    send_message({"ok": bool(ok)})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
