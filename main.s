.rodata

filename:
    db "test.sqlite",10

filelen equ $ -filename

.bss
align 8
page_buf: resb 65536
header_buf: resb 100
temp: resb 144
n:resq 1
.text
	mov rsi,0
	mov rdi,[rsp+16]
	mov rdx,0
	mov rax,2
	syscall;openin
	mov ebx,rax
	mov ecx,temp
	push rax
	mov rax,5
	syscall
	pop rax
	
	mov ebx,rax
	mov ecx,temp
	push rax
	mov rax,5
	syscall
	pop rax

	mov rdi,rax
	mov rsi,header_buf
	mov rdx,2
	mov rcx,16
	call readnbytes; so here it should start reading page by page till a page type bytes are 0x0D
	xor rdx,rdx
	mov rbx,[temp]
	div rbx
	mov [n],rax;we got da number of pages  
	
		 











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

