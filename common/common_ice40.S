# Emulate the behavior of basic ecalls for I/O board
#   Calls for 0x150 - 0x156 at https://github.com/digital-logic-and-computer-design/vscode-riscv-venus-2
.text
.globl ecall_proxy
ecall_proxy:
  addi sp,sp, -16
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw s3, 12(sp)

  # li s0, 0x8000  # no lui version
  li s0, 0x8
  slli s0, s0, 12

  li s1, 0x150
  beq a0,s1, ecall_proxy_writeleds
  li s1, 0x151
  beq a0,s1, ecall_proxy_readleds
  li s1, 0x152
  beq a0,s1, ecall_proxy_write_right_7segs
  li s1, 0x153
  beq a0,s1,ecall_proxy_read_right_7segs
  li s1, 0x154
  beq a0,s1, ecall_proxy_write_left_7segs
  li s1, 0x155
  beq a0,s1,ecall_proxy_read_left_7segs
  li s1, 0x156
  beq a0,s1,ecall_proxy_buttons

ecall_proxy_writeleds:
  sw a1, 8(s0)
  j ecall_proxy_end

ecall_proxy_write_right_7segs:
  sw a1, 0(s0)
  j ecall_proxy_end

ecall_proxy_write_left_7segs:
  sw a1, 4(s0)
  j ecall_proxy_end

ecall_proxy_buttons:
  lw a0, 12(s0)
  j ecall_proxy_end

ecall_proxy_readleds:
  lw a0, 8(s0)
  j ecall_proxy_end

ecall_proxy_read_right_7segs:
  lw a0, 0(s0)
  j ecall_proxy_end

ecall_proxy_read_left_7segs:
  lw a0, 4(s0)

ecall_proxy_end:
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw s3, 12(sp)
  addi sp,sp,16
  ret
