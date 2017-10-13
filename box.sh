#!/bin/bash


function symlink() {
	ln -sf /etc/portage/make.conf portage/
	ln -sf /etc/portage/package.accept_keywords portage/
	ln -sf /etc/portage/package.license portage/
	ln -sf /etc/portage/package.use portage/
	ln -sf /usr/src/linux/.config linux/
	ln -sf /usr/src/linux/patches/ linux/
}

function install() {
	cp portage/* /etc/portage/
	cp linux/.config /usr/src/linux/.config
	mkdir /usr/src/linux/patches/
	cp linux/patches/* /usr/src/linux/patches/
}


case "$1" in
      "symlink")
        symlink
	;;
      "install")
        install
        ;;
      "?")
        echo "Unknown option $OPTARG"
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        ;;
      *)
        echo "Usage: $0 {symlink|push|pull|install|version}"
        exit 1
        ;;
esac




