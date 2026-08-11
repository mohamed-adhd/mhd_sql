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
header_size: resq 1
varint_value: resq 1


type_length: resq 1
name_length: resq 1
tbln_len: resq 1
rec_len: resq 1



align 8
page_buf: resb 65536
header_buf: resb 100
temp: resb 144
fd:resq 1
n :resq 1
s : resq 1
i :resq 1
cells_number : word 1
cellsn : resq 1
rootpage :resq 1
page_type : resb 1

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
    mov rax,[varint_value]
    mov [rowid],rax
    call read_varint
    mov rax,[varint_value]
    mov [header_size],rax
    
    call read_varint
    lea rsi,type_length
    call get_len
    
    call read_varint
    lea rsi,name_length	
    call get_len
    
    call raed_varint
    lea rsi,tbln_len
    call get_len

    call raed_varint
    lea rsi,rec_len
    call get_len

    
    






get_len:
cmp [varint_value],0
je .0eq
cmp [varint_value],1
je .1eq
cmp [varint_value],2
je .2eq
cmp [varint_value],3
je .3eq
cmp [varint_value],4
je .4eq
cmp [varint_value],5
je .5eq
cmp [varint_value],6
je .6eq
cmp [varint_value],7
je .7eq
cmp [varint_value],8
je .8eq
cmp [varint_value],9
je .9eq ;wish there was a better fucking way of doing ts, oh i forgot i m in asssembly...
jne .txt
ret









.1eq:
mov [rsi],1
ret
.2eq:
mov [rsi],2
ret
.3eq:
mov [rsi],3
ret
.4eq:
mov [rsi],4
ret
.5eq:
mov [rsi],6
ret
.6eq:
mov [rsi],8
ret
.7eq:
mov [rsi],8
ret
.8eq:
mov qwod [rsi],0
ret
.9eq:
mov qword [rsi],0
ret

.txt:
    mov rax,[varint_value]
    sub rax, 12
    shr rax,1
    mov [rsi],rax
    ret




























    
    jmp .exit


.schema_interior:

  
    jmp .exit








read_varint:
    xor rbx, rbx
.read:
    mov rdx, [cursor]
    movzx eax, byte [rdx]
    test al, 0x80
    jz .last
    and eax, 0x7f
    shl rbx, 7
    or  rbx, rax
    inc qword [cursor]
    jmp .read

.last:
    and eax, 0x7f
    shl rbx, 7
    or  rbx, rax
    inc qword [cursor]
    mov [varint_value], rbx
    ret











.exit:

    mov rax, 60
    xor rdi, rdi
    syscall
