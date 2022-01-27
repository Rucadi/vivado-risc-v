OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
  error_mem (rw)   : ORIGIN = 0x00003000, LENGTH = 0x00001000
  maskrom_mem (rx) : ORIGIN = 0x50000000, LENGTH = 0x80000000
  memory_mem (rwx) : ORIGIN = 0x80000000, LENGTH = 0x00002000
}

PHDRS {
  text PT_LOAD;
}

SECTIONS {
  .text 0x50000000 : {
    *(.text.start)
    *(.rodata.dtb)
    *(.text.unlikely .text.unlikely.*)
    *(.text .text.* .gnu.linkonce.t.*)
    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.srodata .srodata.*)
  } >maskrom_mem  :text

  .data (INFO) : {
    /* This section must be empty */
    *(.data .data.* .gnu.linkonce.d.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    *(.tohost)
  }

  .bss 0x80000000 (NOLOAD) : {
    . += 8; /* Trap vector */
    PROVIDE(_fbss = .);
    PROVIDE(__global_pointer$ = . + 0x7C0);
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.bss .bss.* .gnu.linkonce.b.*)
    . = ALIGN(8);
    PROVIDE(_ebss = .);
  } >memory_mem

  .note (INFO) : {
    *(.note .note.*)
    *(.eh_frame)
  }
}
