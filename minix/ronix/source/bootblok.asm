BITS 16

;LOADSEG dw 0x0060         ;| here the boot block will start loading
;BIOSSEG dw 0x07C0         ;| here the boot block itself is loaded
;BOOTSEG dw 0x2FE0         ;| here it will copy itself (192K-512b)
;DSKBASE dw 120            ;| 120 = 4 * 0x1E = ptr to disk parameters
;ORG 07C0h
;copy bootblok from 0x07C0 to 0x2FE0
global _start
_start:
mov_bootblok:
	mov ax,07C0h			; where the boot block is loaded
	mov ds,ax						; ds=07C0h
	xor si,si         	; ds:si - original block(same as mov si,0)
	mov ax,2FE0h			; where it will copy itself (192K-512b)
	mov es,ax						; es=2FE0h
	xor di,di         	; es:di - new block(same as mov di,0)
	mov cx,256        ; 256 words=512 bytes to move
	rep	movsw					; repeat until count=0
; Jump to actual start routine at created block
	mov ah, 0Eh
	mov al, 41h
	jmp 2FE0h:start							; Jump to actual start cs:2FE0h,start

start:
	int 10h
	mov ax, cs		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 2FE0h		; Set data segment to where we're loaded
	mov ds, ax


	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine

	jmp $			; Jump here - infinite loop!


	text_string db 'This is my cool new OS!', 0


print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	ret


	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
