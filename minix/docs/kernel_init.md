# MINIX kernel


The main of the kernel is the starting point of the minix kernel 
after execution of the [bootstrap](/bootstrap), fsck programs and 
the [minix kernel assembler sequence](/bootstrap#minix-kernel-entry-point).

## Initialization 

The main sets up the process table before the 
[tasks initialization](/#kernel-initialization-sequence).
```
/* main.c */
#define BASE            1536 /* physical RAM address where MINIX starts */
#define CLICK_SHIFT		4 	 /* To get segment adresses */
main(){
	
	/* Fill the process table for mm,fs,init*/
	base_click = BASE >> CLICK_SHIFT;
	size = sizes[0] + sizes[1];					/* kernel text + data size in clicks */
	phys_clicks mm_base   = base_click + size;	/* place where MM starts (in clicks) */
	phys_clicks fs_base   = mm_base + size + sizes[2] + sizes[3];
	phys_clicks init_base = fs_base + size + sizes[4] + sizes[5];
	
	/*.text*/
	proc[0+NR_TASKS]->p_map[T].mem_phys = mm_base;
	proc[1+NR_TASKS]->p_map[T].mem_phys = fs_base;
	proc[2+NR_TASKS]->p_map[T].mem_phys = init_base;
	proc[0+NR_TASKS]->p_map[T].mem_len = sizes[2*0 + 2];
	proc[1+NR_TASKS]->p_map[T].mem_len = sizes[2*1 + 2];
	proc[2+NR_TASKS]->p_map[T].mem_len = sizes[2*2 + 2];	
	/*.data*/
	proc[0+NR_TASKS]->p_map[D].mem_phys = mm_base+sizes[2*0 + 2];
	proc[1+NR_TASKS]->p_map[D].mem_phys = fs_base+sizes[2*1 + 2];
	proc[2+NR_TASKS]->p_map[D].mem_phys = init_base+sizes[2*2 + 2];
	proc[0+NR_TASKS]->p_map[D].mem_len = sizes[2*0 + 3];
	proc[1+NR_TASKS]->p_map[D].mem_len = sizes[2*1 + 3];
	proc[2+NR_TASKS]->p_map[D].mem_len = sizes[2*2 + 3];		
	/*.stack*/
	proc[0+NR_TASKS]->p_map[D].mem_phys = mm_base+sizes[2*0 + 1]+sizes[2*0 + 3];
	proc[1+NR_TASKS]->p_map[D].mem_phys = fs_base+sizes[2*0 + 2]+sizes[2*1 + 3];
	proc[2+NR_TASKS]->p_map[D].mem_phys = init_base+sizes[2*0 + 3]+sizes[2*2 + 3];
	proc[0+NR_TASKS]->p_map[D].mem_vir = sizes[2*0 + 3];
	proc[1+NR_TASKS]->p_map[D].mem_vir = sizes[2*1 + 3];
	proc[2+NR_TASKS]->p_map[D].mem_vir = sizes[2*2 + 3];
```