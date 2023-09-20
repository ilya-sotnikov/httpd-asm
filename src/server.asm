%include "constants.asm"
%include "macro.asm"
%include "config.asm"

        extern exit_error_msg
        extern htons
        extern mem_find_byte_or
        extern mem_set

        section .text

%macro SERVER_SEND 2
        mov eax, SYSCALL_WRITE
        mov edi, %1
        mov rsi, %2
        mov edx, %2_len
        syscall
%endmacro

setup_sigaction:
        sub rsp, 36
        mov rdi, rsp
        mov esi, 36
        mov edx, 0
        call mem_set

        mov eax, SYSCALL_RT_SIGACTION
        mov rdi, SIGPIPE
        mov qword [rsp], SIG_IGN
        mov rsi, rsp
        mov r10d, 8                  ; sizeof(sigset_t)
        syscall
        SYSCALL_CHECK_ERROR_DIE `sigaction failed\n`
        add rsp, 36
        ret

; arg1 uint8_t *request (len >= 4096+5 for max file_path len for Linux)
; ret  uint32_t file_path_start_pos
; edits the request buffer for perfomance
; either null-terminates file_path in a request or copies "index.html"
; at the beginning of request buffer
request_file_get:
        push r12

        add rdi, 5               ; start_pos

        mov r12, rdi

        xor eax, eax
        cmp byte [r12], "."
        je .end

        mov edx, " "
        mov ecx, "?"
        call mem_find_byte_or

        test eax, eax
        jg .null_terminate
.file_empty:
        mov r8, "index.ht"
        mov r9d, `ml\x00\x00`
        mov qword [r12], r8
        mov dword [r12 + 8], r9d
        jmp .end
.null_terminate:
        mov byte [r12 + rax], 0  ; null-termination
.end:
        mov eax, 5               ; start_pos
        pop r12
        ret

; arg1 uint16_t port
global server_start
server_start:
        push r12
        push r13
        sub rsp, 16

        movzx r13d, di

        mov eax, SYSCALL_SOCKET
        mov edi, AF_INET
        mov esi, SOCK_STREAM
        xor edx, edx
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket create failed\n`

        mov r12d, eax

        mov qword [rsp], 0
        mov qword [rsp+8], 0

        mov eax, SYSCALL_SETSOCKOPT
        mov edi, r12d
        mov esi, SOL_SOCKET
        mov edx, SO_REUSEADDR
        mov dword [rsp], 1
        mov r10, rsp
        mov r8d, 4
        syscall

        SYSCALL_CHECK_ERROR_DIE `setsockopt failed\n`

        mov qword [rsp], 0
        mov qword [rsp+8], 0
        mov byte [rsp], AF_INET
        mov edi, r13d
        call htons
        mov word [rsp+2], ax

        mov eax, SYSCALL_BIND
        mov edi, r12d
        mov rsi, rsp
        mov edx, 16
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket bind failed\n`

        mov eax, SYSCALL_LISTEN
        mov edi, r12d
        mov esi, LISTEN_BACKLOG  ; queued connections
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket listen failed`

        call setup_sigaction

        mov eax, r12d            ; server fd

        add rsp, 16
        pop r13
        pop r12
        ret

; arg1 uint32_t fd
global server_loop
server_loop:
        push r12
        push r13
        push r14
        push r15
        sub rsp, MAX_REQUEST_LEN
        mov r12d, edi
.loop:
        mov eax, SYSCALL_ACCEPT
        mov edi, r12d
        xor esi, esi
        xor edx, edx
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket accept failed\n`

        mov r13d, eax

        mov eax, SYSCALL_READ
        mov edi, r13d
        mov rsi, rsp
        mov edx, MAX_REQUEST_LEN
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket read failed\n`

        mov r15d, eax
        cmp r15d, 5
        jl .send_501

        cmp dword [rsp], "GET "
        jne .send_501

        mov rdi, rsp
        call request_file_get

        mov rdi, rsp
        add rdi, rax            ; correct start_pos of file_path
        mov eax, SYSCALL_OPEN
        mov esi, O_RDONLY
        syscall

        mov r14d, eax

        test eax, eax
        jl .send_404

.file_found:
        SERVER_SEND r13d, HTTP200

        mov edi, r13d
        mov esi, r14d
        xor edx, edx
        mov r10d, MAX_SENDFILE_LEN
.send_file_loop:
        mov eax, SYSCALL_SENDFILE
        syscall
        test eax, eax
        jl .file_close
        jnz .send_file_loop
.file_close:
        mov eax, SYSCALL_CLOSE
        mov edi, r14d
        syscall

        SYSCALL_CHECK_ERROR_DIE `file close failed\n`

.socket_close:
        mov eax, SYSCALL_CLOSE
        mov edi, r13d
        syscall

        SYSCALL_CHECK_ERROR_DIE `socket close failed\n`

        jmp .loop

        add rsp, MAX_REQUEST_LEN
        pop r15
        pop r14
        pop r13
        pop r12
        ret

.send_404:
        SERVER_SEND r13d, HTTP404
        SYSCALL_CHECK_ERROR_DIE `socket write failed\n`
        jmp .socket_close
.send_501:
        SERVER_SEND r13d, HTTP501
        SYSCALL_CHECK_ERROR_DIE `socket write failed\n`
        jmp .socket_close

        section .data

DEFINE_STRING HTTP200, `HTTP/1.0 200 0K\r\n\r\n`
DEFINE_STRING HTTP404, `HTTP/1.0 404 Not Found\r\n\r\n`
DEFINE_STRING HTTP501, `HTTP/1.0 501 Not Implemented\r\n\r\n`
