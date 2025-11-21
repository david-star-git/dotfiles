# Installation



# Keybinds

## i3



## Tmux

- `C-a` - > prefix
- `<prefix>r` - > reload config
- `<prefix>g` - > lazygit
- `<prefix>e` - > ranger
- `<prefix>Enter` - > popup terminal

### Movement

- `<prefix>j` - > left
- `<prefix>k` - > up
- `<prefix>l` - > down
- `<prefix>ö` - > right

### pane

- `<prefix>h` - > horizontal
- `<prefix>v` - > vertical
- `<prefix>q` - > kill pane

### window

- `<prefix>c` - > create

## Nvim

## Remap

- `gg` - > Beginning of Line
- `hh` - > End of Line
- `j` - > left
- `k` - > up
- `l` - > down
- `ö` - > right

## Telescope

- `<leader> ` - > Find Files
- `<leader>g` - > Find Files in Git
- `<leader>f` - > Find Files Grep

## Tests

- `<leader>t` -> Test Nearest
- `<leader>T` -> Test File
- `<leader>a` -> Test Suite
- `<leader>L` -> Test Last
- `<leader>g` -> Test Visit

## LSP

- `<M-n>` - > Cycle next
- `<M-p>` - > Cycle prev
- `<M-y>` - > Accept
- `<M-Space>` - > Accept Top

## etc

- `C-f` - > Indent Function
- `<leader>e` - > Explorer

## commands

- `:so` - > source file
- `:PackerSync`

# Post Install

## Setup

### shell

```sh
chsh
```
-> /usr/bin/zsh

### nvim

`:PackerSync`

```sh
:MasonInstall black clangd css-lsp html-lsp stylua prettier
```

### tmux

`<prefix>r` `<prefix>I`

## SSH key

1. Generate Key: `ssh-keygen -t ed25519 -C "your_email@example.com"`
2. Copy the public key: `cat ~/.ssh/id_ed25519.pub`
3. Add the public key to github: `Settings -> SSH and GPG keys -> New SSH key`
4. Test it: `ssh -T git@github.com`
5. If cloned via http set origin to use ssh: `git remote set-url origin git@github.com:david-star-git/dotfiles.git`
