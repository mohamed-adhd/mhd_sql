global _start

section .rodata

filename:
    db "test.sqlite",10

filelen equ $ -filename


section .bss
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



payload_headlen:  resq 1
columns_number:      resq 1
payload_end: resq 1
rowid:       resq 1
payload_end: resq 1
header_size: resq 1





















align 8
page_buf: resb 65536
header_buf: resb 100
temp: resb 144
fd:resq 1
n :resq 1
s : resq 1
i :resq 1
cells_number : resw 1
cellsn : resq 1
body_cursor  : resq 1
rootpage :resq 1
page_type : resb 1
testname: resb 64

section .text

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
    je schema_interior
    jmp exit


.schema_leaf:
    movzx rax, byte [page_buf + 103]
    shl rax, 8
    movzx rcx, byte [page_buf + 104]
    or rax, rcx
    mov [cellsn], rax
    movzx rax, byte [page_buf + 105]
    shl rax, 8
    movzx rcx, byte [page_buf + 106]
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
    lea rsi,[type_length]
    call get_len
    
    call read_varint
    lea rsi,[name_length]	
    call get_len
    
    call read_varint
    lea rsi,[tbln_len]
    call get_len

    call read_varint
    lea rsi,[rec_len]
    call get_len

    
    mov rax, [type_length]
    add [cursor], rax
    

    mov rax,[page_buf]
    push rax
    mov rdi, [fd]
    mov rsi, testname
    mov rdx, [name_length]
    mov rcx, [cursor]
    call readnbytes

    mov rsi,testname
    mov rdi,[rsp+32]
    mov rcx,name_length
    call strcmp_name
    test rax, rax
    jnz .FOUNDIT
    mov rax,[rootpage]
    dec rax
    imul rax,rbx
    mov rdi, [fd]
    mov rsi, page_buf
    mov rdx, rbx
    mov rcx, rax; focus you are here , this mf vim editor is so ass
    call readnbytes
    movzx eax, byte [page_buf]
    cmp eax,0x0D
    je .we_got_a_nodder
    jne .maybenot

.maybenot:
    cmp eax,0x0D
    je .interior
    jne .next

.we_got_a_nodder:
    movzx eax, byte [page_buf]
    cmp eax, 0x05
    jne .not_leaf

    movzx eax, word [page_buf + 3]
    movzx eax, byte [page_buf + 3]
    shl eax, 8
    movzx ecx, byte [page_buf + 4]
    or eax, ecx
    mov  [cellsn], rax
    movzx eax,[page_buf+8]
    movzx eax, byte [page_buf + 8]
    shl eax, 8
    movzx ecx, byte [page_buf + 9]
    or eax, ecx
    lea rax, [page_buf + rax]
    mov [cursor], rax
   

   call read_varint
   mov [payload_len],[varint_value]
   call read_varint
   mov [row_id],[varint_value]
   mov rax, [temp + 48]
   push rax
   mov rdi, [page_buffer]
   mov rsi, [temp_payload]
   mov rdx, [payload_length]
   mov rcx, cursor
   call readnbytes
   call decodepayload


 // the cursor is at the payload heder , you just read the payload length, focus now set the body cursor at the actual body
   
.read_column:

    ; header cursor points at next serial type
    mov rax, [header_cursor]
    cmp rax, [header_end]
    jae .done

    mov [cursor], rax
    call read_varint
    mov rax, [varint_value]

 
    mov rax, [body_cursor]
    add rax, [value_length]
    mov [body_cursor], rax

    mov rax, [cursor]
    mov [header_cursor], rax

    jmp .read_column
    
   
   




   
   











.interior



























    
   
    

.FOUNDIT:
    mov rax, [cursor]
    add rax, [type_length]
    add rax, [name_length]
    add rax, [tbln_len]
    mov [cursor], rax





    mov rcx, [rec_len]

    cmp rcx, 1
    je .root_1
    cmp rcx, 2
    je .root_2
    cmp rcx, 3
    je .root_3
    cmp rcx, 4;sometimes i loose myslf here bruh
    je .root_4


    jmp exit


.root_1:
    movzx rax, byte [cursor]
    mov [rootpage], rax
    jmp .got_rootpage

.root_2:
    movzx rax, byte [cursor]
    shl rax, 8

    movzx rcx, byte [cursor + 1]
    or rax, rcx

    mov [rootpage], rax
    jmp .got_rootpage
















.root_3:
    movzx rax, byte [cursor]
    shl rax, 16

    movzx rcx, byte [cursor + 1]
    shl rcx, 8
    or rax, rcx

    movzx rcx, byte [cursor + 2]
    or rax, rcx

    mov [rootpage], rax;dawg sometimes i whish i had a gf and a normal life instead of this
    jmp .got_rootpage


.root_4:
    movzx rax, byte [cursor]
    shl rax, 24
    movzx rcx, byte [cursor + 1]
    shl rcx, 16
    or rax, rcx
    movzx rcx, byte [cursor + 2]
    shl rcx, 8
    or rax, rcx
    movzx rcx, byte [cursor + 3]
    or rax, rc
    mov [rootpage], rax














    jmp exit
    























strcmp_name:
    ;wso  rsi = sqlite namy and  rdi = argv[2]  andd rcx = name length
    xor rax, rax

.cmp:
    cmp rcx, 0
    je .checkda_end

    mov dl, [rsi]
    cmp dl, [rdi]
    jne .nual

    inc rsi
    inc rdi
    dec rcx
    jmp .cmp

.checkda_end:
    cmp byte [rdi], 0
    jne .nual

    mov rax, 1
    ret

.nual:
    xor rax, rax
    ret    






get_len:
cmp qword [varint_value],0
je .0eq
cmp qword [varint_value],1
je .1eq
cmp qword [varint_value],2
je .2eq
cmp qword [varint_value],3
je .3eq
cmp qword [varint_value],4
je .4eq
cmp qword [varint_value],5
je .5eq
cmp qword [varint_value],6
je .6eq
cmp qword [varint_value],7
je .7eq
cmp qword [varint_value],8
je .8eq
cmp qword [varint_value],9
je .9eq ;wish there was a better fucking way of doing ts, oh i forgot i m in asssembly...
jne .txt
ret









.0eq:
mov qword [rsi],0
ret
.1eq:
mov qword [rsi],1
ret
.2eq:
mov qword [rsi],2
ret
.3eq:
mov qword [rsi],3
ret
.4eq:
mov qword [rsi],4
ret
.5eq:
mov qword [rsi],6
ret
.6eq:
mov qword [rsi],8
ret
.7eq:
mov qword [rsi],8
ret
.8eq:
mov qword [rsi],0
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




























    
    jmp exit


schema_interior:

  
    jmp exit








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




readnbytes:
	push rdi
	push rdx
	push rsi
	mov rax,8
	mov rsi,rcx
	mov rdx,0
	syscall;seek	
	pop rdx
	pop rsi
	pop rdi
	mov rax,0
	syscall
	ret







exit:

    mov rax, 60
    xor rdi, rdi
    syscall
