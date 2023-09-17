%include "constants.asm"
%include "macro.asm"

        section .text
        extern server_start
        extern server_loop
        extern str_to_u32
        extern strlen

print_usage_die:
        PRINT `usage: httpd-asm [PORT]\n`

        mov eax, SYSCALL_EXIT
        mov edi, 1
        syscall

global _start
_start:
        cmp qword [rsp], 2
        jne print_usage_die

        lea rdi, [rsp + 16]
        mov rdi, [rdi]
        push rdi
        call strlen
        pop rdi
        mov esi, eax
        call str_to_u32
        mov edi, eax
        call server_start
        mov edi, eax
        call server_loop

        mov eax, SYSCALL_EXIT
        xor edi, edi
        syscall
        ret
