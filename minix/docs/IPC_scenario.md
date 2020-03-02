USER_PROCESS            MM                     KERNEL_TRAPS                             SYS_TASK                  
lib.a/fork()            
  lib.a/callx(MM,id)    
    lib.a/sendrec       
      INT SYSVEC ------------------------------>
                                                mpx88.s/s_call                          
                                                  call proc.c/sys_call(BOTH,id,MM,m_ptr)
                                                    proc.c/minisend()                   
                                                      cp_mess(m_ptr,MM->p_messbuf)      
                                                      ready(MM);return OK               
                                                    proc.c/mini_rec()                   
                                                      id->p_getfrom = MM;               
                                                      id->p_flags |= RECEIVING          
                                                      proc.c/unready(id)                
                                                        rdy_head[2]=id->p_nextready     
                                                        proc.c/pick_proc(id)            
                                                          proc_ptr=rdy_head[1] (=> MM)  
                                                      inform(MM_PROC_NR);return OK      
                                                  jmp restart                           
                                                mpx88.s/restart                         
                                                  mov sp,_proc_ptr                      
                                                  // restore this process => MM         
                                                  push cs;push pc                       
                        <-----------------------  iret                                  
                        mm/main.c/main()        
                          get_work()            
                            receive(ANY, &mm_in)
                          who=pid               
                          mm_call=FORK          
                          forkexit.c/do_fork    
                            lib.a/sys_fork(pid) 
                              lib.a/callm1(SYSTASK,SYS_FORK)
                              INT SYSVEC ------>
                                                mpx88.s/s_call ...                      
                                                  send:ready(SYSTASK);return OK         
                                                  recv:unready(MM)                      
                                                    proc_ptr=rdy_head[0] (=> SYSTASK)   
                                                mpx88.s/restart                         
                                                  // restore this process => SYSTASK    
                                                  iret--------------------------------->
                                                                                        receive(ANY, &m)            
                                                                                        switch (m.m_type)           
                                                                                        case SYS_FORK : do_fork()   
                                                                                          system.c/do_fork          
                                                                                          //copy parent proc struct 
                                                                                          return OK;                
                                                                                        send(MM,OK)                 
                                                                                          INT SYSVEC                
                                                <---------------------------------------
                                                mpx88.s/s_call                          
                                                  send:ready(MM);                       
                                                mpx88.s/restart : iret                  
                                                --------------------------------------->receive(ANY, &m)            
                                                <---------------------------------------
                                                mpx88.s/s_call unready(SYS_TASK)        
                                                  proc_ptr=rdy_head[1] (=> MM)          
                                                iret
                          <---------------------
                          reply(pid,result)     
                            send(pid,&mm_out)   
                          --------------------->mpx88.s/s_call
                                                  send:ready(pid)
                          <---------------------
                          get_work:receive(ANY) 
                          --------------------->recv:unready(MM)                        
                                                  proc_ptr=rdy_head[2] => pid           
                                                mpx88.s/restart: iret                   
<-----------------------------------------------
    return(M.m_type)      