# dotfiles

Personal dotfiles for Arch Linux. Managed with symlinks so every config file lives inside this repo and is edited in place.

## Installation

```sh
git clone https://github.com/david-star-git/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

The installer presents a checklist — use `↑↓` to navigate, `Space` to toggle, `Enter` to confirm. Each selected component installs its packages and symlinks its config from the repo.

Available components:

| Component | What it installs |
|-----------|-----------------|
| zsh | zsh + plugins + sets default shell |
| nvim | neovim + Packer + syncs plugins headlessly |
| tmux | tmux + TPM |
| kitty | kitty terminal |
| neomutt | neomutt + isync + msmtp + gnupg + pass + notmuch |
| theme | Kvantum + GTK 3/4 + fonts |
| security | UFW + sysctl hardening + Tor |
| fastfetch | fastfetch |

## Repo layout

```
config/
  home/          dotfiles that live at $HOME root (.zshrc, .mbsyncrc, .scripts/)
  nvim/          → ~/.config/nvim
  tmux/          → ~/.config/tmux
  kitty/         → ~/.config/kitty
  neomutt/       → ~/.config/neomutt
  fastfetch/     → ~/.config/fastfetch
  theme/         Kvantum, gtk-3.0, gtk-4.0, .themes
  i3/            → ~/.config/i3 (commented out in installer, manual setup)
fonts/           → ~/.fonts
install.sh       TUI installer
```

## Post-install

### Shell

The installer calls `chsh` automatically. If it didn't take, run:

```sh
chsh -s /usr/bin/zsh
```

### Neovim

On first launch run `:PackerSync` to install plugins. Mason will then auto-install all LSP servers and tools on startup. To install manually:

```
:MasonInstall black blackd-client clang-format clangd cmakelang cmakelint css-lsp djlint docker-compose-language-service dockerfile-language-server hadolint html-lsp jdtls lua-language-server neocmakelsp prettier pyright ruff shfmt sqlfluff stylua typescript-language-server vtsls yaml-language-server
```

### Tmux

Reload config and install plugins on first launch:

```
<prefix>r    reload config
<prefix>I    install TPM plugins
```

### Neomutt

After install, configure your mail password in pass:

```sh
pass insert email/hostinger
```

Then do an initial sync:

```sh
mbsync -a
```

### SSH key

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub   # add this to GitHub → Settings → SSH keys
ssh -T git@github.com       # test it
git remote set-url origin git@github.com:david-star-git/dotfiles.git
```

---

## Keybinds

> Navigation keys are shifted one key to the right on a German layout:
> `j` = left, `k` = up, `l` = down, `ö` = right

### i3 — `$mod` = Super

#### Applications

| Key | Action |
|-----|--------|
| `$mod+Return` | Terminal (alacritty) |
| `Ctrl+F2` | kitty |
| `$mod+b` | LibreWolf |
| `$mod+d` | Rofi launcher |
| `$mod+e` | Dolphin file manager |
| `$mod+l` | Lock screen |

#### Window management

| Key | Action |
|-----|--------|
| `$mod+q` | Kill window |
| `$mod+f` | Fullscreen toggle |
| `$mod+h` | Split horizontal |
| `$mod+v` | Split vertical |
| `$mod+Shift+Space` | Floating toggle |
| `$mod+Space` | Focus floating/tiling |
| `$mod+r` | Resize mode |
| `$mod+g` | Gaps mode |
| `$mod+Shift+r` | Reload i3 config |
| `$mod+Shift+q` | Exit i3 |

#### Focus & movement

| Key | Action |
|-----|--------|
| `$mod+j/k/l/ö` | Focus left/up/down/right |
| `$mod+Shift+j/k/l/ö` | Move window left/up/down/right |
| `$mod+Arrow` | Focus (arrow keys) |
| `$mod+Shift+Arrow` | Move (arrow keys) |

#### Workspaces

| Key | Action |
|-----|--------|
| `$mod+1–0` | Switch to workspace 1–10 |
| `$mod+Shift+1–0` | Move window to workspace 1–10 |

#### Media & system

| Key | Action |
|-----|--------|
| `Volume Up/Down` | +/- 5% volume |
| `Mute` | Toggle mute |
| `Mic Mute` | Toggle microphone |
| `Brightness Up/Down` | +/- 2% brightness |
| `Pause` | Screenshot (selection) |
| `Print` | Screenshot (full) |
| `Ctrl+F5` | Toggle ASUS fan mode |

---

### Tmux — prefix: `Ctrl+a`

| Key | Action |
|-----|--------|
| `<prefix>r` | Reload config |
| `<prefix>g` | lazygit popup (80%×80%) |
| `<prefix>e` | ranger popup (90%×90%) |
| `<prefix>Enter` | Popup terminal |
| `<prefix>m` | Sync mail in background (mbsync + mailsort) |

#### Panes

| Key | Action |
|-----|--------|
| `<prefix>h` | Split horizontal |
| `<prefix>v` | Split vertical |
| `<prefix>q` | Kill pane |
| `<prefix>j/k/l/ö` | Focus left/up/down/right |

#### Navigation (vim-tmux-navigator, no prefix)

| Key | Action |
|-----|--------|
| `Alt+j/k/l/ö` | Move between panes and nvim splits seamlessly |

#### Windows

| Key | Action |
|-----|--------|
| `<prefix>c` | Create window |

---

### Neovim

> Leader key: `Space`

#### Movement (remapped)

| Key | Action |
|-----|--------|
| `j` | Left (← h) |
| `k` | Up (← k) |
| `l` | Down (← j) |
| `ö` | Right (← l) |
| `gg` | Beginning of line (← ^) |
| `hh` | End of line (← $) |
| `dd` | Delete line without yanking to clipboard |

#### Navigation between panes

| Key | Action |
|-----|--------|
| `Alt+j/k/l/ö` | Move between nvim splits / tmux panes |

#### Telescope

| Key | Action |
|-----|--------|
| `<leader>Space` | Find files |
| `<leader>g` | Find files (git) |
| `<leader>f` | Grep string |

#### File tree (nvim-tree, floating)

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer |

#### LSP / Completion

| Key | Action |
|-----|--------|
| `<leader>d` | Go to definition |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions |
| `Alt+n` | Cycle next suggestion |
| `Alt+p` | Cycle previous suggestion |
| `Alt+y` | Trigger completion |
| `Alt+Space` | Accept top suggestion |

#### Tests (vim-test)

| Key | Action |
|-----|--------|
| `<leader>t` | Test nearest |
| `<leader>T` | Test file |
| `<leader>a` | Test suite |
| `<leader>L` | Test last |

#### Formatting

| Key | Action |
|-----|--------|
| `Ctrl+f` | Indent function |

#### Commands

| Command | Action |
|---------|--------|
| `:so` | Source current file |
| `:PackerSync` | Install / update plugins |

---

### Neomutt

> Navigation follows the same layout as nvim, tmux and i3:
> `k` = up/previous, `l` = down/next, `ö` = open/right, `j` = back/left
> Sidebar uses uppercase `K/L/Ö` to avoid conflicts with index binds.

#### Index (message list)

| Key | Action |
|-----|--------|
| `k` | Previous message |
| `l` | Next message |
| `ö` | Open message |
| `m` | Compose new message |
| `r` | Reply |
| `R` | Reply all |
| `f` | Forward |
| `d` | Delete |
| `u` | Undelete |
| `F` | Flag |
| `t` | Tag |
| `G` | Sync mail (mbsync) |
| `/` | Search |
| `l` | Limit view by pattern |

#### Pager (reading a message)

| Key | Action |
|-----|--------|
| `k` | Scroll up |
| `l` | Scroll down |
| `j` | Back to index |
| `ö` | Next message |
| `v` | View attachments |
| `p` | PGP menu |
| `Ctrl+b` | Browse URLs in message |

#### Sidebar

| Key | Action |
|-----|--------|
| `K` | Previous mailbox |
| `L` | Next mailbox |
| `Ö` | Open selected mailbox |
| `B` | Toggle sidebar |
