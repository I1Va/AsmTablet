.model tiny
.186
locals @@
.code
org 100h
VIDEOSEG equ 0b800h

start:

        ;call print_msg
        ;call show_tablet
        mov ax, 5
        mov bx, 5
        mov cx, 40
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
;               draw_pat_line
;------------------------------------------
;------------------------------------------
; draws a line of 3 parts at coords (AX, BX)
; line length = CX
; line pattern adress = DX
; 1st part consists of 1st sim of line_pattern, len = 1
; 2nd - 2nd sim, len = CX - 2
; 3rd - 3rd sim, len = 1
; Entry: AX, BX, CX, DX
; Exit: None
; Destr: AX, BX, CX, DX, ES
; WARNING: inf loop expected if length < 0
; WARNING: len of string: max(CX, 3)
;------------------------------------------
draw_pat_line   proc
                imul ax, 160
                imul bx, 2
                add bx, ax

                mov ax, VIDEOSEG
                mov es, ax

                push si
                mov si, dx

                mov al, byte ptr [si]
                inc si
                mov byte ptr es:[bx], al
                add bx, 2
                sub cx, 2
@@while:                                           ; while (CX != 0):


                mov al, byte ptr [si]
                mov byte ptr es:[bx], al
                ;mov byte ptr es:[bx+1], 11101110b
                add bx, 2
                LOOP @@while

                inc si
                mov al, byte ptr [si]
                mov byte ptr es:[bx], al

                pop si
                ret
                endp
;------------------------------------------
;##########################################







;##########################################
;               draw_rect
;------------------------------------------
line_pattern db '+-+$'
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
                mov dx, offset line_pattern
                call draw_pat_line
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