.model tiny
.186
locals @@
.code
org 100h

line_pattern db '+-+$'

mov dx, line_pattern


mov ax, VIDEOSEG
mov es, ax

mov al, byte ptr offset dx
mov byte ptr es:[bx], al
add bx, 2
sub cx, 2