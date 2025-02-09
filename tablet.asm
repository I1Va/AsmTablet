.model tiny
.186
locals @@
.code
org 100h
VIDEOSEG equ 0b800h

start:
        ;call print_msg
        ;call show_tablet
        mov ax, 0
        mov bx, 0
        mov cx, 20
        mov dx, 20
        call draw_rect
        mov ax, 4c00h
        int 21h



;##########################################
;               print_msg
;------------------------------------------
msg_string db 'BreakPoint$'
;------------------------------------------
; Print string,
;   placed in msg_string asm variable
; Entry: None
; Exit: None
; Destr: AX, DX
;------------------------------------------
print_msg       proc
                mov ah, 09h
                mov dx, offset msg_string
                int 21h
                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               show_tablet
;------------------------------------------

;------------------------------------------
; Show tablet
; Entry: None
; Exit: None
; Destr: AX, BX, ES,
;------------------------------------------
show_tablet     proc
                mov ax, VIDEOSEG
                mov es, ax
                mov bx, 5*80*2 + 40*2
                mov byte ptr es:[bx], 'A'
                mov byte ptr es:[bx+1], 11101110b

                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               draw_line
;------------------------------------------

;------------------------------------------
; draws a line at coords (AX, BX)
; with length = CX
; Entry: AX, BX, CX
; Exit: None
; Destr: AX, BX, CX, DX, ES
; WARNING: inf loop expected if length < 0
;------------------------------------------
draw_line       proc
                mov dx, VIDEOSEG
                mov es, dx

                imul ax, 160
                imul bx, 2
                add bx, ax

@@while:                                           ; while (CX != 0):
                add bx, 2
                mov byte ptr es:[bx], 'A'
                mov byte ptr es:[bx+1], 11101110b
                LOOP @@while


                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               draw_rect
;------------------------------------------

;------------------------------------------
; draws a rectangle at coords (AX, BX)
;   with width = CX, height = DX
; Entry: AX, BX, CX, DX
; Exit: None
; Destr: AX, BX, CX, DX, ES
; WARNING: inf loop expected
;   if height/width < 0
;------------------------------------------
draw_rect       proc


@@while:                                           ; while (CX != 0):
                push ax
                push bx
                push cx
                push dx
                push es
                call draw_line
                pop es
                pop dx
                pop cx
                pop bx
                pop ax


                inc ax
                sub dx, 1
                cmp dx, 0
                jg @@while


                ret
                endp
;------------------------------------------
;##########################################


end start