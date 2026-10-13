#!/usr/bin/env bash
# Installs tuios-omalauncher into omalauncher's Linux: tuios (its latest release, checked against the
# release's checksums), the tuios-omalauncher command, the widget and a starter agents.conf.
#   ./install.sh            from a clone of this repo
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
bin=$HOME/.local/bin
widgets=$HOME/.config/omalauncher/widgets
mkdir -p "$bin" "$widgets"

for p in jq curl tar micro; do
  command -v "$p" >/dev/null || { echo "installing $p"; pacman -S --noconfirm --needed "$p" >/dev/null; }
done
command -v pgrep >/dev/null || pacman -S --noconfirm --needed procps-ng >/dev/null

if command -v tuios >/dev/null; then
  echo "tuios $(tuios --version | head -1 | awk '{print $3}') is installed (the widget's settings can update it)"
else
  case $(uname -m) in
    aarch64|arm64) arch=arm64 ;;
    x86_64) arch=x86_64 ;;
    *) echo "no tuios release for $(uname -m)" >&2; exit 1 ;;
  esac
  tag=$(curl -fsSL https://api.github.com/repos/Gaurav-Gosain/tuios/releases/latest | jq -r .tag_name)
  ver=${tag#v}
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  base=https://github.com/Gaurav-Gosain/tuios/releases/download/$tag
  echo "downloading tuios $ver"
  curl -fsSL -o "$tmp/tuios.tar.gz" "$base/tuios_${ver}_Linux_${arch}.tar.gz"
  curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"
  want=$(awk -v f="tuios_${ver}_Linux_${arch}.tar.gz" '$2 == f {print $1}' "$tmp/checksums.txt")
  got=$(sha256sum "$tmp/tuios.tar.gz" | awk '{print $1}')
  [ -n "$want" ] && [ "$want" = "$got" ] || { echo "checksum mismatch for tuios $ver" >&2; exit 1; }
  tar -xzf "$tmp/tuios.tar.gz" -C "$tmp" tuios
  install -m 755 "$tmp/tuios" "$bin/tuios"
  echo "installed tuios $ver"
fi

install -m 755 "$here/bin/tuios-omalauncher" "$bin/tuios-omalauncher"
install -m 644 "$here/widget/tuios.owl" "$widgets/36-tuios.owl"

conf=$HOME/.config/omalauncher/agents.conf
if [ ! -f "$conf" ]; then
  cat >"$conf" <<'EOF'
# Tabs of the tuios widget, one per line: name = command
# Claude Code's default renderer leaves scrolling to tuios, which the widget can drive.
claude = claude --settings '{"tui":"default"}'
term = bash
EOF
fi

"$bin/tuios-omalauncher" setup
echo "done: the widget is on home page 2 (long-press to move it). Its ⚙ has the settings."
