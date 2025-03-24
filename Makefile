AS = nasm
DD = dd bs=512 conv=notrunc
IMG = exordium.img
IMG_SIZE = 60M

all: boot/mbr boot/loader create_img write_mbr write_loader

boot/mbr: boot/mbr.asm
	$(AS) -I boot -o $@ $<

boot/loader: boot/loader.asm
	$(AS) -I boot -o $@ $<

create_img:
	qemu-img create -f raw $(IMG) $(IMG_SIZE)

write_mbr: boot/mbr
	$(DD) if=$< of=$(IMG) count=1

write_loader: boot/loader
	$(DD) if=$< of=$(IMG) count=4 seek=2

clean:
	rm -rf boot/mbr boot/loader
	rm -f $(IMG)
