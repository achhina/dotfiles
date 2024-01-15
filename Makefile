SHELL := /bin/bash
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
DEFAULTS := $(ROOT_DIR)bash/defaults

HOME := $(shell realpath $(or $(shell awk -F= '/XDG_HOME=/ {print $$2}' $(DEFAULTS)), $(HOME)))
CONFIG_HOME := $(shell realpath $(or $(shell awk -F= '/XDG_CONFIG_HOME=/ {print $$2}' $(DEFAULTS)), $(HOME)/.config))
TIMESTAMP := $(shell date +%Y-%m-%d-%H-%M-%S)

.PHONY: all clean test

all: $(HOME)/.zshrc

$(HOME)/.zshrc: $(CONFIG_HOME)/zsh/zshrc
	@if [ -e "$(HOME)/.zshrc" ]; then \
		echo "Creating backup and linking .zshrc"; \
		mkdir -p $(CONFIG_HOME)/backup/$(TIMESTAMP); \
		mv "$(HOME)/.zshrc" "$(CONFIG_HOME)/backup/$(TIMESTAMP)/"; \
	fi
	@ln -s "$(CONFIG_HOME)/zsh/zshrc" "$(HOME)/.zshrc"
