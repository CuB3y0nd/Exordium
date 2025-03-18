#!/bin/bash

qemu-system-i386 -drive file=exordium.img,format=raw,if=ide,index=0 -s -S -monitor stdio
