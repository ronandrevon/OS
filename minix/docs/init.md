# The init process 

This process is the father (mother) of all MINIX user processes. 
When MINIX comes up, this is process 2.
It executes the /etc/rc shell file and 
then reads the /ect/ttys file to find out which terminals need a login process.

```
// init.c : first user space process, linked with libc.a
main()
{
  /* Carry out /etc/rc. */
  int tty, k, status, ttynr, ct, i;
  sync();     /* force buffers out onto RAM disk */ 
  if (fork()) {
    /* Parent, just wait. */
    wait(&k);
  } else {
  /* Child exec's the shell to do the work. */
  if (open("/etc/rc", 0) < 0) exit(-1);
  open("/dev/tty0", 1); /* std output */
  open("/dev/tty0", 2); /* std error */
  execn("/bin/sh");     /*start the shell program*/
  }
  /* Read the /etc/ttys file and fork off login processes. */
  tty = open("/etc/ttys", 0)
  while(getline(line)){
    ttynr = line[2] - '0';
    startup(ttynr);
  }
  close(tty);
  
  /* All the children have been forked off.  Wait for someone to terminate.*/
  // First ignore all signals.
  for (i = 1; i <= NR_SIGS; i++) signal(i, SIG_IGN);
  while (1) {
    k = wait(&status);
    pidct--;   
    /* Search to see which line terminated. */
    for (i = 0; i < PIDSLOTS; i++)
      if (pid[i] == k) startup(i);
  }
}
```