# Mike OS 

MikeOS is a well [documented](/doc/handbook-user.html) 
minimal x86 compatible 16-bits operating system.

## Main Features 

- [bootloader](mikeOS/#bootloader) simple to understand
- shell [CLI](mikeOS/#command-line-shell) 
    for [syscalls](doc/handbook-appdev-asm.html#syscallintro)
    and launching bin/bas files 
- BASIC interpreter
- BIOS interrupt calls for keyboard input/screen output 
- [IO port availability](test) for sound and serial port
- [file system](mikeOS/#loading-from-disk) read into the floppy disk *mikeos.flp*
- segment free [memory layout](doc/handbook-sysdev.html#memorymap) :
    - $0000h - 5FFFh$ : kernel
    - $6000h - 7FFFh$ : kernel disk operation buffer
    - $8000h - FFFFh$ : user programs and RAM memory


## Missing OS fundamentals

It is actually more of a program loader than an OS since major aspects are missing.

- scheduler, process managmer
- memory manager
- interprocess communication
- interrupts
- io port manager

## Building
`./build-linux.sh`  

```
echo ">>> Assembling ..."
nasm bootload.asm -o bootload.bin
nasm kernel.asm -o kernel.bin
nasm programs/*.asm
echo ">>> Creating new MikeOS floppy image..."
mkdosfs -C disk/images/mikeos.flp 1440
echo ">>> Adding bootloader to floppy image..."
dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/mikeos.flp
echo ">>> Copying MikeOS kernel and programs..."
mkdir tmp-loop && mount -o loop -t vfat disk_images/mikeos.flp tmp-loop
cp source/kernel.bin tmp-loop
cp programs/*.bin programs/*.bas programs/sample.pcx tmp-loop
echo ">>> Unmounting loopback floppy..."
umount tmp-loop
echo ">>> Creating CD-ROM ISO image..."
mkisofs -quiet -V 'MIKEOS' -input-charset iso8859-1 -o disk_images/mikeos.iso -b mikeos.flp disk_images/
```