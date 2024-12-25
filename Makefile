#!/bin/env make -f

NAME = simple-zram
VERSION := $(shell cat VERSION)

SRC = $(PWD)/src
BUILD_DIR = $(PWD)/build/$(NAME)-$(VERSION)

DEBIAN_DIR = $(BUILD_DIR)/DEBIAN
ETC_DIR = $(BUILD_DIR)/etc
USR_DIR = $(BUILD_DIR)/usr

DEB = $(PWD)/$(NAME)_$(VERSION)_all.deb

.PHONY: all clean build

build:
	@mkdir -vp $(DEBIAN_DIR) \
		$(ETC_DIR) \
		$(USR_DIR)/bin \
		$(USR_DIR)/lib/systemd/system

	@cp -av $(SRC)/$(NAME).conf $(ETC_DIR)/
	@cp -av $(SRC)/$(NAME).service $(USR_DIR)/lib/systemd/system/

	@cp -av $(SRC)/$(NAME) $(USR_DIR)/bin/
	@chmod 755 $(USR_DIR)/bin/$(NAME)

	@sed -i "s/VERSION=/VERSION=$(VERSION)/g" $(USR_DIR)/bin/$(NAME)

ifeq ($(DEBIAN),y)
	@cp -va $(SRC)/debian/* $(DEBIAN_DIR)/
	@sed -i "s/Version:/Version: $(VERSION)/g" $(DEBIAN_DIR)/control
	@sed -i "s/Maintainer:/Maintainer: $(shell git config user.name) <$(shell git config user.email)>/g" \
		$(DEBIAN_DIR)/control

# Set permission for postinst and prerm
	@chmod 755 $(DEBIAN_DIR)/postinst $(DEBIAN_DIR)/prerm

# Create the MD5sums file
	@find $(BUILD_DIR) -type f -exec md5sum {} \; > $(DEBIAN_DIR)/md5sums
	@sed -i "s|$(BUILD_DIR)/||" $(DEBIAN_DIR)/md5sums
	@sed -i "/DEBIAN\//d" $(DEBIAN_DIR)/md5sums

# Build the deb package
	@dpkg-deb --root-owner-group --build $(BUILD_DIR) build/$(NAME)_$(VERSION)_all.deb

endif

install:
	@cp -av $(USR_DIR)/bin/$(NAME) /usr/bin/
	@cp -av $(ETC_DIR)/$(NAME).conf /etc/
	@cp -av $(USR_DIR)/lib/systemd/system/$(NAME).service /lib/systemd/system/

	@systemctl is-active --quiet $(NAME) && systemctl daemon-reload ||
		systemctl enable --now $(NAME)

uninstall:
	@systemctl is-active --quiet $(NAME) && systemctl disable --now $(NAME) || true
	@rm -vf /usr/bin/$(NAME) /etc/$(NAME).conf /lib/systemd/system/$(NAME).service

clean:
	rm -rvf $(BUILD_DIR) $(DEB)