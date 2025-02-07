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
        mov bx, 40
        mov cx, 10
        call draw_line
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
; Destr: AX, BX, ES, DX
; WARNING: inf loop expected if length < 0
;------------------------------------------
draw_line       proc
                mov dx, VIDEOSEG
                mov es, dx

                imul ax, 160
                imul bx, 2
                add bx, ax

@@while:
                add bx, 2
                mov byte ptr es:[bx], 'A'
                mov byte ptr es:[bx+1], 11101110b
                LOOP @@while


                ret
                endp
;------------------------------------------
;##########################################



end start