.globl _start
_start:
    # Initialize stack pointer
    # li sp, 0x1000
    li sp, 1
    slli sp, sp, 12

    # Call main
    jal main

    # li t0, 0x8000 # no lui version
    li t0, 0x8
    slli t0, t0,12

    # li t1, 0x5E3F5479 # dOnE
    li t1, 0x5E
    slli t1, t1, 8
    li t2, 0x3F
    add t1,t1,t2
    slli t1, t1, 8
    li t2, 0x54
    add t1,t1,t2
    slli t1, t1, 8
    li t2, 0x79
    add t1,t1,t2
    sw t1, 0(t0)  # Update LEDs: RGB on
done:
    j done
