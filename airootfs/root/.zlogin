# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi
systemctl enable --now NetworkManager
chmod +x /root/archscript/start.sh

if [[ "$(tty)" == "/dev/tty1" ]]; then
startx
fi

