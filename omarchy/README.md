# Omarchy

Tudo que difere da instalação padrão do [Omarchy](https://omarchy.org/) (Arch +
Hyprland, config em Lua) no meu notebook, e como refazer numa instalação nova.

Última verificação: 2026-11-07, Omarchy 4.0.6, Hyprland 0.56. A lista foi obtida
com `diff` entre `~/.config/...` e os templates em `/usr/share/omarchy/config/`.

## Reinstalação rápida

```bash
git clone git@github.com:andlima/dot-files.git ~/Work/dot-files   # ou https antes de ter a chave SSH
~/Work/dot-files/omarchy/bootstrap.sh --monitors   # --monitors só no mesmo modelo de notebook
```

O script é idempotente: roda de novo à vontade, só mexe no que estiver diferente
e guarda backup `*.bak.<epoch>` ao lado de cada arquivo que substitui. No fim
ele lista os passos manuais que faltam (login do gh, chave no GitHub, mouse BT).

**Não rode o `setup.sh` da raiz no Omarchy.** Ele cria `~/.emacs`, que o Emacs
prefere a `~/.config/emacs/`, e `~/.gitconfig`, que duplica `~/.config/git/config`.

## O que muda, item por item

### Hyprland: `hypr/input.lua` → `~/.config/hypr/input.lua`

Omarchy carrega os defaults dele e depois esse arquivo, então cada bloco
`hl.config({...})` no fim do arquivo sobrescreve só a chave que menciona.

| # | O quê | Config | Default do Omarchy |
|---|-------|--------|--------------------|
| 1 | Caps Lock vira Ctrl extra; Shift+Shift ativa o Caps real | `kb_options = "ctrl:nocaps,shift:both_capslock_cancel"` | `compose:caps,...` |
| 2 | Scroll natural só no touchpad, convencional em qualquer mouse | `natural_scroll = false` + `touchpad.natural_scroll = true` | natural em tudo |
| 3 | Mouse BT BM-615: sensibilidade 0.3, aceleração flat | `hl.device({ name = "bm-615-mouse", ... })` | adaptive, 0 |
| 4 | Swipe horizontal de 3 dedos troca de workspace | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` | sem gestos |
| 5 | Foco só muda com clique (click-to-focus) | `follow_mouse = 2` | `1` (foco segue o mouse) |

Sobre o item 5: modo 2 mantém hover e scroll na janela sob o cursor, mas só o
clique move o foco do teclado. Modo 0 seria a versão estrita.

Depois de qualquer edição: `hyprctl reload && hyprctl configerrors`. Gestos não
aparecem em `hyprctl getoption`; a validação é `configerrors` vazio.

### Hyprland: `hypr/monitors.lua` → `~/.config/hypr/monitors.lua`

Painel interno eDP-2 1920x1080 com escala 1.25 e `GDK_SCALE` 1 (template: 2 e
`"auto"`). Específico do hardware, por isso só entra com `--monitors`. Em outra
máquina use `omarchy hyprland monitor scaling <valor>`.

### Tamanho do texto

`omarchy display text size 11` (default 12px). Esse comando único ajusta shell,
GTK (fator ~0.91) e terminais (Alacritty e Ghostty ficam em 8pt em vez de 9pt).
É isso que explica os diffs em `alacritty.toml` e `ghostty/config`; esses
arquivos não são versionados aqui porque o comando os regenera.

### tmux

tmux 3.7 carrega `~/.tmux.conf` **e depois** `~/.config/tmux/tmux.conf` (o do
Omarchy, prefix `C-Space`), então o do Omarchy vence silenciosamente. Solução:

- `~/.tmux.conf` é symlink para o `.tmux.conf` da raiz deste repo (prefix `C-z`,
  `|`/`-` para split, `C-n`/`C-p`, `prefix r` recarrega). O copy/paste usa
  `wl-copy`/`wl-paste` quando existem e cai para `xsel` em X11.
- O arquivo do Omarchy fica intacto, com `source-file ~/.tmux.conf` como última
  linha. `omarchy refresh tmux` apaga essa linha; rode o bootstrap de novo.

### git: `git/config` → `~/.config/git/config`

Template do Omarchy mais: identidade, credential helper `!gh auth git-credential`
(apontando para o `gh` do PATH, não para o caminho versionado do mise, que
quebra a cada `mise upgrade`) e `url.git@github.com:.insteadOf=https://github.com/`
para todo remote do GitHub usar SSH.

### SSH: `ssh/config` → `~/.ssh/config`

Chave `~/.ssh/id_ed25519` sem passphrase (o disco é criptografado, não há
ssh-agent). O bootstrap gera a chave se não existir; registrar no GitHub é manual:
`gh ssh-key add ~/.ssh/id_ed25519.pub` (precisa de `gh auth refresh -s admin:public_key`).

### mise: `mise/config.toml` → `~/.config/mise/config.toml`

CLIs de desenvolvimento via mise, nunca via pacman (`github-cli`, `uv` do pacman
são evitados de propósito): `claude`, `codex`, `copilot`, `gh`, `pi`, `pipx`,
`uv` em `latest`; `node` fixado em `26.8.2`. `pipx` existe só para o specbutler
(`bootstrap.sh --spec`), porque `spec update` só entende instalações pipx.

Depois do bootstrap: `gh auth login --web`, depois `gh config set git_protocol ssh`.

### Emacs: `emacs/{early-init.el,init.el}` → `~/.config/emacs/`

`pacman -S emacs-wayland` (31.1, PGTK + native-comp). Alternativa não usada:
`omarchy install editor emacs` (pacote AUR `omarchy-emacs` com tema integrado).
Config: modus-vivendi-tinted, JetBrainsMono Nerd Font 11, which-key, tree-sitter,
eglot, MELPA (vertico, orderless, marginalia, magit). `C-z` fica livre porque é o
prefix do tmux. Cache em `~/.cache/emacs/`. Nunca deixe `~/.emacs.d` vazio nem
`~/.emacs` existir: o Emacs prefere ambos a `~/.config/emacs/`.

### Bluetooth

Mouse BM-615, MAC `13:05:AA:00:01:4F`: `bluetoothctl` → `scan on`, `pair`,
`trust` (reconecta sozinho), `connect`. Nome no Hyprland: `bm-615-mouse`
(`hyprctl devices -j`, `mice[].name`).

## Como manter este registro

Toda vez que mudar algo fora do padrão:

1. Edite o arquivo real em `~/.config/...`, valide (`hyprctl configerrors`).
2. Copie para a pasta correspondente aqui e adicione uma linha nesta lista.
3. Se o passo não for um arquivo (comando `omarchy ...`, pacote), ponha no
   `bootstrap.sh` de forma idempotente.
4. Commit.

Para conferir se algo escapou: `diff /usr/share/omarchy/config/hypr/input.lua ~/.config/hypr/input.lua`
e o mesmo para os outros arquivos em `/usr/share/omarchy/config/`.
