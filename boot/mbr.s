SECTION MBR vstart=0x7c00
  mov ax, cs
  mov es, ax
  mov ss, ax
  mov sp, 0x7c00 ; 0x7c00 down as stack is temporary safe

  mov ax, 0x0600 ; clear screen
  mov bh, 0x07   ; color attribute 0x07
  xor cx, cx     ; upper left corner
  mov dx, 0x184f ; bottom right corner
  int 0x10

  mov ah, 0x03   ; get cursor position
  xor bh, bh     ; video page 0
  int 0x10

  mov cx, 0x03   ; length of string
  mov ax, 0x1301 ; write string, move cursor
  mov bx, 0x07   ; video page 0, color attribute 0x07
  lea bp, [msg]  ; ES:BP is the pointer to string
  int 0x10

  jmp $

msg db "MBR"

times 510-($-$$) db 0x00
dw 0xAA55
