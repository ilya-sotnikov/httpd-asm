%include "constants.asm"
%include "macro.asm"

%macro ASSERT_EQUALS 2-*
        cmp %1, %2
        je %%ok

        [section .data]
%%fail_str db %str(failed: %3  %?? %1, %2), `\n`
%%fail_str_len equ $ - %%fail_str
        __?SECT?__

        mov rdi, %%fail_str
        mov rsi, %%fail_str_len
        call log_error_die
%%ok:
%endmacro

%macro CALL_DO 2
        call %1
        %2, %1
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

        section .text
        global _start
        extern str_find_char

log_error_die:
        mov rax, SYSCALL_WRITE
        mov rdx, rsi
        mov rsi, rdi
        mov rdi, STDERR
        syscall

        mov rax, SYSCALL_EXIT
        mov rdi, 1
        syscall

_start:
        PRINT `--------------------------------------\n`
        PRINT `testing starts...\n`
        PRINT `--------------------------------------\n`

        mov rdi, str_find_char_find
        mov rsi, str_find_char_find_len
        mov rdx, "/"
        CALL_DO str_find_char, {ASSERT_EQUALS rax, 15}

        PRINT `success\n`

        mov rax, SYSCALL_EXIT
        xor edi, edi
        syscall

        section .data

DEFINE_STRING str_find_char_find, "testing string /index.html"
