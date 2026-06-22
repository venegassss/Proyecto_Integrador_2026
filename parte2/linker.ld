ENTRY(start)

SECTIONS {
    . = 1M;

    .boot ALIGN(4) :
    {
        KEEP(*(.multiboot_header))
    }

    .text ALIGN(4096) :
    {
        *(.text)
    }

    .rodata ALIGN(4096) :
    {
        *(.rodata)
    }

    .bss ALIGN(4096) :
    {
        *(COMMON)
        *(.bss)
    }
}
