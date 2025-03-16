AS = i386-elf-as
LD = i386-elf-ld

boot/mbr: boot/mbr.o
	$(LD) -T boot/link.ld -o $@ $<

boot/mbr.o: boot/mbr.s
	$(AS) -o $@ $<

clean:
	rm -rf boot/mbr
	rm -rf boot/*.o
