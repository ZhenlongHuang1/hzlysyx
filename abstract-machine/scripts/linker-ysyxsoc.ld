ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
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
    _data_vma_end = .;
  } > sram AT> flash : data
  _data_lma_start = LOADADDR(.data);
  .bss(NOLOAD) : ALIGN(4){
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > sram AT> flash : data
  _heap_start = ALIGN(4);
  _heap_end = ORIGIN(sram) + 0x1000;

  _stack_top = _heap_end;
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
