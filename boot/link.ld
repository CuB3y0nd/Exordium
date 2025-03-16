OUTPUT_FORMAT(binary)
ENTRY(_main)
SECTIONS
{
  /* The BIOS loads the code from the disk to this location. We must tell
   * that to the linker so that it can properly calculate the addresses of
   * the symbols we might jump to.
   */
  . = 0x7c00;
  .text :
  {
    _main = .;
    *(.text)
    /* Place the magic bytes at the end of the first 512 bytes sector. */
    . = 0x1FE;
    SHORT(0xAA55);
  }
}
