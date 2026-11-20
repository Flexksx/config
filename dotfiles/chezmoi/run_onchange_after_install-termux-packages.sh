#!/bin/sh
set -eu

pkg install -y \
	atuin \
	bat \
	dust \
	eza \
	fastfetch \
	fd \
	fzf \
	git-delta \
	gitui \
	glow \
	gping \
	jq \
	just \
	lazygit \
	lnav \
	procs \
	python-yt-dlp \
	ripgrep \
	starship \
	tree \
	xh \
	zellij \
	zoxide \
	zsh

chsh -s "$(command -v zsh)"
