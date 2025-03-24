#!/bin/bash

IMG="exordium.img"

qemu-system-i386 -drive file=$IMG,format=raw,if=ide,index=0 -s -S -monitor stdio
