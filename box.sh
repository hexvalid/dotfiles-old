#!/bin/bash


function copy() {
	mkdir -p portage
	mkdir -p linux
	mkdir -p linux/patches
	cp -v /etc/portage/make.conf portage/
	cp -v /etc/portage/package.accept_keywords portage/
	cp -v /etc/portage/package.license portage/
	cp -v /etc/portage/package.use portage/
	cp -v /usr/src/linux/.config linux/
	cp -v /usr/src/linux/patches/* linux/patches/
}

function install() {
	cp portage/* /etc/portage/
	cp linux/.config /usr/src/linux/.config
	mkdir /usr/src/linux/patches/
	cp linux/patches/* /usr/src/linux/patches/
}


case "$1" in
      "copy")
        copy
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
        echo "Usage: $0 {copy|push|pull|install|version}"
        exit 1
        ;;
esac




