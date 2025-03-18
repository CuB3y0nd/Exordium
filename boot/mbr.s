.code16
.section .text
.include "includes/boot.inc"
.global _start

_start:
  xor %ax, %ax
  mov %ax, %ds
  mov %ax, %ss
  mov $0x7c00, %sp

  mov $0x0600, %ax /* clear screen */
  mov $0x07, %bh   /* color attribute 0x07 */
  xor %cx, %cx     /* upper left corner */
  mov $0x184f, %dx /* bottom right corner */
  int $0x10

  mov $LOADER_SECTOR, %eax
  mov $LOADER_BASE, %bx

  /* sector quantities that awaiting to write */
  /* Note: Since we can sure our loader total size will less than 512 bytes,
   * so set to 1 is enough. */
  mov $1, %cx

  call read_disk

  ljmp $0, $LOADER_BASE

/*
 * read_disk read memory from the disk in 16 bit mode (adhere LBA28)
 */

read_disk:
  /* backup registers */
  mov %eax, %esi

  /* setup sector quantities that we want read */
  mov $0x01f2, %dx
  mov %cl, %al
  out %al, %dx

  /* LBA (7:0) */
  mov %esi, %eax
  mov $0x01f3, %dx
  out %al, %dx

  /* LBA (15:8) */
  shr $8, %eax
  mov $0x01f4, %dx
  out %al, %dx

  /* LBA (23:16) */
  shr $8, %eax
  mov $0x01f5, %dx
  out %al, %dx

  /* LBA (27:24) */
  shr $8, %eax
  and $0x0f, %al

  /*
   * The fifth and seventh bit are obsolete, just ignore it and set to 1, keep
   * the fourth bit with 0 so read from the primary disk and set the sixth bit
   * to 1, means we use LBA addressing method. */
  or $0xe0, %al
  mov $0x01f6, %dx
  out %al, %dx

  /* emit read command */
  mov $0x01f7, %dx
  mov $0x20, %al
  out %al, %dx

/* check disk status */

.wait_disk:
  nop         /* add a little delay to reduce disturb disk working */
  in %dx, %al /* get disk status */

  /*
   * Disk Controller is ready to perform data transfer when the DRQ bit is set
   * to 1 and the BSY bit is set to 0. Otherwise we keeping waiting until it is
   * ready. */
  and $0x88, %al
  cmp $0x08, %al
  jnz .wait_disk

  /* read data from disk */

  /*
   * Note: Each sector have 512 bytes and read 1 word every time) so we need to
   * read SECTORS*512/2 (SECTORS*256) times for each. */
  shl $8, %cx
  mov $0x01f0, %dx
.read_it:
  in %dx, %ax
  mov %ax, (%bx)
  add $2, %bx
  /* TODO: 64KB boundary detection */
  loop .read_it
  ret

  .fill 510-(.-_start), 1, 0
boot_flag:
  .word 0xAA55
