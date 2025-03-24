%include "include/boot.inc"

LOADER_PHYSICS_ADDR equ (LOADER_SEGMENT << 4)

SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

[bits 16]
section loader vstart=LOADER_PHYSICS_ADDR
  ; load global description table
  lgdt es:[gdt_ptr]

  ; open A20 Gate
  in al, 0x92
  or al, 0b00000010
  out 0x92, al

  ; set PE (Protection Enable) bit of CR0 to 1
  mov eax, cr0
  or eax, 0b00000001
  mov cr0, eax

  ; refresh the pipeline so we can enter protected mode
  jmp dword SELECTOR_CODE:protected_mode_entry

[bits 32]
protected_mode_entry:
  mov ax, SELECTOR_DATA
  mov ds, ax
  mov ss, ax
  mov esp, LOADER_PHYSICS_ADDR
  mov ax, SELECTOR_VIDEO
  mov es, ax

  mov byte es:[0], 'P'
  mov byte es:[1], 0x07

  jmp $

_gdt:
  dd 0x00000000, 0x00000000
  dd 0x0000FFFF, DESC_CODE_HIGH
  dd 0x0000FFFF, DESC_DATA_HIGH
  dd 0x80000007, DESC_VIDEO_HIGH

GDT_SIZE equ $ - _gdt
GDT_LIMIT equ GDT_SIZE - 1

gdt_ptr:
  dw GDT_LIMIT
  dd _gdt
