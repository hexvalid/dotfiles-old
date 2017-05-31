#!/bin/bash

pulseaudio -k && sudo modprobe -rv snd-hda-intel &&  sudo modprobe -v snd-hda-intel patch=hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw,hda-jack-retask.fw 


