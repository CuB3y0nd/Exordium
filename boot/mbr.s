.code16
.section .text
.global _main

_main:
  mov %cs, %ax
  mov %ax, %ss
  mov %ax, %sp
  mov $0xb800, %ax
  mov %ax, %es

  mov $0x0600, %ax # clear screen
  mov $0x07, %bh   # color attribute 0x07
  xor %cx, %cx     # upper left corner
  mov $0x184f, %dx # bottom right corner
  int $0x10

  movb $'M', %es:[0x00]
  movb $0x07, %es:[0x01]
  movb $'B', %es:[0x02]
  movb $0x07, %es:[0x03]
  movb $'R', %es:[0x04]
  movb $0x07, %es:[0x05]

  jmp .
