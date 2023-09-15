%include "constants.asm"
%include "macro.asm"

%macro ASSERT_EQUAL 2-*
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

%macro ASSERT_STR_EQUAL 2-*
        mov rdi, %1
        mov rsi, %2
        mov rdx, %2_len
        call str_is_equal
        cmp rax, 1
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
        extern htons
        extern str_is_equal
        extern mem_copy

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

        mov rdi, index_str
        mov rsi, index_str_len
        mov rdx, "/"
        CALL_DO str_find_char, {ASSERT_EQUAL rax, 15}

        mov rdi, index_str
        mov rsi, index_str_len
        mov rdx, "?"
        CALL_DO str_find_char, {ASSERT_EQUAL rax, -1}

        mov rdi, empty_str
        mov rsi, empty_str_len
        mov rdx, " "
        CALL_DO str_find_char, {ASSERT_EQUAL rax, -1}

        mov rdi, long_str
        mov rsi, long_str_len
        mov rdx, "?"
        CALL_DO str_find_char, {ASSERT_EQUAL rax, 1024 * 8}

        mov rdi, index_str
        mov rsi, test_str
        mov rdx, test_str_len
        CALL_DO str_is_equal, {ASSERT_EQUAL rax, 1}

        mov rdi, index_str
        mov rsi, long_str
        mov rdx, index_str_len
        CALL_DO str_is_equal, {ASSERT_EQUAL rax, 0}

        mov rdi, index_str
        mov rsi, empty_str
        mov rdx, empty_str_len
        CALL_DO str_is_equal, {ASSERT_EQUAL rax, 0}

        sub rsp, 1024*16 + 1

        mov rdi, rsp
        mov rsi, index_str
        mov rdx, index_str_len
        CALL_DO mem_copy, {ASSERT_EQUAL rax, index_str_len}
        ASSERT_STR_EQUAL rsp, index_str

        mov rdi, rsp
        mov rsi, long_str
        mov rdx, long_str_len
        CALL_DO mem_copy, {ASSERT_EQUAL rax, long_str_len}

        add rsp, 1024*16 + 1

        mov rdi, 0x1234
        CALL_DO htons, {ASSERT_EQUAL rax, 0x3412}
        mov rdi, 0x0000
        CALL_DO htons, {ASSERT_EQUAL rax, 0x0000}

        PRINT `success\n`

        mov rax, SYSCALL_EXIT
        xor edi, edi
        syscall

        section .data

DEFINE_STRING empty_str, ""
DEFINE_STRING index_str, "testing string /index.html"
DEFINE_STRING test_str, "test"

long_str times 1024 * 8 db "x"
db "?"
times 1024 * 8 db "x"
long_str_len equ $ - long_str
