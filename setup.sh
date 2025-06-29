!/bin/bash

# Установка русской клавы
setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"

# Тёмная тема и обои
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/kali/kali-dark.png'

# Aliases
echo "alias ll='ls -la'" >> ~/.bashrc
echo "alias ..='cd ..'" >> ~/.bashrc
echo "alias py='python3'" >> ~/.bashrc
echo "alias serve='python3 -m http.server 8080'" >> ~/.bashrc
source ~/.bashrc

# Настройка Vim
echo 'set number' >> ~/.vimrc
echo 'syntax on' >> ~/.vimrc
echo 'set mouse=a' >> ~/.vimrc

# Проверка Flask
if ! command -v flask &> /dev/null; then
    echo "[*] Installing Flask..."
    pip3 install flask
fi

# Готово
echo -e "\n[+] Хакерское окружение готово!"

wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"

sudo apt install ./vscode.deb

setxkbmap -layout "us,ru" -option "grp:alt_shift_toggle"
