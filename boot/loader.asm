%include "include/boot.inc"

LOADER_PHYSICS_ADDR equ (LOADER_SEGMENT << 4)

SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

[bits 16]
section loader vstart=LOADER_PHYSICS_ADDR
  ; next ARDS that waiting to return, zero out it in the first call
  xor ebx, ebx
  ; fixed signature: SMAP (System Memory MAP)
  mov edx, 0x534d4150
  ; ES:DI represents the ARDS buffer
  mov di, ards_buf

.e820:
  mov eax, 0xe820
  ; ARDS size (bytes that BIOS writing)
  mov ecx, 20
  int 0x15

  ; if CF flag setted to 1 (an error occurred), try 0xe801 function
  jc .e801

  ; point to next ARDS
  add di, cx
  ; increase ARDS counts
  inc dword es:[ards_nr]
  ; all ARDS are returned if EBX = 0 and CF != 1
  cmp ebx, 0
  jnz .e820

; find (BaseAddrLow + LengthLow)'s max value, since we are building 32-bit
; architecture os, no need high address, this will be our physical memory size

; Note: because max memory area certainly available, we don't need to examine ARDS type

  mov cx, es:[ards_nr]
  mov ebx, ards_buf
  ; we store memory size in EDX
  xor edx, edx
.find_max_mem_area:
  ; BaseAddrLow
  mov eax, [ebx]
  ; LengthLow
  add eax, [ebx + 8]
  ; point to next ARDS
  add ebx, 20

  ; bubble sort
  cmp edx, eax
  jge .next_ards
  mov edx, eax
.next_ards:
  loop .find_max_mem_area
  jmp .mem_get_ok

.e801:
  mov ax, 0xe801
  int 0x15

  ; if CF flag setted to 1 (an error occurred), try 0x88 function
  jc .88

  ; calculate the low 15MB memory size through AX * 1024B
  mov cx, 0x400
  mul cx
  shl edx, 16
  and eax, 0x0000FFFF
  or edx, eax
  add edx, 0x100000

  ; calculate 16MB ~ 4GB memory size through BX * (64 * 1024B)
  xor eax, eax
  mov ax, bx
  mov ecx, 0x10000
  mul ecx
  add edx, eax
  jmp .mem_get_ok

.88:
  mov ah, 0x88
  int 0x15

  ; if CF flag setted to 1 (an error occurred), we've failed miserably :(
  jc .all_failed

  ; calculate total memory size through AX * 1024B + 1MB
  and eax, 0x0000FFFF
  mov cx, 0x400
  mul cx
  shl edx, 16
  or edx, eax
  add edx, 0x100000

.mem_get_ok:
  mov es:[total_memory_bytes], edx

  ; load global description table
  mov ax, 0x9000
  mov ds, ax
  lgdt [gdt_ptr]

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

.all_failed:
  cli
  hlt
  jmp .all_failed

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

  cli
  hlt

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

total_memory_bytes:
  dd 0

ards_buf:
  times 244 db 0

ards_nr:
  dw 0
