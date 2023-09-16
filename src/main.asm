%include "constants.asm"
%include "macro.asm"

        section .text
        extern server_start
        extern server_loop
        extern str_to_unsigned
        extern strlen

print_usage_die:
        PRINT `usage: httpd-asm [PORT]\n`

        mov rax, SYSCALL_EXIT
        mov rdi, 1
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
        mov rsi, rax
        call str_to_unsigned
        mov rdi, rax
        call server_start
        mov rdi, rax
        call server_loop

        mov rax, SYSCALL_EXIT
        xor edi, edi
        syscall
        ret
