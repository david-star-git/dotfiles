#!/usr/bin/env python3
"""
generate.py — renders every app's colors from palette.toml.

Usage:
    python3 config/theme/colors/generate.py

What it does
------------
1. Loads palette.toml (the single source of truth for color values).
2. Writes import-ready fragments into this directory for apps whose config
   format supports importing another file:
       colors.css            (GTK CSS  @define-color, used by waybar/wlogout)
       colors.rasi            (rofi     @import,        used by rofi/*.rasi)
       hypr-colors.conf       (Hyprland source=,         used by hypr/theme.conf)
       alacritty-colors.toml  (alacritty general.import, used by alacritty.toml)
   (kitty, tmux, and nvim are hand-authored — see colors/macglass.lua's
   comment. Not touched here; keep palette.toml in sync with them by hand.)
3. Recolors every literal color value still baked into app configs that have
   no import mechanism at all (mako, kdeglobals, qt6ct, Kvantum, fzf colors
   in the pkg scripts, the screenshot-selection color in keybinds.conf, the
   notification color constants in launch-audio.py) by diffing against
   .state.json — the palette this script generated last time — so re-running
   it after editing palette.toml re-themes those files too.

Re-run this any time palette.toml changes. It is idempotent: run it twice in
a row and the second run is a no-op.
"""
import json
import re
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
COLORS_DIR = Path(__file__).resolve().parent
PALETTE_TOML = COLORS_DIR / "palette.toml"
STATE_JSON = COLORS_DIR / ".state.json"

# First run ever (no .state.json yet) assumes the repo is still on its
# original Catppuccin Mocha + crimson accent setup — this is what every
# non-importable config file's literal values are diffed against the first
# time generate.py runs.
BOOTSTRAP_STATE = {
    "base": "1e1e2e", "mantle": "181825", "crust": "11111b",
    "surface0": "313244", "surface1": "45475a", "surface2": "585b70",
    "overlay0": "6c7086", "text": "cdd6f4", "subtext0": "a6adc8",
    "subtext1": "bac2de", "lavender": "b4befe", "blue": "89b4fa",
    "sapphire": "74c7ec", "teal": "94e2d5", "green": "a6e3a1",
    "yellow": "f9e2af", "peach": "fab387", "red": "f38ba8",
    "pink": "f5c2e7", "rosewater": "f5e0dc",
    "accent": "c0415a", "accent_dim": "c0415a88",
    # migration-only aliases: odd one-off values found in the repo that
    # aren't a named role's primary value, but clearly belong to one.
    "_alias_mantle_waybar": "181824",
    "_alias_lavender_mauve": "cba6f7",
    "_alias_overlay0_dim": "7f849c",
    "_alias_blue_alt": "308cc6",
}
ALIAS_TARGET_ROLE = {
    "_alias_mantle_waybar": "mantle",
    "_alias_lavender_mauve": "lavender",
    "_alias_overlay0_dim": "overlay0",
    "_alias_blue_alt": "blue",
}

ROLE_ORDER = [
    "base", "mantle", "crust", "surface0", "surface1", "surface2", "overlay0",
    "text", "subtext0", "subtext1", "lavender", "blue", "sapphire", "teal",
    "green", "mint", "yellow", "peach", "red", "pink", "rosewater", "purple",
    "accent",
]


def hx(v: str) -> str:
    return v.lstrip("#").lower()[:6]


def rgb(v: str) -> tuple[int, int, int]:
    v = hx(v)
    return int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)


def clamp(n: int) -> int:
    return max(0, min(255, n))


def load_palette() -> dict[str, str]:
    data = tomllib.loads(PALETTE_TOML.read_text())
    return {k: hx(v) for k, v in data["color"].items()}


def load_prev_state() -> dict[str, str]:
    if STATE_JSON.exists():
        return json.loads(STATE_JSON.read_text())
    return dict(BOOTSTRAP_STATE)


def build_anchors(prev: dict[str, str], new: dict[str, str]):
    """(old_rgb, new_rgb) pairs for every role/alias present in both."""
    anchors = [((0, 0, 0), (0, 0, 0)), ((255, 255, 255), (255, 255, 255))]
    exact = {"000000": "000000", "ffffff": "ffffff"}
    for key, old_hex in prev.items():
        role = ALIAS_TARGET_ROLE.get(key, key)
        if role not in new:
            continue
        old_hex6 = hx(old_hex)
        new_hex6 = new[role]
        exact[old_hex6] = new_hex6
        anchors.append((rgb(old_hex6), rgb(new_hex6)))
    return exact, anchors


def nearest_transform(rgb_val, exact, anchors):
    hex6 = "%02x%02x%02x" % rgb_val
    if hex6 in exact:
        return rgb(exact[hex6])
    old_a, new_a = min(
        anchors,
        key=lambda a: sum((c - o) ** 2 for c, o in zip(rgb_val, a[0])),
    )
    return tuple(
        clamp(n + (c - o)) for c, o, n in zip(rgb_val, old_a, new_a)
    )


# ── Regex-based recoloring for literal-only config formats ──────────────────

HEX8_RE = re.compile(r"#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?")
DEC_LINE_RE = re.compile(
    r"^(?P<key>[\w:\[\] .]+=)(?P<r>\d{1,3}),\s?(?P<g>\d{1,3}),\s?(?P<b>\d{1,3})$",
    re.MULTILINE,
)
ARGB_RE = re.compile(r"#([0-9A-Fa-f]{2})([0-9A-Fa-f]{6})")
CSS_RGBA_FUNC_RE = re.compile(r"(rgba?)\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(,|\))")


def recolor_hex_rgba(text: str, exact, anchors) -> str:
    """#RRGGBB or #RRGGBBAA, alpha (if present) preserved verbatim."""
    def repl(m):
        old = rgb(m.group(1))
        new = nearest_transform(old, exact, anchors)
        out = "#%02x%02x%02x" % new
        if m.group(2):
            out += m.group(2)
        return out
    return HEX8_RE.sub(repl, text)


def recolor_argb(text: str, exact, anchors) -> str:
    """#AARRGGBB (qt6ct style) — alpha comes first."""
    def repl(m):
        alpha, color = m.group(1), m.group(2)
        old = rgb(color)
        new = nearest_transform(old, exact, anchors)
        return "#%s%02x%02x%02x" % (alpha, *new)
    return ARGB_RE.sub(repl, text)


def recolor_decimal_lines(text: str, exact, anchors) -> str:
    """key=R,G,B lines (kdeglobals) — never touches font strings etc.
    because those have more than 3 comma-separated values."""
    def repl(m):
        old = (int(m.group("r")), int(m.group("g")), int(m.group("b")))
        new = nearest_transform(old, exact, anchors)
        return f"{m.group('key')}{new[0]},{new[1]},{new[2]}"
    return DEC_LINE_RE.sub(repl, text)


def recolor_css_rgba_func(text: str, exact, anchors) -> str:
    """rgba(r, g, b, a) / rgb(r, g, b) CSS function calls — alpha (if any)
    and the trailing paren/comma are preserved verbatim."""
    def repl(m):
        old = (int(m.group(2)), int(m.group(3)), int(m.group(4)))
        new = nearest_transform(old, exact, anchors)
        return f"{m.group(1)}({new[0]}, {new[1]}, {new[2]}{m.group(5)}"
    return CSS_RGBA_FUNC_RE.sub(repl, text)


def apply(path: Path, fn, *args):
    text = path.read_text()
    new_text = fn(text, *args)
    if new_text != text:
        path.write_text(new_text)
        print(f"  recolored {path.relative_to(REPO)}")


# ── Import-fragment writers ──────────────────────────────────────────────────

def write_hypr_colors(new):
    lines = ["# Generated by generate.py from palette.toml — do not hand-edit.", ""]
    for role in ROLE_ORDER:
        lines.append(f"$col_{role} = rgb({new[role].upper()})")
    lines.append(f'$col_accent_dim = rgba({new["accent"].upper()}88)')
    (COLORS_DIR / "hypr-colors.conf").write_text("\n".join(lines) + "\n")


def write_css_colors(new):
    lines = ["/* Generated by generate.py from palette.toml — do not hand-edit. */"]
    for role in ROLE_ORDER:
        lines.append(f"@define-color {role} #{new[role]};")
    lines.append(f'@define-color accent_dim alpha(#{new["accent"]}, 0.53);')
    # Back-compat aliases for names already used in waybar/wlogout bodies.
    lines += [
        "@define-color foreground @text;",
        "@define-color background @mantle;",
        "@define-color crimson @accent;",
        "@define-color surface0alias @surface0;",
    ]
    (COLORS_DIR / "colors.css").write_text("\n".join(lines) + "\n")


def write_rasi_colors(new):
    lines = ["// Generated by generate.py from palette.toml — do not hand-edit.", "* {"]
    for role in ROLE_ORDER:
        # base keeps a touch of translucency (matches window { transparency: "real"; })
        alpha = "ee" if role == "base" else "ff"
        lines.append(f"    {role}:  #{new[role]}{alpha};")
    lines.append(f'    accent-dim: #{new["accent"]}88;')
    lines += [
        "    // Back-compat aliases for the old Catppuccin role name",
        "    crimson:     @accent;",
        "    crimson-dim: @accent-dim;",
        "",
        "    // Wiring shared by every rofi mode (launcher, wallpaper picker, ...)",
        "    background-color:   transparent;",
        "    text-color:         @text;",
        "    border-color:       @accent;",
        "}",
    ]
    (COLORS_DIR / "colors.rasi").write_text("\n".join(lines) + "\n")


def write_alacritty_colors(new):
    lines = [
        "# Generated by generate.py from palette.toml — do not hand-edit.",
        "[colors.primary]",
        f'background = "#{new["base"]}"',
        f'foreground = "#{new["text"]}"',
        f'dim_foreground = "#{new["overlay0"]}"',
        f'bright_foreground = "#{new["text"]}"',
        "",
        "[colors.cursor]",
        f'text = "#{new["base"]}"',
        f'cursor = "#{new["rosewater"]}"',
        "",
        "[colors.selection]",
        f'text = "#{new["base"]}"',
        f'background = "#{new["rosewater"]}"',
        "",
        "[colors.normal]",
        f'black = "#{new["surface1"]}"',
        f'red = "#{new["red"]}"',
        f'green = "#{new["green"]}"',
        f'yellow = "#{new["yellow"]}"',
        f'blue = "#{new["blue"]}"',
        f'magenta = "#{new["pink"]}"',
        f'cyan = "#{new["teal"]}"',
        f'white = "#{new["subtext1"]}"',
        "",
        "[colors.bright]",
        f'black = "#{new["surface2"]}"',
        f'red = "#{new["red"]}"',
        f'green = "#{new["green"]}"',
        f'yellow = "#{new["yellow"]}"',
        f'blue = "#{new["blue"]}"',
        f'magenta = "#{new["pink"]}"',
        f'cyan = "#{new["teal"]}"',
        f'white = "#{new["subtext0"]}"',
        "",
        "[[colors.indexed_colors]]",
        "index = 16",
        f'color = "#{new["peach"]}"',
        "",
        "[[colors.indexed_colors]]",
        "index = 17",
        f'color = "#{new["rosewater"]}"',
    ]
    (COLORS_DIR / "alacritty-colors.toml").write_text("\n".join(lines) + "\n")


def main():
    new = load_palette()
    prev = load_prev_state()
    exact, anchors = build_anchors(prev, new)

    print("Writing import fragments...")
    write_hypr_colors(new)
    write_css_colors(new)
    write_rasi_colors(new)
    write_alacritty_colors(new)

    print("Recoloring literal-only configs...")
    hex_rgba_targets = [
        "config/waybar/style.css",
        "config/wlogout/style.css",
        "config/mako/config",
        "config/rofi/theme.rasi",
        "config/rofi/launcher.rasi",
        "config/rofi/wallpaper.rasi",
    ]
    for rel in hex_rgba_targets:
        apply(REPO / rel, recolor_hex_rgba, exact, anchors)
        apply(REPO / rel, recolor_css_rgba_func, exact, anchors)

    plain_hex_targets = [
        "config/alacritty/alacritty.toml",
        "config/hypr/scripts/launch-audio.py",
        "config/home/.scripts/pkg/pkgi",
        "config/home/.scripts/pkg/pkgr",
    ]
    for rel in plain_hex_targets:
        apply(REPO / rel, recolor_hex_rgba, exact, anchors)

    apply(REPO / "config/theme/qt6ct/style-colors.conf", recolor_argb, exact, anchors)
    apply(REPO / "config/theme/kdeglobals", recolor_decimal_lines, exact, anchors)

    STATE_JSON.write_text(json.dumps(new, indent=2, sort_keys=True) + "\n")
    print(f"Wrote {STATE_JSON.relative_to(REPO)} — future runs diff against this.")


if __name__ == "__main__":
    main()
