# debian-slim-rescue Makefile

.PHONY: help setup rescue ramboot status install uninstall test lint

INSTALL_PREFIX ?= /usr/local
DSR_BIN       := $(INSTALL_PREFIX)/bin/dsr
DSR_LIB       := $(INSTALL_PREFIX)/lib/debian-slim-rescue

help:
	@echo "debian-slim-rescue"
	@echo ""
	@echo "  make setup      Run minbian desktop setup"
	@echo "  make rescue     Build minidebian rescue initramfs"
	@echo "  make ramboot    Install ramboot module"
	@echo "  make status     Show system info"
	@echo "  make install    Install dsr to $(INSTALL_PREFIX)"
	@echo "  make uninstall  Remove installed files"
	@echo "  make lint       Run shellcheck on all scripts"
	@echo "  make test       Run test suite"

setup:
	bash dsr setup

rescue:
	sudo bash dsr rescue

ramboot:
	sudo bash dsr ramboot

status:
	bash dsr status

install:
	install -d $(DSR_LIB)/shared/lib $(DSR_LIB)/shared/config
	install -d $(DSR_LIB)/minbian/scripts
	install -d $(DSR_LIB)/minidebian
	install -d $(DSR_LIB)/ramboot/dracut/modules.d/90ramboot
	install -d $(DSR_LIB)/ramboot/initramfs-tools/hooks
	install -d $(DSR_LIB)/ramboot/initramfs-tools/scripts/local-premount
	cp -r shared/. $(DSR_LIB)/shared/
	cp -r minbian/. $(DSR_LIB)/minbian/
	cp -r minidebian/. $(DSR_LIB)/minidebian/
	cp -r ramboot/. $(DSR_LIB)/ramboot/
	sed "s|SCRIPT_DIR=.*|SCRIPT_DIR=$(DSR_LIB)|" dsr > $(DSR_BIN)
	chmod +x $(DSR_BIN)
	@echo "Installed: $(DSR_BIN)"

uninstall:
	rm -f $(DSR_BIN)
	rm -rf $(DSR_LIB)
	@echo "Uninstalled."

lint:
	@command -v shellcheck >/dev/null || { echo "shellcheck not found"; exit 1; }
	shellcheck dsr shared/lib/common.sh
	shellcheck minbian/main.sh minbian/scripts/*.sh 2>/dev/null || true
	shellcheck minidebian/main.sh minidebian/make_initrd minidebian/make_system 2>/dev/null || true
	shellcheck ramboot/dracut/modules.d/90ramboot/ramboot.sh \
	           ramboot/dracut/modules.d/90ramboot/ramboot-lib.sh \
	           ramboot/dracut/modules.d/90ramboot/ramboot-cleanup.sh \
	           ramboot/initramfs-tools/hooks/ramboot \
	           ramboot/initramfs-tools/scripts/local-premount/ramboot

test:
	@echo "Running tests..."
	bash tests/test-common.sh
	bash tests/test-ramboot-lib.sh
	@echo "All tests passed."
