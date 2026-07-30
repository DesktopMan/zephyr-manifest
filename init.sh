#!/usr/bin/env bash

OS_TYPE="$(uname -a)"
if [[ "$OS_TYPE" == MINGW* || "$OS_TYPE" == MSYS* || "$OS_TYPE" == CYGWIN* ]]; then
  WINDOWS=1
else
  WINDOWS=0
fi

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "usage: init.sh <SoC family> <Zephyr version> <workspace dir>"
  exit 0
fi

if [ "$1" = "nordic" ] && [ "$2" == "4.4.0" ]; then
  echo "Error: Newest supported Zephyr version for Nordic NCS is 4.3.0"
  exit 1
fi

if [ -d "$3" ]; then
  echo "Workspace already exists. Delete it and rerun the script if you want a clean workspace."
  exit 1
fi

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "UV is not installed. Installing it now..."
  curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --quiet
fi

set -e
set -T
trap '
  printf "\033[1;36m➜ %s\033[0m\n" "$BASH_COMMAND" >&2
' DEBUG

mkdir -p "$3/manifest"
cd "$3"

uv venv --python 3.12
if [ -f .venv/Scripts/activate ]; then
  source .venv/Scripts/activate
elif [ -f .venv/bin/activate ]; then
  source .venv/bin/activate
else
  echo "error: venv not found"
  exit 1
fi

uv pip install west

curl -LsSf https://raw.githubusercontent.com/DesktopMan/zephyr-manifest/refs/heads/main/manifests/$1-$2.yml -o "manifest/west.yml"

west init -l manifest
west update
west zephyr-export

uv pip install $(west packages pip | tr -d '\r')

function install_openocd_esp32 {
  uv pip install openocd-esp32

  OPENOCD_ESP32_URL="https://github.com/espressif/openocd-esp32/releases/download/v0.12.0-esp32-20260703/openocd-esp32-win64-0.12.0-esp32-20260703.zip"
  OPENOCD_ESP32_ZIP="$(mktemp).zip"
  curl -LsSf "$OPENOCD_ESP32_URL" -o "$OPENOCD_ESP32_ZIP"
  OPENOCD_ESP32_TEMP="$(mktemp -d)"
  unzip -q "$OPENOCD_ESP32_ZIP" -d "$OPENOCD_ESP32_TEMP"
  cp -rp "$OPENOCD_ESP32_TEMP/openocd-esp32/share/openocd" .venv/share

  if [ "$WINDOWS" -eq 1 ]; then
    VENV_BIN=$(cygpath -m "$PWD/.venv/Scripts")
	BIN_EXT=".exe"
  else
	VENV_BIN="$PWD/.venv/bin"
  fi

  west config alias.debug "debug --openocd \"$VENV_BIN/openocd-esp32$BIN_EXT\""
  west config alias.debugserver "debugserver --openocd \"$VENV_BIN/openocd-esp32$BIN_EXT\""
}

if [ "$1" = "espressif-s3" ]; then
  install_openocd_esp32
  west blobs fetch hal_espressif --allow-regex '.*esp32s3.*'
  west sdk install -t xtensa-espressif_esp32s3_zephyr-elf
  west config --local build.board adafruit_feather_esp32s3_tft/esp32s3/procpu

  cat <<-'EOF' >> external/zephyr/boards/adafruit/feather_esp32s3_tft/support/openocd.cfg

		set hardware-watchpoint-limit 2

		$_TARGETNAME_0 configure -event reset-init {
		  esp appimage_offset 0x0
		}
	EOF
fi

if [ "$1" = "nordic" ]; then
  west sdk install -t arm-zephyr-eabi
  west config --local build.board nrf7002dk/nrf5340/cpuapp
fi

if [ "$1" = "st-stm32" ]; then
  west sdk install -t arm-zephyr-eabi
  west config --local build.board disco_l475_iot1
fi

mkdir samples
cp -rp external/zephyr/samples/hello_world samples
cp -rp external/zephyr/samples/basic/blinky samples
cp -rp external/zephyr/samples/basic/button samples

west build -p always samples/blinky
rm -r build
