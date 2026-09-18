#!/usr/bin/env python3
"""Launch matching URLs in an Omarchy Chromium web app.

Invocation modes:

- Native messaging (no args, 4-byte length-prefixed JSON on stdin):
    {url: ...}     Zen extension handing off a Slack link
    {action: take} Chromium extension consuming a pending deep link
- CLI / .desktop Exec (optional URL argument, including %u / slack://)
"""
from __future__ import annotations

import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlparse

# Keep in sync with the omarchy-webapp-install URL in setup_omarchy.sh.
SLACK_DEFAULT_URL = "https://app.slack.com/client/T07NZL2HG/C07NZPX4H"

SLACK_EXCLUDE_HOSTS = {
    "api.slack.com",
    "status.slack.com",
    "docs.slack.com",
    "www.slack.com",
    "files.slack.com",
}

SLACK_APEX_PATH_PREFIXES = (
    "/app_redirect",
    "/archives",
    "/messages",
    "/client",
)

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "webapp-url-router"
PENDING_FILE = STATE_DIR / "pending.json"


def slack_team_id() -> str:
    parts = [p for p in urlparse(SLACK_DEFAULT_URL).path.split("/") if p]
    # https://app.slack.com/client/T07NZL2HG/C07NZPX4H
    if len(parts) >= 2 and parts[0] == "client":
        return parts[1]
    return ""


def slack_home_channel() -> str:
    parts = [p for p in urlparse(SLACK_DEFAULT_URL).path.split("/") if p]
    if len(parts) >= 3 and parts[0] == "client":
        return parts[2]
    return ""


def permalink_timestamp(token: str) -> str | None:
    """Convert Slack's p1788559973259499 permalink to 1788559973.259499."""
    if not token.startswith("p") or not token[1:].isdigit() or len(token) < 8:
        return None
    digits = token[1:]
    return f"{digits[:-6]}.{digits[-6:]}"


def canonicalize_slack_url(url: str) -> str:
    """Keep deep links on app.slack.com so Chromium --app stays in one window."""
    parsed = urlparse(url)
    host = (parsed.hostname or "").lower()
    parts = [p for p in parsed.path.split("/") if p]
    query = parse_qs(parsed.query)
    team = slack_team_id()
    channel = None
    message = None

    if host == "app.slack.com" and parts[:1] == ["client"] and len(parts) >= 3:
        if not team:
            return url
        channel = parts[2]
        extra = parts[3:]
        dest = f"https://app.slack.com/client/{team}/{channel}"
        if extra:
            dest += "/" + "/".join(extra)
        return dest

    if parts[:1] == ["archives"] and len(parts) >= 2:
        channel = parts[1]
        if len(parts) >= 3:
            message = permalink_timestamp(parts[2])
    elif parts[:1] == ["messages"] and len(parts) >= 2:
        channel = parts[1]
    elif parts[:1] == ["client"] and len(parts) >= 3:
        channel = parts[2]
        if len(parts) >= 4:
            message = parts[3]

    if not channel or not team:
        return url if host == "app.slack.com" else SLACK_DEFAULT_URL

    dest = f"https://app.slack.com/client/{team}/{channel}"
    thread_ts = (query.get("thread_ts") or [None])[0]
    if thread_ts:
        dest += f"/thread/{channel}-{thread_ts}"
    elif message:
        dest += f"/{message}"
    return dest


def is_slack_webapp_url(url: str) -> bool:
    try:
        parsed = urlparse(url)
    except ValueError:
        return False
    if parsed.scheme not in ("http", "https"):
        return False
    host = parsed.hostname.lower() if parsed.hostname else ""
    if host == "app.slack.com":
        return True
    if host in SLACK_EXCLUDE_HOSTS:
        return False
    if host in ("slack.com",):
        return parsed.path.startswith(SLACK_APEX_PATH_PREFIXES)
    return host.endswith(".slack.com")


def slack_url_from_protocol(url: str) -> str | None:
    """Map slack:// deep links to an https URL the web app can load."""
    try:
        parsed = urlparse(url)
    except ValueError:
        return None
    if parsed.scheme != "slack":
        return None
    query = parse_qs(parsed.query)
    team = (query.get("team") or [None])[0]
    channel = (query.get("id") or [None])[0]
    message = (query.get("message") or [None])[0]
    if team and channel:
        dest = f"https://app.slack.com/client/{team}/{channel}"
        if message:
            dest += f"/{message}"
        return dest
    return SLACK_DEFAULT_URL


def resolve_url(raw: str | None) -> str | None:
    if not raw:
        return SLACK_DEFAULT_URL
    url = unquote(raw).strip()
    if url.startswith("slack:"):
        return slack_url_from_protocol(url)
    if is_slack_webapp_url(url):
        return canonicalize_slack_url(url)
    return None


def launch(url: str) -> bool:
    launcher = shutil.which("omarchy-launch-webapp") or "/usr/share/omarchy/bin/omarchy-launch-webapp"
    if not os.path.isfile(launcher):
        return False
    subprocess.Popen(
        [launcher, url],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return True


def hypr_clients() -> list[dict]:
    try:
        raw = subprocess.check_output(["hyprctl", "clients", "-j"], text=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def find_slack_window() -> dict | None:
    matches = []
    for client in hypr_clients():
        cls = (client.get("class") or "").lower()
        if "slack.com" not in cls:
            continue
        if not (cls.startswith("chrome-") or cls.startswith("chromium")):
            continue
        matches.append(client)
    if not matches:
        return None
    home = slack_home_channel().lower()
    if home:
        for client in matches:
            if home in (client.get("class") or "").lower():
                return client
    preferred = [c for c in matches if "app.slack.com" in (c.get("class") or "").lower()]
    return (preferred or matches)[0]


def focus_window(client: dict) -> None:
    address = client.get("address")
    if not address:
        return
    target = f"address:{address}"
    cmd = ["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "{target}" }})']
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (FileNotFoundError, subprocess.CalledProcessError):
        subprocess.run(
            ["hyprctl", "dispatch", "focuswindow", target],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def write_pending(url: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    payload = json.dumps({"url": url}).encode()
    fd, tmp_name = tempfile.mkstemp(dir=STATE_DIR, prefix="pending.", suffix=".tmp")
    try:
        os.write(fd, payload)
        os.fsync(fd)
    finally:
        os.close(fd)
    os.replace(tmp_name, PENDING_FILE)


def take_pending() -> str | None:
    try:
        data = json.loads(PENDING_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None
    try:
        PENDING_FILE.unlink()
    except OSError:
        pass
    url = data.get("url") if isinstance(data, dict) else None
    return url if isinstance(url, str) and url else None


def open_in_slack(url: str) -> bool:
    existing = find_slack_window()
    if not existing:
        return launch(url)
    # Never launch a second --app window. The Chromium extension navigates the
    # existing tab; that only works in a Chromium process started after the
    # extension was added to chromium-flags.conf.
    write_pending(url)
    focus_window(existing)
    return True


def native_reply(payload: dict) -> None:
    encoded = json.dumps(payload).encode()
    sys.stdout.buffer.write(struct.pack("<I", len(encoded)) + encoded)
    sys.stdout.buffer.flush()


def native_mode(length_prefix: bytes) -> int:
    msg_len = struct.unpack("<I", length_prefix)[0]
    raw = sys.stdin.buffer.read(msg_len)
    try:
        msg = json.loads(raw)
    except json.JSONDecodeError:
        native_reply({"ok": False, "error": "invalid json"})
        return 1
    if msg.get("action") == "take":
        native_reply({"url": take_pending()})
        return 0
    url = resolve_url(msg.get("url"))
    ok = bool(url) and open_in_slack(url)
    native_reply({"ok": ok})
    return 0 if ok else 1


def cli_mode(arg: str | None) -> int:
    if not arg:
        existing = find_slack_window()
        if existing:
            focus_window(existing)
            return 0
        if not launch(SLACK_DEFAULT_URL):
            print("webapp-url-router: omarchy-launch-webapp not found", file=sys.stderr)
            return 1
        return 0
    url = resolve_url(arg)
    if not url:
        print(f"webapp-url-router: not a Slack web app URL: {arg}", file=sys.stderr)
        return 1
    if not open_in_slack(url):
        print("webapp-url-router: omarchy-launch-webapp not found", file=sys.stderr)
        return 1
    return 0


def cli_args(argv: list[str]) -> list[str]:
    # Chrome and Firefox launch the native host as `host.py <extension-origin>`.
    # That origin is not a Slack URL; treating it as CLI made every
    # sendNativeMessage exit before reading stdin, so pending deep links
    # were never consumed.
    return [
        a
        for a in argv[1:]
        if not a.startswith(("chrome-extension://", "moz-extension://"))
    ]


def main() -> int:
    args = cli_args(sys.argv)
    if args:
        if args[0] in ("-h", "--help"):
            print("Usage: webapp-url-router [slack-url]")
            return 0
        if args[0] == "--test-match":
            target = args[1] if len(args) > 1 else ""
            resolved = resolve_url(target)
            print(resolved if resolved else "no")
            return 0
        return cli_mode(args[0])

    peek = sys.stdin.buffer.read(4)
    if len(peek) == 4:
        return native_mode(peek)
    return cli_mode(None)


if __name__ == "__main__":
    raise SystemExit(main())
