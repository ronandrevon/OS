# MikeOS


## bootloader

An extremely good [tuto](http://mikeos.sourceforge.net/write-your-own-os.html)
on building an image and running it on a virtual machine.
After loading the kernel at segment $2000h$ and setting up the file system,
the [bootloader](src/bootload/bootload.asm)
jumps to relative address $0000h$ :
```C
//bootload/bootload.asm
bootloader_start: //set up a 4K space above the 8K buffer and bootloader
  // ss=07C0h+544 (512(8K-buffer)+32(512b bootloader))
  // sp=4096      (4K stack which grows downward)
  // ds=07C0h
read_root_dir://load the root directory from the disk(14 sectors corresponding to 224 entries in the root directory)
  mov bx, buffer // es:bx = 07C0h:buffer
  mov ah, 2      //
  mov al, 14     //
  int 13h        // read(ah=2) the al=14 sectors and place them in the buffer   
search_dir://Search the sector for the kernel to load from floppy into ram     
  mov di, buffer //es:di
  mov si, kern_filename
  rep cmpsb
	je found_file_to_load
  add di, 32
found_file_to_load://Read the sectors into RAM
  mov di, buffer //es:di
  mov ah, 2			; int 13h params: read (FAT) sectors
  mov al, 9			; All 9 sectors of 1st FAT
  int 13h
read_fat_ok://Load the kernel into RAM
  //es=2000h
  mov ah, 2
  mov al, 1
  int 13h

end://Start to run the kernel
  jmp 2000h:0000h  //Jump to entry point of loaded kernel!
```

## kernel

The [kernel](src/kernel.asm) starts executing the code :
```C
/*kernel.asm*/
os_call_vectors :
    jmp os_main
os_main :
    mov ax,0; mov ss,ax; mov sp 0FFFFh                  ;/* set stack segment and pointer */
    mov ax,2000h;mov ds,ax;mov es,ax;mov fs,ax;mov gs,ax;/* All segment registers at origin */
    jmp option_screen
option_screen :
    mov ax,os_init_msg;
    mov bx,os_version_msg;
    mov cx,10011111b       ;/*White text on light blue background*/
    call os_draw_background;/*Draw*/
    call os_command_line
```
which then starts executing the [command line shell](src/features/cli.asm).

## command line shell

The shell prompts for [user input](#user-input) and analyzes the command :
```C
//features/cli.asm
os_command_line :
    call os_clear_screen
    mov si,version_text;call os_print_string
    mov si, help_text  ;call os_print_string
get_cmd :
    /*clear command buffer*/
    mov di,command  ;//command='0'*32
    mov cx,32       ;//init the counter
    rep stosb       ;//repeat 32 times stosb : put the byte string at di+count into ax
    /*prompt for input*/
    mov si,prompt;call os_print_string  ;//prompt='> '
    /*get command string from user*/
    mov ax,input;mov bx,64              ;//input='0'*64
    call os_input_string
    call os_print_newline
    /*tokenize and store cmd vargs into 'input'*/
    mov si,input; mov al,' ';call os_string_tokenize;// separate params from cmd
    mov si,input;mov di,command;call is_string_copy ;// copy cmd from 'input' to 'command'
    /*analyze command*/
    mov di,exit_string;call os_string_compare;jc near exit          ;//'EXIT' entered
    mov di,help_string;call os_string_compare;jc near print_help    ;//'HELP' entered
    ...
    mov si,command;add si,ax;sub si,4;
    mov di,bin_extension; call os_string_compare;jc bin_file        ;//'BIN' file ?
    mov di,bas_extension; call os_string_compare;jc bas_file        ;//'BAS' file ?
```
Once the command is analized it either executes a system call,
or [load](#loading-from-disk) a binary file *.bin* or basic file *.bas*
(into address $8000h=32768$) and executes it.
:

```C
/*features/cli.asm*/
bin_file :
    mov ax,command;mov bx, 0;mov cs,32768; call os_load_file
execute_bin :
    mov ax,bx,cx,dx,di 0    ;/*clear registers*/
    mov word si,[param_list];/*load params*/
    call 32768              ;/*call the external program which is where the program has been loaded*/
    jmp get_cmd
bas_file :
    mov ax,command;mov bx, 0;mov cs,32768;call os_load_file
    mov ax,32768;mov word si,[param_list]
    call os_run_basic
    jmp get_cmd
```

## user input

The user is often prompted for input via pressing keys
on the [keyboard](keyboard-key-pressed) :
```C
//features/screen.asm
os_input_string :
    pusha;cmp bx,0;je .done     ;//character count is zero?
    mov di,ax;                  ;//di=input
    dec bx;mov cx,bx            ;//max nb characters store in counter cx
.get_char :
    call os_wait_for_key        ;//result in ax
    cmp al,8;je .backspace      ;//erase previous if BACKSPACE
    cmp al,13;je .end_string    ;//ENTER key ends the prompt
    cmp al,32;jb .get_char;     ;//Only add printable ASCII >32
    cmp al,126;ja .get_char     ;//Only add printable ASCII <126
    stosb                       ;//add character al to di=input
    /*update display*/
    mov ah,0x0E;mov bh,0;pushbp;
    int 0x10h;                  //BIOS Teletype video Page 0
    pop bp;ret
    /*decrement loop back*/
    dec cx;jmp .get_char        ;//decrement counter loop back
```

## keyboard key pressed

keyboard strokes are obtained through the BIOS interrupt :
```C
//features/keyboard.asm
os_wait_for_key:
    mov ah, 0x11;int 0x16   ;//poll key press
    jnz .key_pressed        ;//jump if key was pressed
    hlt                     ;//wait for key press interrupt
    jmp os_wait_for_key
.key_pressed:
    mov ah, 0x10;int 0x16   ;//key pressed in al
    ret
```

## loading from disk

Reading from [disk](/src/disk.asm) can be used to load a file such as a binary :

```C
/*features/disk.asm*/
os_load_file:
    call os_string_uppercase
    call int_filename_convert

    mov [.filename_loc], ax     ;/* Store filename location */
    mov [.load_position], cx    ;/* And where to load the file!*/

    mov eax, 0                  ;/* Needed for some older BIOSes*/

    call disk_reset_floppy      ;/* In case floppy has been changed*/
    jnc .floppy_ok              ;/* Did the floppy reset OK?*/

    mov ax, .err_msg_floppy_reset;/* If not, bail out*/
    jmp os_fatal_error
.floppy_ok :
.read_root_dir :
    int 13h                     ;/*read sector*/
    jnc .search_root_dir
.search_root_dir :
.next_root_entry :
    mov si, [.filename_loc]     ;/* DS:SI = location of filename to load*/
    call os_string_compare
    jc .found_file_to_load
.found_file_to_load :
    mov di,disk_buffer
    mov ah,2;mov al,9;
    int 13h
    jnc .load_file_sector
.load_file_sector:
    jnc .calculate_next_cluster
.calculate_next_cluster:
    mov word [.cluster],ax          ;// read word
    cmp ax,0FF8h; jae .end          ;// end of file
    add word [.load_position], 512  ;// Increment load position
    jmp .load_file_sector           ;// Onto next sector!
.end
    mov bx,[.file_size];clc;ret
```
