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
        PRINT `usage: httpd-asm [THREADS_CNT >= 1] [PORT]\n`

        mov eax, SYSCALL_EXIT
        mov edi, 1
        syscall

; arg1 const char* arg_null_terminated
; ret  uint32_t arg
; ret  bool success
arg_to_u32:
        push rdi
        call strlen
        pop rdi
        mov esi, eax
        call str_to_u32
        ret

global _start
_start:
        cmp qword [rsp], 3
        jne print_usage_die

        push r12
        push r13

        mov r12, qword [rsp + 16 + 16]   ; threads_cnt
        mov r13, qword [rsp + 16 + 24]   ; port

        mov rdi, r13
        call arg_to_u32
        test edx, edx
        jz print_usage_die
        mov edi, eax
        call server_start
        mov r13, rax                     ; server_fd

        mov rdi, r12
        call arg_to_u32
        test edx, edx
        jz print_usage_die

        mov r12d, eax
        cmp r12d, 1
        je .main_thread
        jl print_usage_die
        sub r12d, 1

.thread_create_loop:
        mov rdi, server_loop
        mov rsi, r13
        call thread_create
        sub r12d, 1
        jnz .thread_create_loop
.main_thread:
        mov rdi, r13
        call server_loop

        pop r13
        pop r12

        mov eax, SYSCALL_EXIT_GROUP
        xor edi, edi
        syscall
        ret
