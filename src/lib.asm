%include "constants.asm"

        section .text

; arg1 const char *s
; arg2 size_t len
; arg3 char c
; ret  int char_pos (-1 if not found or string empty)
global str_find_char
str_find_char:
        test rsi, rsi
        jz .char_not_found

        xor ecx, ecx
.loop:
        cmp byte [rdi + rcx], dl
        je .char_found
        inc ecx
        dec rsi
        jnz .loop
.char_not_found:
        mov rax, -1
        ret
.char_found:
        mov rax, rcx
        ret

; arg1 const char *s1
; arg2 const char *s2
; arg3 size_t n
; ret  1 if s1 == s2, 0 if (s1 != s2) or (n == 0)
global str_is_equal
str_is_equal:
        cmp rdx, 0
        jz .not_equal
        xor ecx, ecx
.loop:
        mov r8, [rsi + rcx]
        cmp byte [rdi + rcx], r8b
        jne .not_equal
        dec rdx
        jnz .loop
.equal:
        mov rax, 1
        ret
.not_equal:
        xor eax, eax
        ret

; arg1 void *dst
; arg2 const void *src
; arg3 size_t n
; ret  size_t n
global mem_copy
mem_copy:
        xor ecx, ecx
        mov rax, rdx
.loop:
        mov r8, [rsi + rcx]
        mov [rdi + rcx], r8
        inc rcx
        dec rdx
        jnz .loop
        ret

; arg1 uint16_t host_short
; ret  uint16_t network_short
global htons
htons:
        mov rax, rdi
        ror ax, 8
        ret