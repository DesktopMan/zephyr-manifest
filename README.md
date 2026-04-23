# Zephyr West Manifest

This repository provides west manifests for working with the Zephyr RTOS, pinned to a specific Zephyr version.

Each manifest is configured for a specific SoC family and Zephyr version for a storage optimized workspace.

## init.sh

**init.sh** is a cross platform Bash script that initializes a complete T3 workspace and builds an example to ensure that everything works.

Dependencies: Zephyr platform dependencies. UV and the required SDK will be installed automatically.

Script parameters: SoC family, Zephyr version and workspace directory.

SoC families:

* espressif-s3
* nordic
* st-stm32

Versions:

* 4.3.0
* 4.4.0

### Espressif S3

```bash
curl -sL https://raw.githubusercontent.com/DesktopMan/zephyr-manifest/main/init.sh | bash -s espressif-s3 4.4.0 zephyr-workspace
```

### Nordic Connect SDK

This will install NCS v3.3.0, which ships with Zephyr 4.3.0. Zephyr 4.4.0 is not supported.

```bash
curl -sL https://raw.githubusercontent.com/DesktopMan/zephyr-manifest/main/init.sh | bash -s nordic 4.3.0 zephyr-workspace
```

### ST STM32

```bash
curl -sL https://raw.githubusercontent.com/DesktopMan/zephyr-manifest/main/init.sh | bash -s st-stm32 4.4.0 zephyr-workspace
```

