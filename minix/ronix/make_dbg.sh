#! /bin/bash
#https://stackoverflow.com/questions/32955887/how-to-disassemble-16-bit-x86-boot-sector-code-in-gdb-with-x-i-pc-it-gets-tr


gdb=0;if [ $# -eq 1 ];then gdb=$1;fi; echo $gdb

echo 'assembling bootblok'
rm disk_images/* obj/*
nasm -f elf32 -g3 -F dwarf source/bootblok.asm -o obj/bootblok.o
nasm -O0 -w+orphan-labels -f bin source/bootblok.asm -o disk_images/bootblok.img
ld -Ttext=0x7c00 -melf_i386 obj/bootblok.o -o obj/bootblok.elf
#ld -Ttext=0x0000 -melf_i386 obj/bootblok.o -o obj/bootblok_.elf

echo 'creating object and image'
#objcopy -O binary obj/bootblok_.elf disk_images/bootblok.img

echo 'running in debug mode '

if [ $gdb -eq 1 ];then
  qemu-system-i386 -hda disk_images/bootblok.img -S -s &
  gdb obj/bootblok.elf \
          -ex 'target remote localhost:1234' \
          -ex 'set architecture i8086' \
          -ex 'break mov_bootblok' \
          -ex 'continue' \
          -ex 'break bootblok.asm:13' \
  else
    qemu-system-i386 -hda disk_images/bootblok.img
fi
