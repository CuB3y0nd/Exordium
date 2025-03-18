.code16
.section .text
.global _start

_start:
  mov $0xb800, %ax
  mov %ax, %es

  movb $'L', %es:[0x00]
  movb $0x07, %es:[0x01]
  movb $'O', %es:[0x02]
  movb $0x07, %es:[0x03]
  movb $'A', %es:[0x04]
  movb $0x07, %es:[0x05]
  movb $'D', %es:[0x06]
  movb $0x07, %es:[0x07]
  movb $'E', %es:[0x08]
  movb $0x07, %es:[0x09]
  movb $'R', %es:[0x0a]
  movb $0x07, %es:[0x10]

  jmp .
