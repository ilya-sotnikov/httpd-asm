%include "constants.asm"
%include "macro.asm"

        extern htons
        extern str_find_char
        extern mem_copy

        section .text

%macro SYSCALL_ERROR_MAYBE 1
        cmp rax, 0
        jge %%ok

        mov rdi, rax
        neg rdi            ; 0 - errno in rax after syscall
        mov rsi, %1
        mov rdx, %1_len
        jmp exit_error_msg
%%ok:
%endmacro

%macro SERVER_SEND 2
        mov rax, SYSCALL_WRITE
        mov rdi, %1
        mov rsi, %2
        mov rdx, %2_len
        syscall
%endmacro

; arg1 int error_code
; arg2 const char *msg
; arg3 size_t msg_len
exit_error_msg:
        mov r10, rdi ; error code

        mov rax, SYSCALL_WRITE
        mov rdi, STDERR
        syscall

        mov rax, SYSCALL_EXIT
        mov rdi, r10
        syscall

; arg1 const char *request
; arg2 size_t request_len
; ret  bool is_get
request_is_get:
.loop:
        cmp rsi, 4
        jl .end_false
        cmp dword [rdi], "GET "
        je .end_true
.end_false:
        xor eax, eax
        ret
.end_true:
        mov rax, 1
        ret

; arg1 const char *request
; arg2 size_t request_len
; arg3 char *file_path (should be 4096 bytes, max on Linux)
; ret  size_t file_path_len
request_file_get:
        cmp rsi, 5
        jl .end_zero

        push r12
        push r13
        push r14
        push r15

        mov r12, rdi
        mov r13, rsi
        mov r14, rdx

        mov rdx, "/"
        call str_find_char

        inc rax                        ; skip /
        mov r15, rax                   ; start_pos

        xor eax, eax
        cmp byte [r12 + r15], "."
        je .pop_ret

        lea rdi, [r12 + r15]
        sub r13, r15
        mov rsi, r13
        mov rdx, " "
        call str_find_char

        cmp rax, 0
        jg .file_not_empty
.file_empty:
        mov rsi, index_path
        mov rdx, index_path_len
        jmp .call_mem_copy
.file_not_empty:
        lea rsi, [r12 + r15]
        mov rdx, rax
.call_mem_copy:
        mov rdi, r14
        call mem_copy
.pop_ret:
        pop r15
        pop r14
        pop r13
        pop r12
        ret
.end_zero:
        xor eax, eax
        ret

global server_start
server_start:
        push rbp
        mov rbp, rsp
        push r12
        sub rsp, 16

        mov rax, SYSCALL_SOCKET
        mov rdi, AF_INET
        mov rsi, SOCK_STREAM
        xor edx, edx
        syscall

        SYSCALL_ERROR_MAYBE socket_err_msg

        mov r12, rax

        mov qword [rsp], 0
        mov qword [rsp+8], 0

        mov rax, SYSCALL_SETSOCKOPT
        mov rdi, r12
        mov rsi, SOL_SOCKET
        mov rdx, SO_REUSEADDR
        mov dword [rsp], 1
        mov r10, rsp
        mov r8, 4
        syscall

        SYSCALL_ERROR_MAYBE setsockopt_err_msg

        mov qword [rsp], 0
        mov qword [rsp+8], 0
        mov byte [rsp], AF_INET
        mov rdi, 8080
        call htons
        mov word [rsp+2], ax

        mov rax, SYSCALL_BIND
        mov rdi, r12
        mov rsi, rsp
        mov rdx, 16
        syscall

        SYSCALL_ERROR_MAYBE bind_err_msg

        mov rax, SYSCALL_LISTEN
        mov rdi, r12
        mov rsi, 4096           ; queued connections
        syscall

        SYSCALL_ERROR_MAYBE listen_err_msg

        mov rax, r12            ; server fd

        add rsp, 16
        pop r12
        mov rsp, rbp
        pop rbp
        ret

global server_loop
server_loop:
        push r12
        push r13
        push r14
        push r15
        sub rsp, 4096 * 2
        mov r12, rdi
.loop:
        mov rax, SYSCALL_ACCEPT
        mov rdi, r12
        xor esi, esi
        xor edx, edx
        syscall

        SYSCALL_ERROR_MAYBE accept_err_msg

        mov r13, rax

        mov rax, SYSCALL_READ
        mov rdi, r13
        mov rsi, rsp
        mov rdx, 4096
        syscall

        SYSCALL_ERROR_MAYBE socket_read_err_msg

        mov r15, rax

        mov rdi, rsp
        mov rsi, rax
        call request_is_get
        cmp rax, 0
        jz .socket_close

        mov rdi, rsp
        mov rsi, r15
        lea rdx, [rsp + 4096]
        call request_file_get
        cmp rax, 0
        jz .send_404

        mov byte [rsp + 4096 + rax], 0 ; null-termination for syscall

        mov rax, SYSCALL_OPEN
        lea rdi, [rsp + 4096]
        mov rsi, O_RDONLY
        syscall

        mov r14, rax

        cmp rax, 0
        jge .file_found

.send_404:
        SERVER_SEND r13, HTTP404
        SYSCALL_ERROR_MAYBE socket_write_err_msg
        jmp .socket_close

.file_found:
        SERVER_SEND r13, HTTP200

.send_file:
        mov rax, SYSCALL_SENDFILE
        mov rdi, r13
        mov rsi, r14
        xor edx, edx
        mov r10, 4096
        syscall
        cmp rax, 0
        jnz .send_file

        mov rax, SYSCALL_CLOSE
        mov rdi, r14
        syscall

        SYSCALL_ERROR_MAYBE file_close_err_msg

.socket_close:
        mov rax, SYSCALL_CLOSE
        mov rdi, r13
        syscall

        SYSCALL_ERROR_MAYBE socket_close_err_msg

        jmp .loop

        add rsp, 4096 * 2
        pop r15
        pop r14
        pop r13
        pop r12
        ret

        section .data

DEFINE_STRING socket_err_msg, `socket create failed\n`
DEFINE_STRING setsockopt_err_msg, `setsockopt failed\n`
DEFINE_STRING bind_err_msg, `socket bind failed\n`
DEFINE_STRING listen_err_msg, `socket listen failed`
DEFINE_STRING accept_err_msg, `socket accept failed\n`
DEFINE_STRING file_open_err_msg, `file open failed\n`
DEFINE_STRING file_close_err_msg, `file close failed\n`
DEFINE_STRING socket_close_err_msg, `socket close failed\n`
DEFINE_STRING socket_read_err_msg, `socket read failed\n`
DEFINE_STRING socket_write_err_msg, `socket write failed\n`

DEFINE_STRING index_path, "index.html"

DEFINE_STRING HTTP200, `HTTP/1.1 200 0K\r\n\r\n`
DEFINE_STRING HTTP404, `HTTP/1.1 404 Not Found\r\n\r\n`