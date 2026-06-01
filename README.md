# debian-slim-rescue

A unified toolkit for minimal Debian systems — slim desktop setup, RAM-based rescue initramfs, and distro-agnostic RAM-root boot.

Merges three upstream projects into a single coherent tool:

| Component | Origin | Purpose |
|---|---|---|
| `minbian/` | [alexmolinaws/minbian](https://github.com/alexmolinaws/minbian) | Post-install minimal Debian desktop setup |
| `minidebian/` | [h-yamamo/minidebian](https://github.com/h-yamamo/minidebian) | RAM-based rescue initramfs (~50 MB) |
| `ramboot/` | [arcmags/ramroot](https://github.com/arcmags/ramroot) (ported) | Load root filesystem to zram at boot |

## Quick start

```bash
# Post-install desktop setup (run as normal user with sudo)
./dsr setup

# Build a rescue initramfs (run as root)
sudo ./dsr rescue

# Install the ramboot module (run as root)
sudo ./dsr ramboot

# Show system info
./dsr status
```

## Components

### minbian — slim desktop setup

Interactive post-install script for a minimal Debian desktop. Detects architecture (x86_64, i386, arm64, armhf, riscv64), RAM, and user preferences, then installs and configures a lightweight desktop environment.

```bash
./dsr setup
# or directly:
bash minbian/main.sh
```

### minidebian — rescue initramfs

Builds a ~50 MB initramfs containing a complete rescue environment. Boots entirely from RAM — no disk required after boot.

```bash
sudo ./dsr rescue
# or directly:
sudo bash minidebian/main.sh
```

Supports: amd64, i386, arm64 (with appropriate kernel).

### ramboot — RAM-root boot module

Loads the root filesystem into a zram device during early boot. Works with both **dracut** (Fedora, openSUSE, Debian 12+, Arch) and **initramfs-tools** (Debian/Ubuntu).

```bash
sudo ./dsr ramboot
```

Configure via `/etc/ramboot.conf`:

```bash
RAMBOOT_ENABLE=auto    # auto | yes | no
RAMBOOT_DEFAULT=n      # default prompt answer
RAMBOOT_RAM_MIN=750    # minimum RAM required (MiB)
RAMBOOT_RAM_PREF=4000  # auto-enable threshold (MiB)
RAMBOOT_ALGO=lz4       # compression: lz4 | lzo | zstd
```

After configuration changes, regenerate the initramfs:
```bash
# dracut
dracut -f --add ramboot

# initramfs-tools
update-initramfs -u
```

## Architecture support

| Arch | minbian | minidebian | ramboot |
|---|---|---|---|
| amd64 (x86_64) | ✅ | ✅ | ✅ |
| i386 | ✅ | ✅ | ✅ |
| arm64 (aarch64) | ✅ | ✅ | ✅ |
| armhf | ✅ | — | ✅ |
| riscv64 | ✅ | — | ✅ |

## Requirements

- Debian 11 (bullseye) or later, Ubuntu 20.04+, or any Debian derivative
- `minbian`: user in `sudo` group
- `minidebian`: root, kernel with initramfs, `debootstrap`, `zstd`
- `ramboot`: root, `dracut` or `initramfs-tools`, kernel with `zram` + `ext4`

## Shared library

`shared/lib/common.sh` provides utilities used by all components:
- Architecture and distro detection
- RAM detection
- Logging helpers
- apt wrappers

## License

GPL-3.0 — see [LICENSE](LICENSE).

Upstream licenses:
- minbian: GPL-3.0 ([alexmolinaws/minbian](https://github.com/alexmolinaws/minbian))
- minidebian: see [minidebian/README.md](minidebian/README.md)
- ramroot: GPL-3.0 ([arcmags/ramroot](https://github.com/arcmags/ramroot))
