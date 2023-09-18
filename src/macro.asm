%macro DEFINE_STRING 2
%1 db %2
%1_len equ $-%1
%endmacro

%macro SYSCALL_CHECK_ERROR_DIE 1
        test rax, rax
        jge %%ok
        cmp rax, -4095
        jl %%ok

        [section .data]
%%msg db %1
%%msg_len equ $ - %%msg
        __?SECT?__

        mov edi, eax
        neg edi                     ; 0 - errno in rax after syscall
        mov rsi, %%msg
        mov edx, %%msg_len
        jmp exit_error_msg
%%ok:
%endmacro

%macro PRINT 1
        [section .data]
%%msg db %1
%%msg_len equ $ - %%msg
        __?SECT?__
        mov eax, SYSCALL_WRITE
        mov edi, STDOUT
        mov rsi, %%msg
        mov edx, %%msg_len
        syscall
%endmacro
