ENTRY(_start)
PHDRS { boot PT_LOAD; text PT_LOAD; data PT_LOAD; }
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}
SECTIONS {
  . = ORIGIN(flash);
  .boot : {
      *(entry)
      *(.text.bootloader*)
  } > flash AT> flash : boot

  .text : ALIGN(4){
    _text_vma_start = .;
    *(.text*)
  } > sram AT> flash : text

  .rodata : ALIGN(4){
    *(.rodata*)
    . = ALIGN(4);
    _text_vma_end = .;
  } > sram AT> flash : text
    _text_lma_start = LOADADDR(.text);

  .data : ALIGN(4){
    _data_vma_start = .;
    *(.data*)
    *(.sdata*)
    *(.sdata2*)
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
  _heap_end = ORIGIN(sram) + LENGTH(sram) - 0x400;

  _stack_top = _heap_end;
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
