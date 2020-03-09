# Inter process communication

Some assembly code for inter-process communication.

## kernel call

kernel/mpx88.s :

```
_s_call:			      ; System calls are vectored here.
	call save		      ; save the machine state
	mov bp,_proc_ptr	; use bp to access sys call parameters
	push 2(bp)		    ; push(pointer to user message) (was bx)
	push (bp)		      ; push(src/dest) (was ax)
	push _cur_proc		; push caller
	push 4(bp)		    ; push(SEND/RECEIVE/BOTH) (was cx)
	call _sys_call		; sys_call(function, caller, src_dest, m_ptr)
	jmp _restart		  ; jump to code to restart proc/task running
```

## restart
```
_restart:			| This routine sets up and runs a proc or task.
	cmp _cur_proc,#IDLE	| restart user; if cur_proc = IDLE, go idle
	je idle			| no user is runnable, jump to idle routine
	cli			| disable interrupts
	mov sp,_proc_ptr	| return to user, fetch regs from proc table
	pop ax			| start restoring registers
	pop bx			| restore bx
	pop cx			| restore cx
	pop dx			| restore dx
	pop si			| restore si
	pop di			| restore di
	mov lds_low,bx		| lds_low contains bx
	mov bx,sp		| bx points to saved bp register
	mov bp,SPLIM-ROFF(bx)	| splimit = p_splimit
	mov splimit,bp		| ditto
	mov bp,dsreg-ROFF(bx)	| bp = ds
	mov lds_low+2,bp	| lds_low+2 contains ds
	pop bp			| restore bp
	pop es			| restore es
	mov sp,SP-ROFF(bx)	| restore sp
	mov ss,ssreg-ROFF(bx)	| restore ss using the value of ds
	push PSW-ROFF(bx)	| push psw
	push csreg-ROFF(bx)	| push cs
	push PC-ROFF(bx)	| push pc
	lds bx,lds_low		| restore ds and bx in one fell swoop
	iret			| return to user or task
```

## system call

lib/sendrec.s :

```
| send(), receive(), sendrec() all save bp, but destroy ax, bx, and cx.
.globl _send, _receive, _sendrec
_send:	mov cx,*SEND		| send(dest, ptr)
	jmp L0

_receive:
	mov cx,*RECEIVE		| receive(src, ptr)
	jmp L0

_sendrec:
	mov cx,*BOTH		| sendrec(srcdest, ptr)
	jmp L0

  L0:	push bp			| save bp
	mov bp,sp		| can't index off sp
	mov ax,4(bp)		| ax = dest-src
	mov bx,6(bp)		| bx = message pointer
	int SYSVEC		| trap to the kernel
	pop bp			| restore bp
	ret			| return
```
