.rodata

filename:
    db "test.sqlite",10

filelen equ $ -filename


.bss
cell_start:  resq 1
cursor:      resq 1
payload_len: resq 1
rowid:       resq 1
payload_end: resq 1
varint_value: resq 1
align 8
page_buf: resb 65536
header_buf: resb 100
temp: resb 144
fd:resq 1
n:resq 1
s: resq 1
i:resq 1
cells_number: word 1
cellsn : resq 1
cell:
page_type:resb 1

.text

_start:

    mov rsi, 0
    mov rdi, [rsp+16]
    mov rdx, 0
    mov rax, 2
    syscall
    mov [fd], rax

    mov rdi, rax
    mov rsi, temp
    mov rax, 5
    syscall;fstat call

    mov rax, [temp + 48]
    push rax
    mov rdi, [fd]
    mov rsi, header_buf
    mov rdx, 2
    mov rcx, 16
    call readnbytes

    movzx rbx, byte [header_buf]
    shl rbx, 8
    movzx rax, byte [header_buf + 1]
    or rbx, rax; da number of pages is heree

    pop rax
    xor rdx, rdx
    div rbx
    mov [n], rax
    mov rdi, [fd]
    mov rsi, page_buf
    mov rdx, rbx
    xor rcx, rcx
    call readnbytes
    movzx eax, byte [page_buf + 100]
    cmp al, 0x0D
    je .schema_leaf

    cmp al, 0x05
    je .schema_interior
    jmp .exit


.schema_leaf:
    movzx rax, byte [page_buf + 103]
    shl rax, 8
    movzx rcx, byte [page_buf + 104]
    or rax, rcx
    mov [cellsn], rax
    movzx rax, byte [page_buf + 108]
    shl rax, 8
    movzx rcx, byte [page_buf + 109]
    or rax, rcx

    mov [cell_start], rax

    mov rax, page_buf
    add rax, [cell_start]
    mov [cursor], rax


    call read_varint
    mov rax, [varint_value]
    mov [payload_len], rax

    call read_varint
    mov rax, [varint_value]
    mov [rowid],rax
	mov
    jmp .exit


.schema_interior:

  
    jmp .exit


.exit:

    mov rax, 60
    xor rdi, rdi
    syscall
