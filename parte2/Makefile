all: kernel.iso

kernel.bin: src/header.asm src/main.asm src/long_mode.asm src/kernel.c
	nasm -f elf64 src/header.asm -o header.o
	nasm -f elf64 src/main.asm -o main.o
	nasm -f elf64 src/long_mode.asm -o long.o
	gcc -m64 -ffreestanding -O2 -Wall -c src/kernel.c -o kernel.o
	ld -m elf_x86_64 -n -o kernel.bin -T linker.ld header.o main.o long.o kernel.o

kernel.iso: kernel.bin
	mkdir -p iso/boot/grub
	cp kernel.bin iso/boot/kernel.bin
	cp grub/grub.cfg iso/boot/grub/grub.cfg
	grub-mkrescue /usr/lib/grub/i386-pc -o kernel.iso iso

run:
	qemu-system-x86_64 -cdrom kernel.iso

clean:
	rm -rf *.o *.bin *.iso iso
