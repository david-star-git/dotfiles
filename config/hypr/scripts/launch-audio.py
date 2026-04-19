#!/usr/bin/env python3
"""
launch-audio.py - volume popup with per-app stream control
Requires: python-gobject, gtk-layer-shell, pamixer, pactl (pipewire-pulse)
Run once to open, run again to close (toggle).
Click outside the popup to close it.
Press Escape to close.
"""

import gi, subprocess, re, json, os, signal, sys
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GLib, GtkLayerShell

# ── Position config ───────────────────────────────────────────────────────────
# Set these to the coords reported by `hyprctl cursorpos` while hovering
# the center of the Waybar audio button.
WIDGET_WIDTH = 280
TARGET_CENTER_X = 2217  # horizontal center of popup top edge
TARGET_TOP_Y = 0  # vertical top edge of popup (= bar bottom)


# ── Compute right margin from monitor geometry ────────────────────────────────
def _get_right_margin():
    try:
        mons = json.loads(
            subprocess.run(
                ["hyprctl", "monitors", "-j"], capture_output=True, text=True
            ).stdout
            or "[]"
        )

        for m in mons:
            if m["x"] <= TARGET_CENTER_X < m["x"] + m["width"]:
                monitor_right = m["x"] + m["width"]
                return monitor_right - (TARGET_CENTER_X + WIDGET_WIDTH // 2)
    except Exception:
        pass
    return 10  # safe fallback
RIGHT_MARGIN = _get_right_margin()
TOP_MARGIN = TARGET_TOP_Y

# ── CSS ───────────────────────────────────────────────────────────────────────
CSS = """
* { transition: none; }
window {
    background-color: #11111b;
    border: 2px solid #c0415a;
    border-radius: 5px;
}

#header {
    padding: 14px 16px 10px 16px;
    border-bottom: 1px solid #1e1e2e;
}

#footer {
    padding: 8px 16px 12px 16px;
    border-top: 1px solid #1e1e2e;
}

/* ── Master ── */
#master-label {
    color: #c0415a;
    font-family: monospace;
    font-size: 11px;
    font-weight: bold;
    letter-spacing: 1px;
}

#master-pct {
    color: #c0415a;
    font-family: monospace;
    font-size: 13px;
    font-weight: bold;
    min-width: 44px;
}

/* ── Dropdown toggle ── */
#streams-toggle {
    background: transparent;
    color: #6c7086;
    border: none;
    border-radius: 0;
    border-top: 1px solid #1e1e2e;
    padding: 5px 16px;
    font-family: monospace;
    font-size: 10px;
    letter-spacing: 1px;
}

#streams-toggle:hover { color: #cdd6f4; background: #1e1e2e; }
/* ── App rows ── */
#streams-box { padding: 6px 0; border-bottom: 1px solid #1e1e2e; }
.app-row     { padding: 4px 16px; }
.app-name    { color: #a6adc8; font-family: monospace; font-size: 10px; min-width: 90px; }
.app-pct     { color: #6c7086; font-family: monospace; font-size: 10px; min-width: 36px; }
/* ── Mute buttons ── */
.mute-btn {
    background: transparent;
    color: #6c7086;
    border: none;
    border-radius: 4px;
    padding: 2px 5px;
    font-size: 12px;
    min-width: 0;
    min-height: 0;
}

.mute-btn:hover { background: #1e1e2e; color: #cdd6f4; }
.mute-btn.muted { color: #c0415a; }
/* ── Sink label ── */
#sink-name { color: #45475a; font-family: monospace; font-size: 9px; }
/* ── Master slider (crimson) ── */
#master-slider trough    { background-color: #313244; border-radius: 3px; min-height: 4px; }
#master-slider highlight { background-color: #c0415a; border-radius: 3px; }
#master-slider slider    {
    background-color: #1e1e2e;
    border-radius: 50%;
    min-width: 12px; min-height: 12px;
    border: 2px solid #c0415a;
    box-shadow: none;
}

/* ── App sliders (subtle) ── */
.app-slider trough    { background-color: #1e1e2e; border-radius: 3px; min-height: 3px; }
.app-slider highlight { background-color: #45475a; border-radius: 3px; }
.app-slider slider    {
    background-color: #585b70;
    border-radius: 50%;
    min-width: 10px; min-height: 10px;
    border: none; box-shadow: none;
}

.app-slider slider:hover { background-color: #cdd6f4; }
"""


# ── pactl helpers ─────────────────────────────────────────────────────────────
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
    if muted:
        return "󰝟"
    if vol == 0:
        return "󰝦"
    if vol < 33:
        return "󰕿"
    if vol < 66:
        return "󰖀"
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
            current = {
                "index": m.group(1),
                "name": "Unknown",
                "vol": 100,
                "muted": False,
            }

            continue
        if not current:
            continue
        if line.startswith("Mute:"):
            current["muted"] = "yes" in line
        elif line.startswith("Volume:"):
            pct = re.search(r"(\d+)%", line)
            if pct:
                current["vol"] = int(pct.group(1))
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


# ── Transparent fullscreen click-catcher (closes popup on outside click) ──────
class Backdrop(Gtk.Window):

    def __init__(self, on_click):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_app_paintable(True)
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.TOP)
        for edge in (
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.BOTTOM,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.RIGHT,
        ):
            GtkLayerShell.set_anchor(self, edge, True)
        GtkLayerShell.set_exclusive_zone(self, -1)
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect("button-press-event", lambda *_: on_click())
        self.connect("draw", self._on_draw)

    def _on_draw(self, _widget, cr):
        cr.set_source_rgba(0, 0, 0, 0)
        cr.set_operator(1)  # cairo.OPERATOR_SOURCE
        cr.paint()
        return False


# ── Main popup ────────────────────────────────────────────────────────────────
class VolumePopup(Gtk.Window):

    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_default_size(WIDGET_WIDTH, -1)

        # Layer shell - OVERLAY so it renders above the backdrop (TOP)
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, TOP_MARGIN)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, RIGHT_MARGIN)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        provider = Gtk.CssProvider()
        provider.load_from_data(CSS.encode("utf-8"))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.add(root)

        # ── Header: master volume ─────────────────────────────────────────────
        header = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        header.set_name("header")
        root.pack_start(header, False, False, 0)
        label_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        header.pack_start(label_row, False, False, 0)
        self._master_muted = get_muted()
        self._master_vol = get_volume()
        self.master_icon = Gtk.Button(
            label=vol_icon(self._master_vol, self._master_muted)
        )

        self.master_icon.get_style_context().add_class("mute-btn")
        if self._master_muted:
            self.master_icon.get_style_context().add_class("muted")
        self.master_icon.connect("clicked", self._on_master_mute)
        label_row.pack_start(self.master_icon, False, False, 0)
        lbl = Gtk.Label(label="MASTER")
        lbl.set_name("master-label")
        lbl.set_xalign(0)
        label_row.pack_start(lbl, True, True, 0)
        self.master_pct = Gtk.Label(label=f"{self._master_vol}%")
        self.master_pct.set_name("master-pct")
        self.master_pct.set_xalign(1)
        label_row.pack_start(self.master_pct, False, False, 0)
        self.master_slider = Gtk.Scale.new_with_range(
            Gtk.Orientation.HORIZONTAL, 0, 100, 1
        )

        self.master_slider.set_name("master-slider")
        self.master_slider.set_value(self._master_vol)
        self.master_slider.set_draw_value(False)
        self.master_slider.set_hexpand(True)
        self.master_slider.connect("value-changed", self._on_master_slider)

        header.pack_start(self.master_slider, False, False, 0)

        # ── Streams dropdown toggle ───────────────────────────────────────────
        self._streams_open = False
        self.toggle_btn = Gtk.Button(label="APPLICATIONS  ▸")
        self.toggle_btn.set_name("streams-toggle")
        self.toggle_btn.set_relief(Gtk.ReliefStyle.NONE)
        self.toggle_btn.connect("clicked", self._toggle_streams)

        root.pack_start(self.toggle_btn, False, False, 0)

        # ── Streams list (hidden by default) ─────────────────────────────────
        self.streams_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        self.streams_box.set_name("streams-box")
        self.streams_box.set_visible(False)
        self.streams_box.set_no_show_all(True)

        root.pack_start(self.streams_box, False, False, 0)

        # ── Footer: sink name ─────────────────────────────────────────────────
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        footer.set_name("footer")
        root.pack_start(footer, False, False, 0)
        sink_lbl = Gtk.Label(label=f"{get_sink_name()}")
        sink_lbl.set_name("sink-name")
        sink_lbl.set_xalign(0)
        footer.pack_start(sink_lbl, True, True, 0)
        GLib.timeout_add(2000, self._refresh_streams)
        self.connect("key-press-event", self._on_key)

    # ── Streams ───────────────────────────────────────────────────────────────
    def _toggle_streams(self, _):
        self._streams_open = not self._streams_open
        if self._streams_open:
            self._build_streams()
            self.streams_box.set_visible(True)
            self.toggle_btn.set_label("APPLICATIONS  ▾")
        else:
            self.streams_box.set_visible(False)
            self.toggle_btn.set_label("APPLICATIONS  ▸")
        self.resize(1, 1)

    def _build_streams(self):
        for child in self.streams_box.get_children():
            self.streams_box.remove(child)
        inputs = get_sink_inputs()
        if not inputs:
            empty = Gtk.Label(label="No active streams")
            empty.get_style_context().add_class("app-name")
            empty.set_margin_top(6)
            empty.set_margin_bottom(6)

            self.streams_box.pack_start(empty, False, False, 0)
            self.streams_box.show_all()
            return
        for inp in inputs:
            row = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            row.get_style_context().add_class("app-row")
            top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
            row.pack_start(top, False, False, 0)
            mute_btn = Gtk.Button(label=vol_icon(inp["vol"], inp["muted"]))
            mute_btn.get_style_context().add_class("mute-btn")
            if inp["muted"]:
                mute_btn.get_style_context().add_class("muted")
            top.pack_start(mute_btn, False, False, 0)
            name_lbl = Gtk.Label(label=inp["name"])
            name_lbl.get_style_context().add_class("app-name")
            name_lbl.set_xalign(0)
            name_lbl.set_ellipsize(3)

            top.pack_start(name_lbl, True, True, 0)
            pct_lbl = Gtk.Label(label=f"{inp['vol']}%")
            pct_lbl.get_style_context().add_class("app-pct")
            pct_lbl.set_xalign(1)
            top.pack_start(pct_lbl, False, False, 0)
            slider = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 150, 1)
            slider.get_style_context().add_class("app-slider")
            slider.set_value(inp["vol"])
            slider.set_draw_value(False)
            slider.set_hexpand(True)

            idx = inp["index"]
            slider.connect(
                "value-changed",
                lambda s, i=idx, p=pct_lbl, m=mute_btn: self._on_input_slider(
                    s, i, p, m
                ),
            )

            mute_btn.connect(
                "clicked",
                lambda _, i=idx, b=mute_btn, s=slider: self._on_input_mute(i, b, s),
            )

            row.pack_start(slider, False, False, 0)
            self.streams_box.pack_start(row, False, False, 0)
        self.streams_box.show_all()

    def _refresh_streams(self):
        if self._streams_open:
            self._build_streams()
        return True

    # ── Master callbacks ──────────────────────────────────────────────────────
    def _on_master_slider(self, scale):
        self._master_vol = int(scale.get_value())
        set_volume(self._master_vol)
        self._master_muted = get_muted()
        self.master_pct.set_text(f"{self._master_vol}%")
        self.master_icon.set_label(vol_icon(self._master_vol, self._master_muted))

    def _on_master_mute(self, _):
        toggle_mute()
        self._master_muted = get_muted()
        self._master_vol = get_volume()
        self.master_icon.set_label(vol_icon(self._master_vol, self._master_muted))
        ctx = self.master_icon.get_style_context()
        if self._master_muted:
            ctx.add_class("muted")
        else:
            ctx.remove_class("muted")
    # ── App stream callbacks ──────────────────────────────────────────────────
    def _on_input_slider(self, scale, index, pct_lbl, mute_btn):
        vol = int(scale.get_value())
        set_input_volume(index, vol)
        pct_lbl.set_text(f"{vol}%")
        muted = "muted" in mute_btn.get_style_context().list_classes()
        mute_btn.set_label(vol_icon(vol, muted))

    def _on_input_mute(self, index, btn, slider):
        toggle_input_mute(index)
        ctx = btn.get_style_context()
        muted = "muted" in ctx.list_classes()
        if muted:
            ctx.remove_class("muted")
        else:
            ctx.add_class("muted")
        vol = int(slider.get_value()) if slider else 50
        btn.set_label(vol_icon(vol, not muted))

    def _on_key(self, _, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()


# ── Entry point ───────────────────────────────────────────────────────────────
def main():
    # Toggle: if already running, kill it and exit
    result = subprocess.run(
        ["pgrep", "-f", "launch-audio.py"], capture_output=True, text=True
    )

    pids = [
        int(p)
        for p in result.stdout.strip().splitlines()
        if p.strip().isdigit() and int(p.strip()) != os.getpid()
    ]

    if pids:
        for pid in pids:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        sys.exit(0)

    # Show backdrop first (lower layer), then popup (overlay layer)
    backdrop = Backdrop(Gtk.main_quit)
    backdrop.show_all()
    popup = VolumePopup()
    popup.show_all()
    popup.present()
    Gtk.main()
if __name__ == "__main__":
    main()

