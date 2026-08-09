.rodata

filename:
    db "test.sqlite",10

filelen equ $ -filename

.bss
align 8
page_buf: resb 65536
header_buf: resb 100
temp: resb 144
fd:resq 1
n:resq 1
s: resq 1
i:resb 1
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
	push rax
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
	mov [i],1

	.loop
	cmp [i],[n]
	jne .scanpage
	

.scanpage:
	mov rdi,rax
	mov rsi,page_buf
	mov rdx,rbx
	mov rcx,rbx*[i]
	call readnbytes; read page
	xor rdx,rdx
	mov rdx,page_buf
	call checkpage
	inc [i]
	jmp .loop

	
	
checkpage:
	mov rdi,rax
	mov rsi,page_type
	mov rdx,1
	mov rcx,0
	call readnbytes; read page
	cmp [page_type],0x0D
	je .we_got_a_nodder

.we_got_a_nodder:
	mov rdi,[fd]
	mov rsi,cells_number
	mov rdx,2
	mov rcx,3
	call readnbytes; read page
	push rbx
	push rax
	mov rbx,rax
	movzx rbx, byte [cells_number]
	shl rbx, 8
	movzx rax, byte [cells_number+1]
	or rbx,rax;
	mov [cellsn],rbx
	pop rax
	pop rbx
	
	
	
	










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

