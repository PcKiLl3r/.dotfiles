Configure ranger:
```
echo "set preview_script ~/.config/ranger/scope.sh" >> ~/.config/ranger/rc.conf
echo "set use_preview_script true" >> ~/.config/ranger/rc.conf
echo "set preview_files true" >> ~/.config/ranger/rc.conf
```

uninstall nano-default-editor

git config --global rerere.enabled true

git config --global rebase.autoStash true

start using ghostty
    - faster terimnal


fix docker defaults:
V določenih infrastrukturah lahko pride do podvajanja omrežij, saj Docker po defaultu uporablja 172.17.0.0/16. Če želimo nastaviti svoj range IP-jev, ki ga bo Docker uporabljal, ustvarimo datoteko na `/etc/docker/daemon.json` in vnesemo:
```
{
  "live-restore": true,
  "bip": "172.31.100.1/24",
  "default-address-pools": [
    {
      "base": "172.31.100.0/22",
      "size": 24
    }
  ]
}
```
