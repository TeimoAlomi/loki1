#!/usr/bin/env bash
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "[FATAL] run as root." >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get dist-upgrade -yqq

# ── packages ──────────────────────────────────────────────────────────────────
apt-get install -yqq --no-install-recommends \
  zsh git tmux neofetch htop ncdu ripgrep fd-find exa bat cmatrix curl wget \
  plymouth-themes grub2-common lightdm papirus-icon-theme xfce4-whiskermenu-plugin \
  fonts-hack-ttf fonts-jetbrains-mono sassc

# ── live-user ─────────────────────────────────────────────────────────────────
LIVE_USER=$(awk -F: '$3==1000{print $1}' /etc/passwd || true)
LIVE_USER=${LIVE_USER:-kali}
LIVE_HOME=$(eval echo "~$LIVE_USER")

# ── assets ───────────────────────────────────────────────────────────────────
ASSETS=/usr/share/hack-assets
mkdir -p "$ASSETS"
MATRIX_WALL="$ASSETS/matrix.jpg"

if [[ ! -f $MATRIX_WALL ]]; then
  wget -qO "$MATRIX_WALL" https://images2.alphacoders.com/778/77840.jpg
fi

# ── grub ─────────────────────────────────────────────────────────────────────
GRUB_DEFAULT=/etc/default/grub
if ! grep -q 'GRUB_BACKGROUND=' "$GRUB_DEFAULT"; then
  sed -i '/GRUB_TIMEOUT_STYLE/d' "$GRUB_DEFAULT"
  cat >>"$GRUB_DEFAULT" <<EOF
GRUB_TIMEOUT_STYLE=hidden
GRUB_BACKGROUND=$MATRIX_WALL
GRUB_GFXMODE=1920x1080
EOF
  update-grub
fi

# ── plymouth ─────────────────────────────────────────────────────────────────
PLY_THEME_DIR=/usr/share/plymouth/themes/matrix
if [[ ! -d $PLY_THEME_DIR ]]; then
  mkdir -p "$PLY_THEME_DIR"

  cat >"$PLY_THEME_DIR/matrix.plymouth" <<'EOF'
[Plymouth Theme]
Name=Matrix
Description=Green matrix rain
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/matrix
ScriptFile=/usr/share/plymouth/themes/matrix/matrix.script
EOF

  cat >"$PLY_THEME_DIR/matrix.script" <<'EOF'
wallpaper_image = Image("matrix.jpg");
wallpaper_sprite = Sprite();
wallpaper_sprite.SetImage(wallpaper_image);
wallpaper_sprite.SetOpacity(1.0);
loop { Plymouth.Sleep(0.05); }
EOF

  cp "$MATRIX_WALL" "$PLY_THEME_DIR/matrix.jpg"
  update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$PLY_THEME_DIR/matrix.plymouth" 100
  update-alternatives --set default.plymouth "$PLY_THEME_DIR/matrix.plymouth"
  update-initramfs -u
fi

# ── lightdm ──────────────────────────────────────────────────────────────────
LIGHTDM_GTK=/etc/lightdm/lightdm-gtk-greeter.conf
grep -q '^background=.*matrix.jpg' "$LIGHTDM_GTK" 2>/dev/null || \
  echo "background=$MATRIX_WALL" >> "$LIGHTDM_GTK"

# ── xfce theme & wallpaper ───────────────────────────────────────────────────
THEME_TMP=/tmp/graphite
if [[ ! -d $THEME_TMP ]]; then
  git clone --depth=1 https://github.com/vinceliuice/Graphite-gtk-theme.git "$THEME_TMP"
  bash "$THEME_TMP/install.sh" -d /usr/share/themes -c dark -s standard >/dev/null
fi

THEME_NAME="Graphite-Dark"
ICON_NAME="Papirus-Dark"

sudo -u "$LIVE_USER" xfconf-query -c xsettings -p /Net/ThemeName -s "$THEME_NAME" || true
sudo -u "$LIVE_USER" xfconf-query -c xsettings -p /Net/IconThemeName -s "$ICON_NAME" || true

for p in $(xfconf-query -c xfce4-desktop -l | grep last-image || true); do
  sudo -u "$LIVE_USER" xfconf-query -c xfce4-desktop -p "$p" -s "$MATRIX_WALL" || true
done

# ── zsh & p10k ───────────────────────────────────────────────────────────────
if [[ ! -d "$LIVE_HOME/.oh-my-zsh" ]]; then
  sudo -u "$LIVE_USER" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [[ ! -d "$LIVE_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  sudo -u "$LIVE_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$LIVE_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

ZSHRC="$LIVE_HOME/.zshrc"
grep -q powerlevel10k "$ZSHRC" 2>/dev/null || \
  sudo -u "$LIVE_USER" sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"

sudo -u "$LIVE_USER" bash -c "cat >> '$ZSHRC' <<'EOS'
# --- Hacker aliases ---
alias ll='exa -al --color=always --group-directories-first'
alias cat='batcat --paging=never'
alias hack='clear && cmatrix -u 2'
EOS"

chsh -s "$(command -v zsh)" "$LIVE_USER"

# ── tmux ─────────────────────────────────────────────────────────────────────
TMUXCONF="$LIVE_HOME/.tmux.conf"
cat >"$TMUXCONF" <<'EOF'
set -g mouse on
set -g status-bg colour0
set -g status-fg colour2
set -g status-left-length 30
set -g status-right-length 150
set -g status-right "#(whoami)@#H | %Y-%m-%d %H:%M "
set -g pane-border-format "#{pane_title}"
set-option -ga terminal-overrides ",xterm-256color:Tc"
EOF
chown "$LIVE_USER:$LIVE_USER" "$TMUXCONF"

# ── motd ─────────────────────────────────────────────────────────────────────
cat >/etc/profile.d/00-kali-motd.sh <<'EOF'
clear
neofetch --ascii_distro kali
EOF
chmod +x /etc/profile.d/00-kali-motd.sh

echo "[ OK ] visuals loaded. reboot to admire."
