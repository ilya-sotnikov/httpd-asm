%include "constants.asm"
%include "macro.asm"
%include "config.asm"

        extern htons
        extern mem_find_byte_or
        extern mem_copy

        section .text

%macro SYSCALL_ERROR_MAYBE 1
        test eax, eax
        jge %%ok

        mov edi, eax
        neg edi            ; 0 - errno in rax after syscall
        mov rsi, %1
        mov edx, %1_len
        jmp exit_error_msg
%%ok:
%endmacro

%macro SERVER_SEND 2
        mov eax, SYSCALL_WRITE
        mov edi, %1
        mov rsi, %2
        mov edx, %2_len
        syscall
%endmacro

; arg1 int error_code
; arg2 const char *msg
; arg3 size_t msg_len
exit_error_msg:
        mov r10d, edi ; error code

        mov eax, SYSCALL_WRITE
        mov edi, STDERR
        syscall

        mov eax, SYSCALL_EXIT
        mov edi, r10d
        syscall

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
        mov rdi, r12
        mov rsi, index_path
        mov edx, index_path_len
        call mem_copy
.null_terminate:
        mov byte [r12 + rax], 0  ; null-termination
        mov eax, 5               ; start_pos
.end:
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

        SYSCALL_ERROR_MAYBE socket_err_msg

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

        SYSCALL_ERROR_MAYBE setsockopt_err_msg

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

        SYSCALL_ERROR_MAYBE bind_err_msg

        mov eax, SYSCALL_LISTEN
        mov edi, r12d
        mov esi, LISTEN_BACKLOG  ; queued connections
        syscall

        SYSCALL_ERROR_MAYBE listen_err_msg

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

        SYSCALL_ERROR_MAYBE accept_err_msg

        mov r13d, eax

        mov eax, SYSCALL_READ
        mov edi, r13d
        mov rsi, rsp
        mov edx, MAX_REQUEST_LEN
        syscall

        SYSCALL_ERROR_MAYBE socket_read_err_msg

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
        jnz .send_file_loop

        mov eax, SYSCALL_CLOSE
        mov edi, r14d
        syscall

        SYSCALL_ERROR_MAYBE file_close_err_msg

.socket_close:
        mov eax, SYSCALL_CLOSE
        mov edi, r13d
        syscall

        SYSCALL_ERROR_MAYBE socket_close_err_msg

        jmp .loop

        add rsp, MAX_REQUEST_LEN
        pop r15
        pop r14
        pop r13
        pop r12
        ret

.send_404:
        SERVER_SEND r13d, HTTP404
        SYSCALL_ERROR_MAYBE socket_write_err_msg
        jmp .socket_close
.send_501:
        SERVER_SEND r13d, HTTP501
        SYSCALL_ERROR_MAYBE socket_write_err_msg
        jmp .socket_close

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
DEFINE_STRING HTTP501, `HTTP/1.1 501 Not Implemented\r\n\r\n`
