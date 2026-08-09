.rodata

filename:
    db "test.sqlite",10

filelen equ $ -filename

.text



open_file:
	mov rsi,0
	mov rdi,filename
	mov rdx,0
	mov rax,2
	syscall
sys_read:
	mov rax,8
	mov rsi,rcx
	mov rdx,0
	syscall
	pop rdx
	pop rsi
	pop rax









