SSHPORT=3333
run:
	docker run --rm -ti -p $$SSHPORT:22 rv64jdk:latest

build: prepare
	(DATETAG=$$(date +%Y%m%d_%H%M) ; docker build . -t rv64jdk:$$DATETAG -t rv64jdk:latest )

try:
	docker run --rm -ti ubuntu:20.04

prepare:
	bash prepare_downloads.sh

remove-downloads:
	rm -f qemu.*.tar.xz

tmux:
	bash tmux_start.sh
.PHONY: run build try prepare remove-downloads tmux
