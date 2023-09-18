LISTEN_BACKLOG         equ 4096             ; maximum length to which the queue of pending connections for sockfd may grow
MAX_REQUEST_LEN        equ 1024 * 8         ; at least 4096 + 5, check request_file_get
MAX_SENDFILE_LEN       equ 1024 * 16        ; chunks, number of bytes to copy from a file to a socket in 1 syscall
THREAD_STACK_SIZE      equ 4096 * 4         ; at least MAX_REQUEST_LEN
THREAD_COUNT           equ 8
