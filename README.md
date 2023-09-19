# httpd-asm

Small multithreaded web server for static files (HTTP 1.0 subset) written in x64 assembly for Linux.

Probably full of CVEs. Don't use it.

## Features

- serve static files
- 200, 404, 501
- multithreaded
- tweak parameters in src/config.asm
- static and small executable

## Build

Requirements:

- Linux x64
- nasm
- GNU Make
- GNU Binutils

To build just run `make`.

## Usage

```
git clone https://github.com/ilya-sotnikov/httpd-asm
cd httpd-asm
make
cp target/httpd-asm ~/.local/bin
cd <HTML_DIRECTORY>
httpd-asm <THREADS_CNT> <PORT>
```
