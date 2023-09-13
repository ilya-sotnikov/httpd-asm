STDIN                  equ        0
STDOUT                 equ        1
STDERR                 equ        2

O_RDONLY               equ        0
O_WRONLY               equ        1
O_RDWR                 equ        2

AF_INET                equ        2
SOCK_STREAM            equ        1
SOL_SOCKET             equ        1
SO_REUSEADDR           equ        2

SYSCALL_READ           equ        0
SYSCALL_WRITE          equ        1
SYSCALL_OPEN           equ        2
SYSCALL_CLOSE          equ        3
SYSCALL_SENDFILE       equ       40
SYSCALL_SOCKET         equ       41
SYSCALL_ACCEPT         equ       43
SYSCALL_BIND           equ       49
SYSCALL_LISTEN         equ       50
SYSCALL_SETSOCKOPT     equ       54
SYSCALL_EXIT           equ       60
