# Minix files

## Kernel
type | Description |
-----|---          |
**Constants,structs**
type.h     | structs sig_info; pc_psw={int (*pc)() program_counter, phys_clicks cs; unsigned psw} 
glo.h      | globals cur_proc,prev_proc,int_mess, t_stack[] k_stack
proc.h     | process table proc; process pointers proc_ptr,bill_ptr,rdy_head[NQ],rdy_tail[NQ]; task_mess; busy_map
const.h    | constants NR_REGS,INIT_SP,MEM_BYTES,CLOCK_VECTOR, INT,TASK_Q 1, SERVER_Q 2, USER_Q 3, TASK_STACK_BYTE
dmp.c      | dumping routines for debugging
table.c    | pointers tasks : task[NR_TASKS+INIT_NR+1]={printer_task,tty_task,winchester_task,floppy_task,mem_task,clock_task,sys_task,0,0,0,0} 
**main and process managment**
main.c          | main(), panic(), trap(),unexpected_int(),div_trap(), PRIVATE : set_vec()
proc.c          | process management => pick_proc(),sched(),interrupt(task, m_ptr),ready(rp),unready(rp),sys_call(function, caller, src_dest, m_ptr),int mini_send(caller, dest, m_ptr)
MINIX/klib88.s  | _phys_copy,_cp_mess,_port_out,_port_in,_portw_out,_portw_in,_lock,_unlock,_restore,_build_sig,_get_chrome,_vid_copy,_get_byte,_reboot,_wreboot,_exit,_vec_table
MINIX/mpx88.s   | _restart,_s_call,_tty_int,_lpr_int,_disk_int,_wini_int,_clock_int,_surprise,_trp,_divide,_sizes
**process tasks**
system.c  | sys_task(), cause_sig(),inform(),umap(rp,seg,vir_addr,bytes)
clock.c   | clock_task()
tty.c     | tty_task() = terminal , keyboard(), putc(c)
printer.c | printer_task(), pr_char()
memory.c  | mem_task()=disk driver,do_mem(m_ptr)=read/write,do_setup(m_ptr)
floppy.c  | floppy_task()
wini.cx   | winchester_task() = hard disk,same as t_wini.c, 539 at_wini.c for at_pc


## Headers
file      | description |
----------|----
signal.h  | NR_SIGS, SIGHUP,SIGINT,SIGQUIT,..., STACK_FAULT
stat.h    | stat struct; common definitions file_type,dir, permissions,
sgtty.h   | data structure for IOCTL sgttyb,tchars; tty #defines 
callnr.h  | NCALLS 69 call numbers : EXIT 1, FORK 2, READ 3, .. EXEC 59, TASK_REPLY 68
error.h   | error codes 
const.h   | constants NR_PROCS, NR_TASKS,NR_SEGS, T,D,S, MM,FS,INIT,LOW_USER WORD_SIZE
com.h     | #defines for messages, processes HARDWARE -1,SYSTASK -2,CLOCK -3,MEM -4,FLOPPY -5 ,WINCHESTER -6, TTY -7 ,PRINTER -8
type.h    | macros; types  vir_clicks, blocks, ;structs mem_map, message,mess_i, copy_info
sys       | posix headers


## Tools
file      | description |
----------|----         |
bootblock.s   | boot loader program 
fsck.c        | file system check before starting MINIX, uses low level ftsck1
fsck1.s       | exit,putc,getc,diskio   LOCAL : print,dmaoverr,ok,csv,cret,_prt
diskfix.s     | usage,done,next,again => Dos partitions on a winchester to minix
build.c       | build an image to burn/flash on diskette/floppy from compiled OS
