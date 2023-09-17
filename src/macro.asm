%macro DEFINE_STRING 2
%1 db %2
%1_len equ $-%1
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
