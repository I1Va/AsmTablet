	.file	"main.c"
	.text
	.globl	_get
	.def	_get;	.scl	2;	.type	32;	.endef
_get:
LFB12:
	.cfi_startproc
	movl	4(%esp), %eax
	subl	$31, %eax
	cmpl	$19, %eax
	jbe	L4
	movl	$0, %eax
	ret
L4:
	movl	$1, %eax
	ret
	.cfi_endproc
LFE12:
	.ident	"GCC: (MinGW.org GCC-6.3.0-1) 6.3.0"
