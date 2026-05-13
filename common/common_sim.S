.text

# Bridge to emulate the ecall (actually calls the ecall in the simulator)
.globl ecall_proxy
ecall_proxy:
    ecall
    jr ra

.globl ecall_proxy_test
ecall_proxy_test:
    ecall
    li t0, 0xBADBAD0
    li t1, 0xBADBAD1
    li t2, 0xBADBAD2
    li t3, 0xBADBAD3
    li t4, 0xBADBAD4
    li t5, 0xBADBAD5
    li t6, 0xBADBAD5

    jr ra
