#!/bin/sh

gdb -ix .gdbinit_real_mode \
  -ex 'set tdesc filename target.xml' \
  -ex 'target remote localhost:1234'
