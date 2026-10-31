// PEARS links: the focused PEARS worktree's service UIs (web, API docs, Mailpit, ...)
// on the host ports its .env assigns (HOST_PORT_*, DOMAIN), falling back to the repo's
// docker-compose.ports.defaults. A worktree is any folder holding that defaults file.
//
// Docked in a layout: the whole status bar, standing in for the shipped
// workspace-status (machine, branch, agents on the left, the command palette hint
// flush right) with the links just left of that hint. Opened as an overlay
// (`mod.open:pears-links`): a list with the full URLs. Click a link to open it in
// the browser. A green dot means something is listening on that port.
import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { spaces, panes, focused, agents, exec, run, readTextFile, theme, props, closeOverlay, window, notify } from "herdr";

const MARKER = "docker-compose.ports.defaults";
// `key`: the popup's one-letter shortcut (j and k stay free for moving).
const SERVICES = [
  { id: "web", key: "w", label: "Web", port: "HOST_PORT_WEB", domain: true, path: "/" },
  { id: "api-docs", key: "a", label: "API docs", port: "HOST_PORT_WEB", domain: true, path: "/api/v1/docs/" },
  { id: "mailpit", key: "m", label: "Mailpit", port: "HOST_PORT_MAILPIT_UI", path: "/" },
  { id: "silo", key: "s", label: "Silo", port: "HOST_PORT_MINIO_CONSOLE", path: "/" },
  { id: "flower", key: "f", label: "Flower", port: "HOST_PORT_FLOWER", path: "/" },
  { id: "mkdocs", key: "d", label: "Docs", port: "HOST_PORT_PYDOCS", path: "/" },
  { id: "playwright", key: "p", label: "Playwright", port: "HOST_PORT_PLAYWRIGHT_UI", path: "/" },
];
// Connects to each port and prints the ones that answer. Bare connects, no HTTP request,
// so runserver and the rest log nothing.
const PROBE = 'for p; do (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null && echo "$p"; done';

// Where the focused terminal is, as the shipped Changes panel decides it.
function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder || null, on };
}

// KEY=value lines, last one wins, surrounding quotes dropped (like bin/worktree.sh env_read).
function parseEnv(text) {
  const vars = {};
  for (const line of (text ?? "").split("\n")) {
    const m = /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/.exec(line.trim());
    if (m) vars[m[1]] = m[2].replace(/^(["'])(.*)\1$/, "$2");
  }
  return vars;
}

async function findRoot(cwd) {
  let dir = cwd.replace(/\/+$/, "") || "/";
  for (let i = 0; i < 16; i++) {
    const marker = await readTextFile(`${dir}/${MARKER}`).catch(() => null);
    if (marker !== null) return { root: dir, defaults: marker };
    if (dir === "/") return null;
    dir = dir.slice(0, dir.lastIndexOf("/")) || "/";
  }
  return null;
}

function openUrl(url) {
  const mac = window()?.platform === "macos";
  // setsid -f: the browser must not be a child of this exec, which has a 30 s limit.
  const [cmd, args] = mac ? ["open", [url]] : ["setsid", ["-f", "xdg-open", url]];
  exec(cmd, args)
    .then((r) => { if (r.code !== 0) throw new Error(r.stderr.trim() || `${cmd} exited ${r.code}`); })
    .catch((e) => notify({ title: "Couldn't open link", body: `${url}\n${e?.message ?? e}`, level: "error" }));
}

export default class PearsLinks extends View {
  init(_props, cx) {
    this.context = null; // the location the links below belong to
    this.root = null;
    this.links = [];
    this.remote = false;
    this.ticks = 0;
    this.at = 0; // the highlighted row in the popup
    if (props()?.overlay) {
      // Only the popup takes the keyboard; the docked bar never does.
      this.handle = cx.focus_handle();
      this.handle.focus();
      // As the shipped picker does: focus again once the popup has finished opening.
      cx.timer.after(600, () => this.handle.focus());
    }
    this.refresh(cx);
    // Cheap check every second so switching spaces updates quickly; .env and ports every 5 s.
    cx.timer.every(1000, (cx) => {
      this.ticks += 1;
      if (JSON.stringify(location()) !== this.context || this.ticks % 5 === 0) this.refresh(cx);
    });
  }

  refresh(cx) {
    if (this.loading) return;
    const where = location(), context = JSON.stringify(where);
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const changed = context !== this.context;
        this.context = context;
        if (changed) { this.root = null; this.links = []; }
        this.remote = Boolean(where.on);
        if (!where.cwd || where.on) { this.root = null; this.links = []; return; }

        const found = await findRoot(where.cwd);
        if (!found) { this.root = null; this.links = []; return; }
        const defaults = parseEnv(found.defaults);
        const env = { ...defaults, ...parseEnv(await readTextFile(`${found.root}/.env`).catch(() => null)) };
        const links = SERVICES.flatMap((s) => {
          const port = env[s.port];
          if (!/^\d+$/.test(port ?? "")) return [];
          const host = (s.domain && env.DOMAIN) || `127.0.0.1:${port}`;
          return [{ ...s, number: port, url: `http://${host}${s.path}` }];
        });

        const ports = [...new Set(links.map((l) => l.number))];
        const probe = await exec("bash", ["-c", PROBE, "probe", ...ports]).catch(() => null);
        const up = new Set((probe?.stdout ?? "").split("\n").filter(Boolean));
        if (JSON.stringify(location()) !== context) return; // moved on while we looked
        this.root = found.root;
        this.links = links.map((l) => ({ ...l, up: up.has(l.number) }));
      } finally {
        this.loading = false;
        cx.notify();
      }
    });
  }

  render() {
    return props()?.overlay ? this.renderList() : this.renderBar();
  }

  renderBar() {
    const t = theme();
    // Left side copied from the shipped workspace-status mod (Herdr app 0.1.10): one
    // mod draws the whole row so the palette hint stays flush right with or without links.
    const space = spaces().find((s) => s.active);
    const list = agents();
    const needs = list.filter((a) => a.status === "blocked").length;
    const label = (icon, text) => h_flex().flex_none().gap(6).items_center()
      .child(svg(`mods/workspace-chrome/${icon}.svg`).size(13)).child(text);
    const links = h_flex().flex_1().gap(14).items_center().justify_end().overflow_hidden();
    return h_flex().id("pears-links").size_full().px(14).gap(16).items_center().overflow_hidden()
      .bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine ?? "This computer"))
      .when(Boolean(space?.branch), (el) => el.child(label("branch", space.branch)))
      .child(h_flex().flex_none().gap(6).items_center().child(div().size(6).rounded(3).bg(t.dim)).child(`${list.length} agents`)
        .when(needs > 0, (el) => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))))
      .child(this.root
        ? links.children(this.links.map((l) =>
          h_flex().id(`bar-${l.id}`).flex_none().gap(6).items_center().cursor_pointer()
            .tooltip(l.url)
            .hover((s) => s.text_color(t.foreground))
            .on_click(() => openUrl(l.url))
            .child(div().size(6).rounded(3).bg(l.up ? t.ansi2 : t.dim))
            .child(l.label)))
        : links.when(this.remote, (el) => el.child(div().flex_none().text_color(t.dim).child("PEARS links: local spaces only"))))
      .child(div().id("palette").flex_none().text_color(t.dim).cursor_pointer().on_click(() => run("app.palette"))
        .child(`${window()?.platform === "macos" ? "⌘" : "Ctrl"} Shift P  commands`));
  }

  choose(link) {
    if (!link) return;
    openUrl(link.url);
    closeOverlay(props().overlay);
  }

  // ↑/↓ or j/k move, Enter opens the highlighted link, a service's letter opens it at once.
  onKey(e, cx) {
    const k = e.key, n = this.links.length;
    if (k === "escape") return closeOverlay(props().overlay);
    if (e.modifiers?.control || e.modifiers?.alt || e.modifiers?.platform) return;
    if ((k === "down" || k === "j") && n) this.at = (this.at + 1) % n;
    else if ((k === "up" || k === "k") && n) this.at = (this.at + n - 1) % n;
    else if (k === "enter") this.choose(this.links[this.at]);
    else {
      const link = this.links.find((l) => l.key === k);
      if (!link) return;
      this.choose(link);
    }
    cx.stop_propagation();
    cx.notify();
  }

  renderList() {
    const t = theme();
    const list = v_flex().id("pears-links").size_full().p(8).gap(2).text_size(13).text_color(t.foreground)
      .track_focus(this.handle).on_key_down((e, cx) => this.onKey(e, cx));
    const title = (text) => div().px(8).pt(4).pb(6).text_size(11.8).text_color(t.muted).truncate().child(text);
    if (!this.root) {
      return list.child(title(this.remote ? "PEARS links work for spaces on this computer only." : "The focused terminal isn't in a PEARS worktree."));
    }
    this.at = Math.min(this.at, Math.max(0, this.links.length - 1));
    const keycap = (text) => div().flex_none().px(5).rounded(4).border_1().border_color(t.border).text_size(11).text_color(t.muted).child(text);
    return list
      .child(title(this.root))
      .children(this.links.map((l, i) =>
        h_flex().id(`row-${l.id}`).gap(10).px(8).py(6).rounded(6).items_center().cursor_pointer()
          .when(i === this.at, (el) => el.bg(t.selected))
          .hover((s) => s.bg(t.hover))
          .on_click(() => this.choose(l))
          .child(div().flex_none().size(7).rounded(4).bg(l.up ? t.ansi2 : t.dim))
          .child(div().flex_none().w(84).child(l.label))
          .child(div().flex_1().truncate().text_color(l.up ? t.muted : t.dim).child(l.url))
          .child(keycap(l.key.toUpperCase()))))
      .child(div().px(8).pt(6).text_size(11).text_color(t.dim).child("↑↓ select · Enter open · letter opens · Esc close"));
  }
}
