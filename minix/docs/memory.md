# Memory layout 

The i8088 : 

- 16 bit architecture (2-byte word)
- 1 MB (2^20 addresses) of memory : 
    - 64K(=2^16) segments
    - 16(=2^4) bytes per segments
- addresses are 20-bit (ssssoh) wide : 
    - 16-bit segment address(ssssh)
    - 4-bit address offset(oh)
- 255 entries in interrupt vector table : 
    - 4-byte wide each as they give the sector of the interrupt routine
    - 0040h is the first available sector for instructions


## layout

chunk         | segment     | offset | val              | description
------ --- ---|-------------|--------|------------------|------------
**INTERRUPT** | **0000h**   |0       |divide            |address to divide interrupt routine 
              |             |4       |`s_call`          |address to software interrupt routine
              |    ---      |        |                  |other interrupt vectors
              | 0004h       |0       |                  |first non interrupt vector 
**KERNEL**    | **0060h=B** |0       |minix:jmp `main`  |first kernel instruction
*text*        |             |4       | `ker_ds`         |kernel data segment put by [patch-2](/build#patch-2)
              | `s_call`    |        |                  |software interrupt routine
              |  ---        |        |                  |Other interrupt routines
              | `main`      |        |                  |[kernel initialization](/kernel_init)
              | *proc.c*    |        |                  |[process manager](/kernel_proc)
              |`proc[0].p_reg[CS]` | |                  |printer task instructions
              |  ---        |        |                  |Other tasks instructions
              | libc.a      |        |                  |[unix system calls]()
*data*        | `ker_ds`    |        |`sizes[0:8]`      |txt and data sizes of kernel,mm,fs,init put by [patch-2](/build#patch-2)
              | `proc`      |        |`proc[0:8]`       |[process table](/proc) 
              | `&proc[NR_TASKS]`  | | ??               |mm+fs process addresses
              | `&proc[LOW_USER]`  | | ??               |init process address
              | `&proc[NR_PROCS]`  | | ??               |user process addresses
              | `&proc[NR_PROCS]`  | | ??               |user process addresses
*kernel stack*| `k_stack`   |        |                  |kernel stack segment
*tasks stacks*| `t_stack[0]`|        |                  |tasks stack segments
*kernel extra*|             |        |                  |
    **MM**    |`B+size[:1]` |        |                  |[memory manager]()
    **FS**    |`B+size[:3]` |        |                  |[file system manager]()
    **INIT**  |`B+size[:5]` |        |                  |[init process](/init)
    **USER**  |`sizes[:7]`  |        |                  |User space programs 