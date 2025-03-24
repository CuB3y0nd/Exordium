%include "include/boot.inc"

[bits 16]
section mbr vstart=0x7c00
  mov ax, 0x0600 ; clear screen
  mov bh, 0x07   ; color attribute 0x07
  xor cx, cx     ; upper left corner
  mov dx, 0x184f ; bottom right corner
  int 0x10

  ; loader will be loaded to ES:DI (0x90000)
  mov ax, LOADER_SEGMENT
  mov es, ax
  xor di, di

  ; set LBA address of the loader
  mov ax, LOADER_SECTOR

  ; sector quantities that awaiting to be read
  ; Note: Since we can sure our loader's total size will greater than 512
  ;       bytes, so set to 4 should large enough.
  mov cx, 0x4

  call read_disk

  jmp LOADER_SEGMENT:0

; read_disk reads memory from the disk in 16 bit mode (adhere LBA28)

read_disk:
  ; backup sector quantities
  mov si, ax

  ; setup sector quantities that we want read
  mov dx, 0x1f2
  mov al, cl
  out dx, al

  ; LBA (7:0)
  mov ax, si
  mov dx, 0x1f3
  out dx, al

  ; LBA (15:8)
  shr ax, 8
  mov dx, 0x1f4
  out dx, al

  ; LBA (23:16)
  shr ax, 8
  mov dx, 0x1f5
  out dx, al

  ; LBA (27:24)
  shr ax, 8
  and al, 0x0f

  ; The fifth and seventh bit are obsoleted, just ignore it and set to 1, keep
  ; the fourth bit with 0 so read from the primary disk and set the sixth bit
  ; to 1, means we use LBA addressing method.
  or al, 0xe0
  mov dx, 0x1f6
  out dx, al

  ; emit read command
  mov dx, 0x1f7
  mov al, 0x20
  out dx, al

; check disk status

.wait_disk:
  nop       ; add a little delay to reduce disturb disk working
  in al, dx ; get disk status

  ; Disk Controller is ready to perform data transfer when the DRQ bit is set
  ; to 1 and the BSY bit is set to 0. Otherwise we keeping waiting until it is
  ; ready.
  and al, 0x88
  cmp al, 0x08
  jnz .wait_disk

; read data from the disk to ES:DI (0x90000)

.read_it:
  ; Note: Each sector have 512 bytes and read 1 word every time) so we need to
  ;       read SECTORS*512/2 (SECTORS*256) times for each.
  shl cx, 8

  mov dx, 0x1f0
  cld
  rep insw
  ; TODO: Add 64KB boundary detection (due we can sure that our loader will
  ;       not exceed 64KB, so i just leave it as a TODO.)
  ret

  times 510-($-$$) db 0
boot_flag:
  dw 0xAA55
