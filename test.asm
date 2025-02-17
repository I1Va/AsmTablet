.model tiny
.186
locals @@

.code
org 100h

start:
L4:
    mov ax, 40
	sub	ax, 31
	cmp	ax, 19
	jbe	L4; 19 <= ax <= 31

    mov ax, 4c00h                                   ;|
    int 21h                                         ;| exit(0)




end start

