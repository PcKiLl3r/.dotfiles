make fzf script that finds open sessions

use this command: "sudo localectl set-x11-keymap real-prog-dvo-k pc105 "" terminate:ctrl_alt_bksp
"
to set default keyboard layout

maybe if still doesnt work do this: "
exec --no-startup-id setxkbmap -layout real-prog-dvo-k -option terminate:ctrl_alt_bksp
"
in your i3 config
or this: "
setxkbmap -layout real-prog-dvo-k -option terminate:ctrl_alt_bksp
"
in your .zshrc
or:
Create or edit the /etc/X11/xorg.conf.d/00-keyboard.conf file with the following content:
"
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "real-prog-dvo-k"
    Option "XkbModel" "pc105"
    Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
"

add dbeaver to dnf install

add rofi to dnf install

add light to dnf install

alacrity?

sway/hyperland?

xmonad
awesome WM
Haskell

test if this is dark mode:
gtk-application-prefer-dark-theme=1


install - maybe if there way to make it work...

npm install --save-dev @playwright/test
npx playwright install webkit

for testing different browsers...




sudo dnf install kdeconnectd kdeconnect-cli


✅ 1. KDE Connect (without full KDE) – Works perfectly with i3
📦 Install required packages:
bash
Kopiraj kodo
sudo dnf install kdeconnectd kdeconnect-cli
You don’t need Plasma. You’ll control it via CLI.

📱 On your Z Fold 4:
Install KDE Connect from Play Store.

Ensure both devices are on the same Wi-Fi network.

🔌 On Fedora (i3):
Start the KDE Connect daemon:

bash
Kopiraj kodo
kdeconnectd &
Pair your phone using:

bash
Kopiraj kodo
kdeconnect-cli --list-available
kdeconnect-cli --pair --device <device-id>
📋 To send/receive text:
Copy from phone → PC:

bash
Kopiraj kodo
kdeconnect-cli --device <device-id> --get-clipboard
Send text from PC → phone:

bash
Kopiraj kodo
echo "Hello from i3" | kdeconnect-cli --device <device-id> --share -
🟢 Pro tip: You can add scripts or bind to i3 keybindings to automate text sharing.

