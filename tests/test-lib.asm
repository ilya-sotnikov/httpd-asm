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
        mov esi, %%fail_str_len
        call log_error_die
%%ok:
%endmacro

%macro ASSERT_STR_EQUAL 2-*
        mov rdi, %1
        mov rsi, %2
        mov edx, %2_len
        call mem_cmp
        cmp rax, 1
        je %%ok

        [section .data]
%%fail_str db %str(failed: %3  %?? %1, %2), `\n`
%%fail_str_len equ $ - %%fail_str
        __?SECT?__

        mov rdi, %%fail_str
        mov esi, %%fail_str_len
        call log_error_die
%%ok:
%endmacro

%macro CALL_DO 2
        call %1
        %2, %1
%endmacro

        section .text
        global _start
        extern mem_find_byte
        extern mem_find_byte_or
        extern htons
        extern mem_cmp
        extern mem_copy
        extern mem_set
        extern str_to_u32
        extern strlen

log_error_die:
        mov eax, SYSCALL_WRITE
        mov edx, esi
        mov rsi, rdi
        mov edi, STDERR
        syscall

        mov eax, SYSCALL_EXIT
        mov edi, 1
        syscall

_start:
        PRINT `--------------------------------------\n`
        PRINT `testing starts...\n`
        PRINT `--------------------------------------\n`

        mov rdi, test_str
        mov esi, test_str_len
        mov edx, "/"
        CALL_DO mem_find_byte, {ASSERT_EQUAL eax, 15}

        mov rdi, test_str
        mov esi, test_str_len
        mov edx, "*"
        CALL_DO mem_find_byte, {ASSERT_EQUAL eax, -1}

        mov rdi, empty_str
        mov esi, empty_str_len
        mov edx, " "
        CALL_DO mem_find_byte, {ASSERT_EQUAL eax, -1}

        mov rdi, long_str
        mov esi, long_str_len
        mov edx, "?"
        CALL_DO mem_find_byte, {ASSERT_EQUAL eax, 1024 * 8}

        mov rdi, test_str
        mov esi, test_str_len
        mov edx, "/"
        mov ecx, "?"
        CALL_DO mem_find_byte_or, {ASSERT_EQUAL eax, 15}

        mov rdi, index_str_space
        mov esi, index_str_space_len
        mov edx, " "
        mov ecx, "?"
        CALL_DO mem_find_byte_or, {ASSERT_EQUAL eax, 10}

        mov rdi, index_str_quest
        mov esi, index_str_quest_len
        mov edx, " "
        mov ecx, "?"
        CALL_DO mem_find_byte_or, {ASSERT_EQUAL eax, 10}

        mov rdi, test_str
        mov rsi, short_str
        mov edx, short_str_len
        CALL_DO mem_cmp, {ASSERT_EQUAL eax, 1}

        mov rdi, test_str
        mov rsi, long_str
        mov edx, test_str_len
        CALL_DO mem_cmp, {ASSERT_EQUAL eax, 0}

        mov rdi, test_str
        mov rsi, empty_str
        mov edx, empty_str_len
        CALL_DO mem_cmp, {ASSERT_EQUAL eax, 0}

        sub rsp, 1024*16 + 1

        mov rdi, rsp
        mov rsi, test_str
        mov edx, test_str_len
        CALL_DO mem_copy, {ASSERT_EQUAL eax, test_str_len}
        ASSERT_STR_EQUAL rsp, test_str

        mov rdi, rsp
        mov rsi, long_str
        mov edx, long_str_len
        CALL_DO mem_copy, {ASSERT_EQUAL eax, long_str_len}

        mov rdi, rsp
        mov esi, long_str_len
        xor edx, edx
        CALL_DO mem_set, {ASSERT_EQUAL eax, long_str_len}
        mov r8, rsp
        mov r9, long_str_len
.loop:
        sub r9, 1
        ASSERT_EQUAL byte [rsp + r9], 0
        jnz .loop

        add rsp, 1024*16 + 1

        mov di, 0x1234
        CALL_DO htons, {ASSERT_EQUAL ax, 0x3412}
        mov di, 0x0000
        CALL_DO htons, {ASSERT_EQUAL ax, 0x0000}

        mov rdi, num_str
        CALL_DO str_to_u32, {ASSERT_EQUAL edx, 1}
        ASSERT_EQUAL eax, 1337

        mov rdi, letters_str
        CALL_DO str_to_u32, {ASSERT_EQUAL edx, 0}

        mov rdi, empty_str_null
        CALL_DO str_to_u32, {ASSERT_EQUAL edx, 0}

        mov rdi, null_term_str
        CALL_DO strlen, {ASSERT_EQUAL eax, null_term_str_len}

        push 0
        mov rdi, rsp
        CALL_DO strlen, {ASSERT_EQUAL eax, 0}
        pop rax

        PRINT `success\n`

        mov eax, SYSCALL_EXIT
        xor edi, edi
        syscall

        section .data

DEFINE_STRING empty_str, ""
DEFINE_STRING test_str, "testing string /index.html?test=5"
DEFINE_STRING index_str_quest, "index.html?test=5"
DEFINE_STRING index_str_space, "index.html $(*!@)$7187"
DEFINE_STRING short_str, "test"
DEFINE_STRING_NULL num_str, "1337"
DEFINE_STRING_NULL letters_str, "abcdefg"
DEFINE_STRING_NULL empty_str_null, ""

long_str times 1024 * 8 db "x"
db "?"
times 1024 * 8 db "x"
long_str_len equ $ - long_str

DEFINE_STRING_NULL null_term_str, "testing strlen"
