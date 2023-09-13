%include "constants.asm"

        section .text
        extern server_start
        extern server_loop

global _start
_start:
        call server_start
        mov rdi, rax
        call server_loop

        mov rax, SYSCALL_EXIT
        xor edi, edi
        syscall
        ret
