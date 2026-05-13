MEMORY {
    program_memory : ORIGIN = 0x00000000, LENGTH = 2K
    data_memory    : ORIGIN = 0x00000000, LENGTH = 2K
}

SECTIONS {
    .text : {*(.text)} > program_memory

    /*the data memory should be after the program memory in the executable*/
    .data : {*(.data)} > data_memory AT > program_memory

    .bss  : {*(.bss) } > data_memory
}
