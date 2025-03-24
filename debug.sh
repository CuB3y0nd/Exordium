#!/bin/sh

gdb -ix gdb/.gdbinit \
  -ex 'set tdesc filename gdb/target.xml' \
  -ex 'target remote localhost:1234'
