#!/bin/bash

IMG="exordium.img"

qemu-system-i386 -drive file=$IMG,format=raw,if=ide,index=0 -m 32M -s -S -monitor stdio
