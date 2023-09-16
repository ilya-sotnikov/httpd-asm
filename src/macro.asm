%macro DEFINE_STRING 2
%1 db %2
%1_len equ $-%1
%endmacro

%macro PRINT 1
        [section .data]
%%msg db %1
%%msg_len equ $ - %%msg
        __?SECT?__
        mov rax, SYSCALL_WRITE
        mov rdi, STDOUT
        mov rsi, %%msg
        mov rdx, %%msg_len
        syscall
%endmacro
