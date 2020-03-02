# Bootstrap sequence

When the PC is powered on, the **BIOS reads the first block(512byte) from the floppy disk into address 0x07C0** (standard convention).
This boot block contains the boot program.

*Loading is not trivial because the PC is unable to read a track into
memory across a 64K boundary, so the positioning of everything is critical.*

The [bootstrap program](#bootstrap-program) :

- **copies itself** to address 192K-512b (to get itself out of the way). 
- **loads the OS into memory** from the floppy. The number of sectors to load is determined by the build program which compiles the OS and put the result at address 504 of the boot program.
- **jumps indirectly** to [fsck](#file-system-check)(file system check program) whose address is given by the last two words in the boot block.
- **fsck jumps back** to the [Minix kernel entry point](#minix-kernel-entry-point)

Summary of the words patched into the boot block by the [build program](/build) :
```
504: number of sectors from the OS to load
506: DS value for fsck
508: PC value for fsck
510: CS value for fsck
```
## bootstrap program
```
LOADSEG = 0x0060         //here the boot block will start loading
BIOSSEG = 0x07C0         //here the boot block itself is loaded
BOOTSEG = 0x2FE0         //here it will copy itself 0x2FE00=192K-512b
DSKBASE = 120            //120 = 4 * 0x1E = ptr to disk parameters
/* The boot program first copies the boot block at BIOSEG into BOOTSEG*/
	mov     ax,BIOSSEG
	mov     ds,ax           //ds=0x07C0
	xor     si,si           //ds:si - source block to copy 
	mov     ax,BOOTSEG
	mov     es,ax
	xor     di,di           //es:di - destination to copy block
	mov     cx,#256         //words to move
	rep     movsw			//mov word(16 bits) until cx=256
	jmpi    start,BOOTSEG   //set cs to bootseg
start: 
	//check disk 
	jnb	load

//;Determine if this is a 1.2M diskette by trying to read sector 15
disksec  DW 	1		//; disk sector =1 512Bytes
tracksiz DW 	15		//; for 1.2M diskette
//; Load/read the operating system from diskette/HD.
load:
	call setreg 	// ax tells how many sectors have been read
	mov	bx,1		//; bx = number of next sector to read
	add	bx,2		//; diskette sector 1 goes at 1536 ("sector" 3)
	mov	ah,2		//; opcode for read
	int	13h			//; call the BIOS for a read
	mov	ax,disksec	//; increment disksector read
	cmp	ax,final    //; see if we are done 
	jb	load
//; Loading done.  Finish and jump to fsck	
	mov     dx,03F2h		//; kill the motor
	mov	bx,tracksiz			//; fsck expects # sectors/track in bx
	mov     ax,fsck_ds      //; set segment registers
	mov     ds,ax           //; when sep I&D ds != cs
	mov     es,ax           //; otherwise they are the same.
	mov     ss,ax           //; This gets patched by 'build'
	jmp     DWORD PTR cs:fsck_pc   //; call the booted program

/*The values are provided by build.c at those adress */	

ORG 504 //each are 2 bytes adresses 0xXXXX
final   = 504 //number of sectors to read to load the OS
fsck_ds = 506 //data segment adress for fsck routine 
fsck_pc = 508 //pc value for fsck routine
fsck_cs = 510 //code_segment adress for fsck routine
```

## file system check
```
/****************************************************************
fsck.c : file system checker
*****************************************************************/
// link command: ld fsck1.o fsck.o -l../lib/lib.a
#define STANDALONE		/* compile for the boot-diskette */
main(int argc,char **argv){
	for (;;) {	
		printf("\nHit key as follows:\n\n");
		printf("    =  start MINIX (root file system in drive 0)\n");
		printf("    m  make an (empty) file system (first insert blank, formatted diskette)\n");
		printf("\n# ");	
		c = getc();
		command = c & 0xFF;	
		switch (command) {
			case '=': return((c >> 8) & 0xFF);
		}
	}
	sync();
}
```


## Minix kernel entry point
```
/****************************************************************
/* Minix kernel entry point */
/****************************************************************/
Minix:					//; this is the entry point for the Minix	kernel.
	jmp short M0
	ORG 4
	ker_ds	DW  dgroup	//; this word will contain kernel's ds value
M0:	cli	
	mov ax,cs			//; set up segment registers	
	mov ds,ax			//; set up ds
	mov ax,cs:ker_ds	//; build	has loaded this	word with ds value
	mov ds,ax			//; ds now contains proper value
	mov sp,offset dgroup:k_stack//; set sp to point to the top
	add sp,K_STACK_BYTES		//; kernel stack
	call main					// jump to main.c
```