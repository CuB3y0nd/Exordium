%include "include/boot.inc"

LOADER_PHYSICS_ADDR equ (LOADER_SEGMENT << 4)

SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

[bits 16]
section loader vstart=LOADER_PHYSICS_ADDR
; detect available physical memory RAM's size

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

; Note: because max memory area certainly available, we don't need to examine
;       ARDS type

  mov cx, es:[ards_nr]
  mov ebx, ards_buf
  ; we store memory size in EDX
  xor edx, edx
.find_max_mem_area:
  ; BaseAddrLow
  mov eax, [ebx]
  ; BaseAddrLow + LengthLow
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
  mov esi, edx

  ; calculate 16MB ~ 4GB memory size through BX * (64 * 1024B)
  xor eax, eax
  mov ax, bx
  mov ecx, 0x10000
  mul ecx
  add esi, eax
  mov edx, esi
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

; entering protected mode

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

  ; create and initialize page directory table and page tables
  call setup_paging

  ; dump GDT base and limit information to gdt_ptr
  sgdt [gdt_ptr]

  ; mapping the video segment base address to kernel space
  mov ebx, [gdt_ptr + 2]
  or dword [ebx + 0x18 + 4], 0xc0000000

  ; gdt base plus 0xc0000000 becomes the kernel address
  add dword [gdt_ptr + 2], 0xc0000000

  ; mapping stack pointer to kernel space too
  add esp, 0xc0000000

  ; set up page directory base register
  mov eax, PG_DIR
  mov cr3, eax

  ; mark the PG (Paging) bit to 1
  mov eax, cr0
  or eax, 0x80000000
  mov cr0, eax

  ; reload GDT with new GDT address
  lgdt [gdt_ptr]

  mov byte es:[0], 'V'
  mov byte es:[1], 0x07

  cli
  hlt

; setup paging
;
; This routine sets up paging by setting the page bit in CR0. The page tables
; are set up, identity-mapping the first 4MB.  The rest are initialized later.

setup_paging:
  ; sanitize page directory
  mov edi, PG_DIR
  mov ecx, 1024
  xor eax, eax
  rep stosd

.create_pde:
  mov eax, PG_DIR
  ; calculate the address of the first page table entry
  add eax, 0x1000
  mov ebx, eax

  ; set PDE attributes
  or eax, PG_US_U | PG_RW_W | PG_P

  ; since our kernel less than 1MB, so we will just load it kernel to low 1MB
  ; address
  ;
  ; owing to the kernel's virtual address starts at 0xc0000000 (high 1GB memory),
  ; we should mapping the first 1MB memory of the virtual address started at
  ; 0xc0000000 to physical 1MB memory due to our kernel in low 1MB physical
  ; memory
  ;
  ; 0x00 ~ 0xbfffffff, 3GB total, for user programs
  ; 0xc0000000 ~ 0x100000000, 1GB total, for kernel space
  mov [PG_DIR + 0x00], eax
  mov [PG_DIR + 0xc00], eax

  ; set the last PDE pointing to their start address to implement so-called
  ; Page Directory Self-Mapping
  sub eax, 0x1000
  mov [PG_DIR + 4092], eax

  ; 1MB low memory / each page size 4KB = 256 total page table entries
  mov ecx, 256
  mov esi, 0
  mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
  mov [ebx + esi * 4], edx
  add edx, 0x1000
  inc esi
  loop .create_pte

  ; IMPORTANT! for share kernel space in every process, we should determine all
  ; kernel PDEs in advance

  mov eax, PG_DIR
  ; calculate the address of the second page table entry
  add eax, 0x2000
  or eax, PG_US_U | PG_RW_W | PG_P
  mov ebx, PG_DIR
  ; page table entries amounts in 769th (0xc00/4=769) ~ 1022th (last entry had
  ; been used)
  mov ecx, 254
  mov esi, 769
.create_kernel_pde:
  mov [ebx + esi * 4], eax
  add eax, 0x1000
  inc esi
  loop .create_kernel_pde
  ret

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
  times 200 db 0

ards_nr:
  dw 0
