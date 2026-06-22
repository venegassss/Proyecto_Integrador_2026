global start
extern long_mode_start

section .text
bits 32
start:
    cli
    mov esp, stack_top

    ; Verificar magic number de Multiboot2
    cmp eax, 0x36d76289
    jne .no_multiboot

    ; Verificar CPUID
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_cpuid

    ; Verificar long mode
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode

    ; Configurar paginacion
    call setup_page_tables
    call enable_paging

    ; Cargar GDT y saltar a 64 bits
    lgdt [gdt64.pointer]
    jmp gdt64.code:long_mode_start

.no_multiboot:
.no_cpuid:
.no_long_mode:
    hlt

setup_page_tables:
    mov eax, pdpt
    or eax, 0b11
    mov [pml4], eax
    mov eax, pd
    or eax, 0b11
    mov [pdpt], eax
    mov ecx, 0
.map_pd:
    mov eax, 0x200000
    mul ecx
    or eax, 0b10000011
    mov [pd + ecx * 8], eax
    inc ecx
    cmp ecx, 512
    jne .map_pd
    ret

enable_paging:
    mov eax, pml4
    mov cr3, eax
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

section .rodata
gdt64:
    dq 0
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

section .bss
align 4096
pml4:  resb 4096
pdpt:  resb 4096
pd:    resb 4096
align 16
stack_bottom:
    resb 16384
stack_top:
