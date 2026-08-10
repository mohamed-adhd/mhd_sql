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
	mov rsi,0
	mov rdi,[rsp+16]
	mov rdx,0
	mov rax,2
	syscall;openin
	mov [fd],rax
	
	mov rdi,rax
	mov rsi,temp
	mov rax,5
	syscall; fstat call
	mov rax,[temp +48]
	push rax
	
	
	mov rdi,rax
	mov rsi,header_buf
	mov rdx,2
	mov rcx,16
	call readnbytes; read the pages size
	movzx rbx, byte [header_buf]
	shl rbx, 8
	movzx rax, byte [header_buf +1]
	or rbx,rax;conversion from bigendian
	
	pop rax
	xor rdx,rdx
	div rbx
	mov [n],rax;we got da number of pages  
	mov qword [i],1

	.loop
	mov rax,[i]
    	cmp rax,[n]
    	ja .scanpage
	

.scanpage:
	mov rdi,[fd]
	mov rsi,page_buf
	mov rdx,rbx
	mov rax, [i]
	dec rax
	imul rax, rbx
	mov rcx, rax
	call readnbytes; read page
	xor rdx,rdx
	mov rdx,page_buf
	call checkpage
	inc qword [i]
	jmp .loop

	
	
checkpage:
	
	cmp byte [page_buf],0x0D
	je .we_got_a_nodder
	jne .notleaf
	ret
.notleaf:
	ret

.we_got_a_nodder:
	movzx rax, byte [page_buf + 3]
	shl rax, 8
	movzx rcx, byte [page_buf + 4]
	or rax, rcx
	push rax
	movzx rax, byte [page_buf + 5]
	shl rax, 8
	movzx rcx, byte [page_buf + 6]
	or rax, rcx
	mov[cell_start],rax
	cmp [cell_start],0
	je .set_tha_shi
	pop rax
	mov [cellsn], rax
	mov rax, page_buf
	add rax, [cell_start]
	mov [cursor], rax
	call read_varint

.set_tha_shi:
	mov [cell_start],65536
	
.read_varint:
    movzx eax, byte [curs:or]
    test al, 0x80
    jnz .more_bytes

.more_bytes:

    inc qword [cursor]
    jmp .read_varint

















.read_cells:
	
	
	
	
	
	










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

