/* Synthetic LINK_ONLY layout. No board-specific RAM/MMIO or initialized SP. */
ENTRY(raf_dec_q8_entry)
SECTIONS {
  . = 0x10000;
  .text : { *(.text*) }
  .rodata : { *(.rodata*) }
  .data : { *(.data*) }
  .bss (NOLOAD) : { *(.bss*) *(COMMON) }
}
