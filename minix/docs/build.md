# Building the image

The image is built using command : `make image` 

which

- compiles build.c, bootblok.s, the kernel,mm,fs and init programs as 
    well as the file system check program.
- unmounts the floppy disk /dev/fd0 to allow writing into it
- Runs the build program to write into floppy disk image *boot.iso* which will get loaded at [boot](/bootstrap). 

The [build program](#the-build-program) is executed as : ` build bootblok kernel mm fs init fsck /dev/fd0 `

The bootblok file is copied at sector 0 (512 bytes) of the boot diskette.
The operating system is copied directly after it.
The *kernel, mm, fs, init, and fsck* are each padded out to a multiple of 16 bytes
(which corresponds to the i8088 segments) and then concatenated into a 
single file beginning 512 bytes into this file (sector 1) so that the first byte 
of sector 1 contains executable code for the kernel.
```
bootblok: the diskette boot program     sector 0
kernel:   the operating system kernel   sector 1
mm:       the memory manager
fs:       the file system
init:     the system initializer
fsck:     the file system checker
```

After the boot image has been built, build goes back and makes several
patches to the image file or diskette:

- [patch 1](#patch-1) : Sets the last 4 words of the boot block
- [patch 2](#patch-2) Writes a table into the first 8 words of the kernel's data space.
    It has 4 entries, the cs and ds values for each program
    The kernel needs this information to run mm, fs, and init.
    Writes the kernel's DS value into address 4 of the kernel's TEXT segment, so the kernel can set itself up.
- [patch 3](#patch-3) The origin and sizes of the init program are patched into bytes 4-9
	of the file system data space. The file system needs this
	information, and expects to find it here.

## The build program

```
// build.c : build os and puts into boot diskette
#define PROG_ORG 	1536   /* where does kernel begin in abs mem */
#define DS_OFFSET 	4L     /* position of DS written in kernel text seg */
#define SECTOR_SIZE 512
#define CLICK_SHIFT 4
long cum_size,all_size;
main(argc, argv){
	char *outfile = argv[7]; /* output file */
	FILE *image = fopen(outfile,'w')
	copy1(argv[1]);								/* boot */
	for (i = 0; i < 5; i++) copy2(i, argv[i+2]);/* kernel + mm + fs + init + fsck = 5 */
	printf("Operating system size  %29D     %5X\n", cum_size, cum_size);
	printf("\nTotal size including fsck is %D.\n", all_size);
	if (cum_size % 16 != 0) pexit("MINIX is not multiple of 16 bytes", "");
	/*patches */
	patch1(all_size);
	patch2();
	patch3();			
}
```
## patch 1

write in the image the size of kernel to load at boot and fsck info : ds,cs,ip*/

```
patch1(all_size){
	unsigned short cs,ds,ubuf[SECTOR_SIZE/2],nb_sectors;
	long fsck_org = PROG_ORG + cum_size;       		 /* where does fsck begin */
	cs = fsck_org >> CLICK_SHIFT;					 // segment address in clicks (since segments are 16 bytes each)
	ds = cs + (sizes[FSCK].text_size >> CLICK_SHIFT);
	
	nb_sectors = (unsigned) (all_size / 512L);
	read_block(0, ubuf); /* read in boot block */
	ubuf[(SECTOR_SIZE/2) - 4] = nb_sectors + 1;		// number of sectors to write
	ubuf[(SECTOR_SIZE/2) - 3] = ds;					// ds,ip,cs for fsck
	ubuf[(SECTOR_SIZE/2) - 2] = ip;
	ubuf[(SECTOR_SIZE/2) - 1] = cs;
	write_block(0, ubuf);/* write to image file*/
}
```

## patch 2

write in image file kernel the sizes info about the kernel,mm,fs,init 
written in the first 8 words of the kernel DATA space(2 words for each)
  The first word of each set is the text size in clicks
  The second is the data+bss size in clicks
In addition, the DS value the kernel is to use is computed here, and loaded
at location 4 in the kernel's TEXT space.
```
#define DS_OFFSET 4
patch2()
{
	/* write kernel,mm,fs,init sizes in kernel data space */
	data_offset = 512L + (long)sizes[KERN].text_size;    /* start of kernel data */
	get_byte(data_offset+1L) << 8) + get_byte(data_offset);
	for (int i = 0; i < PROGRAMS - 1; i++){
		text_clicks = t >> sizes[i].text_size >> CLICK_SHIFT;
		data_clicks = (sizes[i].data_size + sizes[i].bss_size) >> CLICK_SHIFT;
		put_byte(data_offset + 4*i + 0L, (text_clicks));
		put_byte(data_offset + 4*i + 2L, (data_clicks));
	}
	/* Now write the DS value into word 4 of the kernel text space. */
	ds = PROG_ORG+sizes[KERN].text_size >> CLICK_SHIFT;
	put_byte(512L + DS_OFFSET, ds & 0377);
}
```

## patch 3
Write the origin, text and data sizes of the init program in FS's data
 space.  The file system expects to find these 3 words there.
```
patch3()
{	
	long init_org = PROG_ORG;	
	init_org += sizes[KERN].text_size+sizes[KERN].data_size+sizes[KERN].bss_size;;
	init_org += sizes[MM].text_size + sizes[MM].data_size + sizes[MM].bss_size;
	fs_org = init_org - PROG_ORG + 512L;   /* offset of fs-text into file */
	fs_org +=  (long) sizes[FS].text_size;		
	init_org += sizes[FS].text_size + sizes[FS].data_size + sizes[FS].bss_size;
	init_org  = init_org >> CLICK_SHIFT;
	

	unsigned short init_text_size = sizes[INIT].text_size;
	unsigned short init_data_size = sizes[INIT].data_size + sizes[INIT].bss_size;	
	fbase = fs_org;
	w0 = (unsigned short) init_org	;put_byte(fbase+4L,w0);
	w1 = init_text_size				;put_byte(fbase+6L,w1);
	w2 = init_data_size				;put_byte(fbase+8L,w2);
}
```