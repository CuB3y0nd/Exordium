AS = i386-elf-as
LD = i386-elf-ld
DD = dd bs=512 count=1 conv=notrunc
IMG = exordium.img
IMG_SIZE = 60M

all: boot/mbr boot/loader create_img write_mbr write_loader

boot/mbr.o: boot/mbr.s
	$(AS) -I boot -o $@ $<

boot/loader.o: boot/loader.s
	$(AS) -o $@ $<

boot/mbr: boot/mbr.o
	$(LD) -Ttext 0x7c00 --oformat binary -o $@ $<

boot/loader: boot/loader.o
	$(LD) --oformat binary -o $@ $<

create_img:
	qemu-img create -f raw $(IMG) $(IMG_SIZE)

write_mbr: boot/mbr
	$(DD) if=$< of=$(IMG)

write_loader: boot/loader
	$(DD) if=$< of=$(IMG) seek=2

clean:
	rm -rf boot/mbr boot/loader
	rm -rf boot/*.o
	rm -f $(IMG)
