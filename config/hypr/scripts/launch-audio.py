#!/usr/bin/env python3
"""
launch-audio.py - volume popup with per-app stream control (GTK4 port)
Requires: python-gobject, gtk4-layer-shell, pamixer, pactl

Install gtk4-layer-shell (Arch):
    sudo pacman -S gtk4-layer-shell

For blur, add to your Hyprland config:
    layerrule = blur, namespace:audio-popup
    layerrule = ignorezero, namespace:audio-popup
"""

import gi, subprocess, re, os, signal, sys, time

# ── gtk4-layer-shell linking fix ───────────────────────────────────────────────
_LS_LIB   = "libgtk4-layer-shell.so"
_LS_CACHE = os.path.expanduser("~/.cache/gtk4-layer-shell-path")

if _LS_LIB not in os.environ.get("LD_PRELOAD", ""):
    _sopath = None
    if os.path.exists(_LS_CACHE):
        _sopath = open(_LS_CACHE).read().strip() or None
    if not _sopath:
        try:
            for line in subprocess.run(
                ["ldconfig", "-p"], capture_output=True, text=True
            ).stdout.splitlines():
                if "libgtk4-layer-shell" in line and "=>" in line:
                    _sopath = line.split("=>")[-1].strip()
                    os.makedirs(os.path.dirname(_LS_CACHE), exist_ok=True)
                    open(_LS_CACHE, "w").write(_sopath)
                    break
        except Exception:
            pass
    if _sopath:
        os.environ["LD_PRELOAD"] = (
            _sopath + ":" + os.environ.get("LD_PRELOAD", "")
        ).strip(":")
        os.execv(sys.executable, [sys.executable] + sys.argv)

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gtk, Gdk, GLib, Gtk4LayerShell

WIDGET_WIDTH    = 280
TARGET_CENTER_X = 2217
TARGET_TOP_Y    = 3
C_BG      = "rgba(17, 17, 27, 0.90)"
C_SURFACE = "#1e1e2e"
C_TEXT    = "#cdd6f4"
C_ACCENT  = "#c0415a"

STREAM_LINGER_S  = 120
DRAG_SETTLE_MS   = 500
REVEAL_DURATION  = 150   # ms for the slide-down animation

# Cache file for right margin so hyprctl only runs once ever per monitor config
_MARGIN_CACHE = os.path.expanduser("~/.cache/audio-popup-margin")

CSS = f"""
* {{ outline: none; box-shadow: none; }}
window {{
    background-color: {C_BG};
    border: 2px solid {C_ACCENT};
    border-radius: 5px;
}}
#header {{ padding: 12px 14px 10px 14px; }}
#master-label {{
    color: {C_TEXT}; font-family: monospace; font-size: 11px;
    font-weight: bold; letter-spacing: 1px;
}}
#master-pct {{
    color: {C_ACCENT}; font-family: monospace; font-size: 12px;
    font-weight: bold; min-width: 40px;
}}
button {{
    background-color: transparent; background-image: none;
    border: none; box-shadow: none; outline: none;
    padding: 0; margin: 0; min-width: 0; min-height: 0; border-radius: 4px;
}}
button:hover  {{ background-color: {C_SURFACE}; background-image: none; }}
button:active {{ background-color: transparent; background-image: none; }}
.mute-btn             {{ color: {C_TEXT};   font-size: 13px; padding: 2px 5px; }}
.mute-btn:hover       {{ color: {C_TEXT};   }}
.mute-btn.muted       {{ color: {C_ACCENT}; }}
.mute-btn.muted:hover {{ color: {C_ACCENT}; }}
#divider-row {{ padding: 0 6px; }}
#divider-line {{
    background-color: {C_ACCENT}; min-height: 1px;
    margin-top: 7px; margin-bottom: 7px;
}}
#arrow-btn        {{ color: {C_ACCENT}; font-size: 9px; padding: 0 6px; background: transparent; }}
#arrow-btn:hover,
#arrow-btn:active {{ color: {C_ACCENT}; background: transparent; }}
revealer > * {{ padding: 0; margin: 0; }}
#streams-box {{ padding: 4px 0 6px 0; border-top: 1px solid {C_SURFACE}; }}
.app-row  {{ padding: 3px 14px; }}
.app-name {{ color: {C_TEXT};   font-family: monospace; font-size: 10px; }}
.app-pct  {{ color: {C_ACCENT}; font-family: monospace; font-size: 10px; min-width: 34px; }}
.linger   {{ opacity: 0.4; }}
#footer    {{ padding: 6px 14px 10px 14px; border-top: 1px solid {C_SURFACE}; }}
#sink-name {{ color: {C_TEXT}; font-family: monospace; font-size: 9px; opacity: 0.5; }}
scale {{ padding: 6px 0; outline: none; box-shadow: none; }}
scale trough {{
    min-height: 2px; border-radius: 2px; border: none;
    padding: 0; margin: 0; background-color: {C_SURFACE};
    outline: none; box-shadow: none;
}}
scale trough highlight {{ background-color: {C_ACCENT}; border-radius: 2px; }}
scale slider {{
    background-color: {C_SURFACE}; border-radius: 50%;
    min-width: 8px; min-height: 8px;
    border: 1px solid {C_ACCENT}; outline: none; box-shadow: none;
}}
scale slider:hover   {{ background-color: {C_TEXT}; }}
scale:focus trough,
scale:focus slider   {{ outline: none; box-shadow: none; }}
"""

_loop = GLib.MainLoop()


# ── Pure-Python process check (no pgrep subprocess) ───────────────────────────
def _find_existing_pids():
    """Return PIDs of other instances of this script without spawning pgrep."""
    mypid   = os.getpid()
    script  = os.path.basename(__file__)
    results = []
    try:
        for entry in os.scandir("/proc"):
            if not entry.name.isdigit():
                continue
            pid = int(entry.name)
            if pid == mypid:
                continue
            try:
                cmdline = open(f"/proc/{pid}/cmdline").read().replace("\0", " ")
                if script in cmdline:
                    results.append(pid)
            except OSError:
                pass
    except OSError:
        pass
    return results


# ── Audio helpers ──────────────────────────────────────────────────────────────
def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()

def get_volume():
    v = run(["pamixer", "--get-volume"])
    return int(v) if v.isdigit() else 0

def get_muted():
    return run(["pamixer", "--get-mute"]) == "true"

def set_volume(v):
    subprocess.run(["pamixer", "--set-volume", str(int(v))])

def toggle_mute():
    subprocess.run(["pamixer", "--toggle-mute"])

def get_sink_name():
    n = run(["pactl", "get-default-sink"])
    return n.split(".")[-1][:32] if n else "unknown"

def vol_icon(vol, muted):
    if muted:    return "󰝟"
    if vol == 0: return "󰝦"
    if vol < 33: return "󰕿"
    if vol < 66: return "󰖀"
    return "󰕾"

def get_sink_inputs():
    out = run(["pactl", "list", "sink-inputs"])
    inputs, current = [], {}
    for line in out.splitlines():
        line = line.strip()
        m = re.match(r"^Sink Input #(\d+)", line)
        if m:
            if current:
                inputs.append(current)
            current = {"index": m.group(1), "name": "Unknown", "vol": 100, "muted": False}
            continue
        if not current:
            continue
        if line.startswith("Mute:"):
            current["muted"] = "yes" in line
        elif line.startswith("Volume:"):
            pct = re.search(r"(\d+)%", line)
            if pct:
                current["vol"] = min(int(pct.group(1)), 100)
        elif "application.name" in line:
            val = re.search(r'"([^"]+)"', line)
            if val:
                current["name"] = val.group(1)[:22]
        elif "media.name" in line and current["name"] == "Unknown":
            val = re.search(r'"([^"]+)"', line)
            if val:
                current["name"] = val.group(1)[:22]
    if current:
        inputs.append(current)
    return inputs

def set_input_volume(index, vol):
    subprocess.run(["pactl", "set-sink-input-volume", str(index), f"{int(vol)}%"])

def toggle_input_mute(index):
    subprocess.run(["pactl", "set-sink-input-mute", str(index), "toggle"])

def get_right_margin():
    """Return right margin, using a cache file to avoid hyprctl on every launch."""
    if os.path.exists(_MARGIN_CACHE):
        try:
            return int(open(_MARGIN_CACHE).read().strip())
        except ValueError:
            pass
    try:
        import json
        mons = json.loads(run(["hyprctl", "monitors", "-j"]) or "[]")
        for m in mons:
            if m["x"] <= TARGET_CENTER_X < m["x"] + m["width"]:
                rm = (m["x"] + m["width"]) - (TARGET_CENTER_X + WIDGET_WIDTH // 2)
                os.makedirs(os.path.dirname(_MARGIN_CACHE) or ".", exist_ok=True)
                open(_MARGIN_CACHE, "w").write(str(rm))
                return rm
    except Exception:
        pass
    return 10

def make_slider(max_val=100):
    adj = Gtk.Adjustment(value=0, lower=0, upper=max_val,
                         step_increment=1, page_increment=10, page_size=0)
    s = Gtk.Scale(orientation=Gtk.Orientation.HORIZONTAL, adjustment=adj)
    s.set_draw_value(False)
    s.set_hexpand(True)
    s.set_can_focus(False)
    # GTK4 programmatic cursor — CSS cursor: is unreliable on Wayland
    s.set_cursor(Gdk.Cursor.new_from_name("ew-resize", None))
    return s

def apply_css():
    provider = Gtk.CssProvider()
    provider.load_from_string(CSS)
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )


# ── Popup ──────────────────────────────────────────────────────────────────────
class VolumePopup(Gtk.Window):

    def __init__(self):
        super().__init__()
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_default_size(WIDGET_WIDTH, -1)

        Gtk4LayerShell.init_for_window(self)
        Gtk4LayerShell.set_namespace(self, "audio-popup")
        Gtk4LayerShell.set_layer(self, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.TOP,   True)
        Gtk4LayerShell.set_anchor(self, Gtk4LayerShell.Edge.RIGHT, True)
        Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.TOP,   TARGET_TOP_Y)
        Gtk4LayerShell.set_margin(self, Gtk4LayerShell.Edge.RIGHT, get_right_margin())
        Gtk4LayerShell.set_keyboard_mode(self, Gtk4LayerShell.KeyboardMode.ON_DEMAND)

        self._linger:        dict[str, float] = {}
        self._dragging:      dict[str, bool]  = {}
        self._settle_source: dict[str, int]   = {}
        self._input_muted:   dict[str, bool]  = {}
        self._mvol   = 0
        self._mmuted = False

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_child(root)

        # ── Header ────────────────────────────────────────────────────────────
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        header.set_name("header")
        root.append(header)

        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        header.append(top_row)

        self.mute_btn = Gtk.Button(label=vol_icon(0, False))
        self.mute_btn.add_css_class("mute-btn")
        self.mute_btn.set_can_focus(False)
        self.mute_btn.set_cursor(Gdk.Cursor.new_from_name("pointer", None))
        self.mute_btn.connect("clicked", self._on_master_mute)
        top_row.append(self.mute_btn)

        lbl = Gtk.Label(label="MASTER")
        lbl.set_name("master-label")
        lbl.set_xalign(0)
        lbl.set_hexpand(True)
        top_row.append(lbl)

        self.master_pct = Gtk.Label(label="…")
        self.master_pct.set_name("master-pct")
        self.master_pct.set_xalign(1)
        top_row.append(self.master_pct)

        self.master_slider = make_slider()
        self.master_slider.connect("value-changed", self._on_master_slider)
        header.append(self.master_slider)

        # ── Divider ───────────────────────────────────────────────────────────
        self._streams_open = False
        divider_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        divider_row.set_name("divider-row")
        root.append(divider_row)

        left_line = Gtk.Box()
        left_line.set_name("divider-line")
        left_line.set_hexpand(True)
        left_line.set_valign(Gtk.Align.CENTER)
        divider_row.append(left_line)

        self.arrow_btn = Gtk.Button(label="▼")
        self.arrow_btn.set_name("arrow-btn")
        self.arrow_btn.set_can_focus(False)
        self.arrow_btn.set_cursor(Gdk.Cursor.new_from_name("pointer", None))
        self.arrow_btn.connect("clicked", self._toggle_streams)
        divider_row.append(self.arrow_btn)

        right_line = Gtk.Box()
        right_line.set_name("divider-line")
        right_line.set_hexpand(True)
        right_line.set_valign(Gtk.Align.CENTER)
        divider_row.append(right_line)

        # ── Streams revealer (SLIDE_DOWN = grows downward, no layout jump) ───
        self.revealer = Gtk.Revealer()
        self.revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN)
        self.revealer.set_transition_duration(REVEAL_DURATION)
        self.revealer.set_reveal_child(False)
        root.append(self.revealer)

        self.streams_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.streams_box.set_name("streams-box")
        self.revealer.set_child(self.streams_box)

        # ── Footer ────────────────────────────────────────────────────────────
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        footer.set_name("footer")
        root.append(footer)

        self.sink_lbl = Gtk.Label(label="…")
        self.sink_lbl.set_name("sink-name")
        self.sink_lbl.set_xalign(0)
        self.sink_lbl.set_hexpand(True)
        footer.append(self.sink_lbl)

        key_ctrl = Gtk.EventControllerKey.new()
        key_ctrl.connect("key-pressed", self._on_key)
        self.add_controller(key_ctrl)

        # Defer all blocking audio queries until after first frame
        GLib.idle_add(self._init_audio)

    def _init_audio(self):
        self._mvol   = get_volume()
        self._mmuted = get_muted()
        self.master_pct.set_text(f"{self._mvol}%")
        self.mute_btn.set_label(vol_icon(self._mvol, self._mmuted))
        if self._mmuted:
            self.mute_btn.add_css_class("muted")
        self.master_slider.handler_block_by_func(self._on_master_slider)
        self.master_slider.get_adjustment().set_value(self._mvol)
        self.master_slider.handler_unblock_by_func(self._on_master_slider)
        self.sink_lbl.set_text(get_sink_name())
        GLib.timeout_add(2000, self._refresh_streams)
        return False

    # ── Streams ───────────────────────────────────────────────────────────────
    def _toggle_streams(self, _):
        self._streams_open = not self._streams_open
        self.arrow_btn.set_label("▲" if self._streams_open else "▼")
        if self._streams_open:
            self._build_streams()
        # Revealer slides smoothly — no resize jump
        self.revealer.set_reveal_child(self._streams_open)

    def _iter_stream_rows(self):
        child = self.streams_box.get_first_child()
        while child:
            yield child
            child = child.get_next_sibling()

    def _build_streams(self):
        now  = time.monotonic()
        live = {inp["index"]: inp for inp in get_sink_inputs()}

        self._linger = {k: v for k, v in self._linger.items() if v > now}

        existing = {w._stream_index: w for w in self._iter_stream_rows()
                    if hasattr(w, "_stream_index")}

        for idx in existing:
            if idx not in live and idx not in self._linger:
                self._linger[idx] = now + STREAM_LINGER_S

        show = list(live.keys()) + [i for i in self._linger if i not in live]

        for idx, row in list(existing.items()):
            if idx not in show:
                self.streams_box.remove(row)

        existing = {w._stream_index: w for w in self._iter_stream_rows()
                    if hasattr(w, "_stream_index")}

        for idx in show:
            inp     = live.get(idx)
            is_live = inp is not None
            if inp is None:
                inp = {"index": idx, "name": "…", "vol": 0, "muted": True}

            if idx in existing:
                row = existing[idx]
                if is_live:
                    if not self._dragging.get(idx, False):
                        self._input_muted[idx] = inp["muted"]
                        row._mute_btn.set_label(vol_icon(inp["vol"], inp["muted"]))
                        if inp["muted"]:
                            row._mute_btn.add_css_class("muted")
                        else:
                            row._mute_btn.remove_css_class("muted")
                        row._slider.handler_block_by_func(row._on_value_changed)
                        row._slider.get_adjustment().set_value(inp["vol"])
                        row._slider.handler_unblock_by_func(row._on_value_changed)
                        row._pct_lbl.set_text(f"{inp['vol']}%")
                    row.remove_css_class("linger")
                    row.set_sensitive(True)
                else:
                    row.add_css_class("linger")
                    row.set_sensitive(False)
            else:
                row = self._make_stream_row(inp, is_live)
                self.streams_box.append(row)

        non_rows = [w for w in self._iter_stream_rows() if not hasattr(w, "_stream_index")]
        has_rows = any(hasattr(w, "_stream_index") for w in self._iter_stream_rows())

        if not has_rows:
            if not non_rows:
                empty = Gtk.Label(label="no active streams")
                empty.add_css_class("app-name")
                empty.set_margin_top(6)
                empty.set_margin_bottom(4)
                self.streams_box.append(empty)
        else:
            for w in non_rows:
                self.streams_box.remove(w)

    def _make_stream_row(self, inp, is_live):
        row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        row.add_css_class("app-row")
        row._stream_index = inp["index"]

        top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        row.append(top)

        mute_btn = Gtk.Button(label=vol_icon(inp["vol"], inp["muted"]))
        mute_btn.add_css_class("mute-btn")
        mute_btn.set_can_focus(False)
        mute_btn.set_cursor(Gdk.Cursor.new_from_name("pointer", None))
        if inp["muted"]:
            mute_btn.add_css_class("muted")
        top.append(mute_btn)
        row._mute_btn = mute_btn

        self._input_muted[inp["index"]] = inp["muted"]

        name_lbl = Gtk.Label(label=inp["name"])
        name_lbl.add_css_class("app-name")
        name_lbl.set_xalign(0)
        name_lbl.set_ellipsize(3)
        name_lbl.set_hexpand(True)
        top.append(name_lbl)

        pct_lbl = Gtk.Label(label=f"{inp['vol']}%")
        pct_lbl.add_css_class("app-pct")
        pct_lbl.set_xalign(1)
        top.append(pct_lbl)
        row._pct_lbl = pct_lbl

        slider = make_slider(max_val=100)
        slider.get_adjustment().set_value(min(inp["vol"], 100))
        row._slider = slider

        idx = inp["index"]

        def on_value_changed(s, i=idx, p=pct_lbl, m=mute_btn):
            self._on_input_slider(s, i, p, m)
        row._on_value_changed = on_value_changed

        slider.connect("value-changed", on_value_changed)
        mute_btn.connect(
            "clicked",
            lambda _, i=idx, b=mute_btn, s=slider: self._on_input_mute(i, b, s),
        )
        row.append(slider)

        if not is_live:
            row.add_css_class("linger")
            row.set_sensitive(False)

        return row

    def _refresh_streams(self):
        self._build_streams()
        return True

    # ── Callbacks ─────────────────────────────────────────────────────────────
    def _on_master_slider(self, scale):
        self._mvol = int(scale.get_value())
        self.master_pct.set_text(f"{self._mvol}%")
        self.mute_btn.set_label(vol_icon(self._mvol, self._mmuted))
        set_volume(self._mvol)

    def _on_master_mute(self, _):
        toggle_mute()
        self._mmuted = get_muted()
        self._mvol   = get_volume()
        self.mute_btn.set_label(vol_icon(self._mvol, self._mmuted))
        if self._mmuted:
            self.mute_btn.add_css_class("muted")
        else:
            self.mute_btn.remove_css_class("muted")

    def _on_input_slider(self, scale, index, pct_lbl, mute_btn):
        vol   = int(scale.get_value())
        muted = self._input_muted.get(index, False)
        pct_lbl.set_text(f"{vol}%")
        mute_btn.set_label(vol_icon(vol, muted))
        self._dragging[index] = True
        if index in self._settle_source:
            GLib.source_remove(self._settle_source[index])
        set_input_volume(index, vol)
        self._settle_source[index] = GLib.timeout_add(
            DRAG_SETTLE_MS, self._clear_dragging, index
        )

    def _clear_dragging(self, index):
        self._dragging[index] = False
        self._settle_source.pop(index, None)
        return False

    def _on_input_mute(self, index, btn, slider):
        toggle_input_mute(index)
        muted = not self._input_muted.get(index, False)
        self._input_muted[index] = muted
        if muted:
            btn.add_css_class("muted")
        else:
            btn.remove_css_class("muted")
        vol = int(slider.get_value()) if slider else 50
        btn.set_label(vol_icon(vol, muted))

    def _on_key(self, controller, keyval, keycode, state):
        if keyval == Gdk.KEY_Escape:
            _loop.quit()
        return False


# ── Entry point ────────────────────────────────────────────────────────────────
def main():
    for pid in _find_existing_pids():
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        sys.exit(0)

    apply_css()
    popup = VolumePopup()
    popup.present()
    _loop.run()


if __name__ == "__main__":
    main()
