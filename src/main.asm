%include "constants.asm"
%include "config.asm"
%include "macro.asm"

        section .text
        extern server_start
        extern server_loop
        extern str_to_u32
        extern strlen
        extern thread_create

print_usage_die:
        PRINT `usage: httpd-asm [PORT]\n`

        mov eax, SYSCALL_EXIT
        mov edi, 1
        syscall

global _start
_start:
        cmp qword [rsp], 2
        jne print_usage_die

        mov r8, qword [rsp + 16]      ; port

        push r12
        push r13

        mov rdi, r8
        push rdi
        call strlen
        pop rdi
        mov esi, eax
        call str_to_u32
        mov edi, eax
        call server_start

        mov r12, rax
        lea r13d, [THREAD_COUNT - 1]

.thread_create_loop:
        mov rdi, server_loop
        mov rsi, r12
        call thread_create
        sub r13d, 1
        jnz .thread_create_loop

        mov rdi, r12
        call server_loop

        pop r13
        pop r12

        mov eax, SYSCALL_EXIT_GROUP
        xor edi, edi
        syscall
        ret
