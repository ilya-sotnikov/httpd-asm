%include "constants.asm"

        section .text

; arg1 const char *s
; ret  size_t n
; for C API
global strlen
strlen:
        xor eax, eax
        mov rcx, -1
        repne scasb
        not rcx
        mov rax, rcx
        sub rax, 1
        ret

; arg1 const uint8_t *m
; arg2 int32_t size
; arg3 uint8_t byte
; ret  int32_t byte_pos (-1 if not found or size == 0)
global mem_find_byte
mem_find_byte:
        test esi, esi
        jz .byte_not_found
        xor ecx, ecx
.loop:
        cmp byte [rdi + rcx], dl
        je .byte_found
        add ecx, 1
        sub esi, 1
        jnz .loop
.byte_not_found:
        mov eax, -1
        ret
.byte_found:
        mov eax, ecx
        ret

; arg1 const uint8_t *m
; arg2 int32_t size
; arg2 uint8_t byte1
; arg3 uint8_t byte2
; ret  int32_t byte_pos (-1 if not found or size == 0)
global mem_find_byte_or
mem_find_byte_or:
        test esi, esi
        jz .byte_not_found
        xor r8d, r8d
.loop:
        mov r9b, byte [rdi + r8]
        cmp r9b, dl
        je .byte_found
        cmp r9b, cl
        je .byte_found
        add r8d, 1
        sub esi, 1
        jnz .loop
.byte_not_found:
        mov eax, -1
        ret
.byte_found:
        mov eax, r8d
        ret

; arg1 const uint8_t *m1
; arg2 const uint8_t *m2
; arg3 uint32_t n
; ret  1 if m1 == m2, 0 if (m1 != m2) or (n == 0)
global mem_is_equal
mem_is_equal:
        test edx, edx
        jz .not_equal
        xor ecx, ecx
.loop:
        mov r8b, byte [rsi + rcx]
        cmp byte [rdi + rcx], r8b
        jne .not_equal
        sub edx, 1
        jnz .loop
.equal:
        mov eax, 1
        ret
.not_equal:
        xor eax, eax
        ret

; arg1 void *dst
; arg2 const void *src
; arg3 uint32_t n
; ret  uint32_t n
global mem_copy
mem_copy:
        xor ecx, ecx
        mov eax, edx
.loop:
        mov r8b, byte [rsi + rcx]
        mov byte [rdi + rcx], r8b
        add ecx, 1
        sub edx, 1
        jnz .loop
        ret

; arg1 const char *str
; arg2 uint32_t str_len
; ret1 uint32_t num
; ret2 bool success
global str_to_u32
str_to_u32:
        xor eax, eax
        xor edx, edx
        xor r8d, r8d
        mov ecx, 1
        mov r9d, 10
.loop:
        movzx r8d, byte [rdi]

        sub r8d, "0"
        jl .fail
        cmp r8d, 9
        jg .fail

        mul r9d
        add eax, r8d

        add ecx, 1
        add rdi, 1
        sub esi, 1
        jnz .loop

.success:
        mov edx, 1
        ret
.fail:
        xor edx, edx
        ret

; arg1 uint16_t host_short
; ret  uint16_t network_short
global htons
htons:
        movzx eax, di
        ror ax, 8
        ret
