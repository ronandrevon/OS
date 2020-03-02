# Building the image

The image is built using command : `make image` 
which compiles the full OS and copies it onto a diskette throught 
the [build program](/build).


# Power up sequence

At power up the first sector of the diskette is loaded into memory.
This sector contains the boostrap program which starts running.

1. The [bootstrap](/bootstrap) program loads the kernel to memory and start running the kernel.
1. The [kernel](/kernel_init) initalizes [tasks](#kernel-initialization-sequence) 
    *system,clock,tty(keyboard),printer,memory,floppy,wini* 
    until it starts running the init process.
1. The [init](/init) process initializes tty(teletype terminals) and bash to allow for login and further fork processes.


## kernel initialization sequence

![](figures/ker_init_sequence.png)

<details>
<summary>sequence diagram</summary>
    Sequence diagram of the kernel initialization stage
</details>
