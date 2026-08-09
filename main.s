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
s: resq 1
i:resb 1
.text
	mov rsi,0
	mov rdi,[rsp+16]
	mov rdx,0
	mov rax,2
	syscall;openin
	

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
	
	.loop
	mov [i],1
	cmp [i],[n]
	jne .scanpage
	

.scanpage:
	mov rdi,rax
	mov rsi,page_buf
	mov rdx,rbx
	mov rcx,rbx*[i]
	call readnbytes; read page

	
	



	










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

