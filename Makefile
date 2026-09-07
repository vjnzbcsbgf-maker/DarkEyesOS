# DarkEyesOS convenience Makefile. Real logic lives in build.sh + live-build.
SHELL := /bin/bash
OUT := out
ISO := $(OUT)/darkeyes-amd64.hybrid.iso
DEV ?=

.PHONY: help deps config build iso vm flash lint clean distclean

help:
	@echo "DarkEyesOS build targets:"
	@echo "  make deps      Install build dependencies"
	@echo "  make config    Validate live-build configuration (lb config)"
	@echo "  make build     Full build -> $(ISO)  (needs sudo)"
	@echo "  make iso       Alias for build"
	@echo "  make vm        Boot the built ISO in QEMU"
	@echo "  make flash DEV=/dev/sdX   Flash ISO to USB (DESTRUCTIVE)"
	@echo "  make lint      Shellcheck hooks/tools + validate configs"
	@echo "  make clean     lb clean + remove $(OUT)"
	@echo "  make distclean Also drop caches"

deps:
	sudo ./build.sh deps

config:
	sudo ./build.sh config

build:
	sudo ./build.sh build

iso: build

vm: $(ISO)
	qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm \
		-cdrom $(ISO) -boot d -vga virtio || \
	qemu-system-x86_64 -m 2048 -smp 2 -cdrom $(ISO) -boot d

flash: $(ISO)
	@test -n "$(DEV)" || { echo "Set DEV=/dev/sdX"; exit 1; }
	sudo ./scripts/flash-usb.sh $(ISO) $(DEV)

lint:
	./scripts/lint.sh

clean:
	sudo lb clean --purge 2>/dev/null || true
	rm -rf $(OUT) darkeyes-build.log

distclean: clean
	sudo lb clean --all 2>/dev/null || true
	rm -rf cache .build
