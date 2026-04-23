#!/usr/bin/env bash

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

if [ "$1" = "espressif-s3" ]; then
  west blobs fetch hal_espressif
  west sdk install -t xtensa-espressif_esp32s3_zephyr-elf
  west config --local build.board adafruit_feather_esp32s3_tft/esp32s3/procpu
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
cp -r external/zephyr/samples/hello_world samples
cp -r external/zephyr/samples/basic/blinky samples
cp -r external/zephyr/samples/basic/button samples

west build -p always samples/blinky
rm -r build

