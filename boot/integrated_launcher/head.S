#define MIP_MSIP (1 << 3)

.section .text.start, "ax", @progbits
.globl _start
_hang:
  li sp, 0xA0000000
  csrr a0, mhartid
  li s0, 0x80000000
  beqz a0, main
_hartx_loop:
  # write mtvec
  csrw mtvec, s0
  # enable software interrupt
  csrwi mie, MIP_MSIP
  wfi
  # only start if interrupt request is set
  csrr a2, mip
  andi a2, a2, MIP_MSIP
  beqz a2, _hartx_loop
  # jump to code in RAM
  ecall
  j _hartx_loop