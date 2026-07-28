ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}
SECTIONS {
  . = ORIGIN(flash);
  .text : {
    *(entry)
    *(.text*)
  } > flash AT> flash : text

  .rodata : ALIGN(4){
    *(.rodata*)
  } > flash AT> flash : text

  .data : ALIGN(4){
    _data_vma_start = .;
    *(.data*)
    *(.sdata*)
    *(.sdata2*)
    _data_vma_end = .;
  } > psram AT> flash : data
  _data_lma_start = LOADADDR(.data);
  .bss(NOLOAD) : ALIGN(4){
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > psram AT> flash : data
  _heap_start = ALIGN(4);
  _heap_end = ORIGIN(psram) + 0x200000;

  _stack_top = _heap_end;
  _stack_pointer = ORIGIN(psram) + LENGTH(psram);
}
