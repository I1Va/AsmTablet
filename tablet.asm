.model tiny
.186
locals @@

.data

VIDEOSEG        equ 0b800h
X_CORD          equ 10d
Y_CORD          equ 10d
RECT_HEIGHT     equ 10d
RECT_WIDTH      equ 50d

tablet_string db 'Sweet February with Valentine!$'
rect_style db '+=+|.|+=+$'

.code
org 100h

start:

        mov ah, 01101110b                               ; rect color attr
        mov si, offset rect_style                       ; rect style pattern addr
        mov bx, RECT_HEIGHT                             ; bx = RECT_HEIGHT
        mov cx, RECT_WIDTH                              ; cx = RECT_WIDTH
        mov dx, VIDEOSEG                                ;|
        mov es, dx                                      ;| es = VIDEOSEG
        mov di, (X_CORD * 80d + Y_CORD) * 2d            ; DI = addr of (X_CORD, Y_CORD)
        call draw_rect

        mov ah, 11001110b                               ; label color attr
        mov si, offset tablet_string                    ; label memory addr
        mov cx, 30d                                     ; cx = label len
        mov di, (11dx * 80d + 11d) * 2d                 ; DI = addr of label addr on screen
        call draw_string


        mov ax, 4c00h                                   ;|
        int 21h                                         ;| exit(0)



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
                mov ah, 09h                             ;
                mov dx, offset msg_string               ; dx = &msg_string
                int 21h                                 ; print(dx)
                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               draw_pat_line
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws a line by pattern
; Entry:
;       AH      ; color attr
;       DS:SI   ; line pattern addr
;       CX      ; line length
;       ES:DI   ; line beginng addr
; Desroy:
;       AL, BX, CX, SI, DI
;------------------------------------------
draw_pat_line   proc
                cld                                     ; DF = 0 (++)

                lodsb                                   ; al = ds:[si++]
                stosw                                   ; es:[di++] = ax
                sub cx, 2d                              ; cx -= 2 for first, last char

                lodsb                                   ; al = ds:[si++]

                rep stosw                               ; while (CX != 0) {es:[di+=2] = ax}

                lodsb                                   ; al = ds:[si++]
                stosw                                   ; es:[di+=2] = al

                ret
                endp
;------------------------------------------
;##########################################







;##########################################
;               draw_rect
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws rectangle by pattern
; Entry:
;       AH      - color attr
;       DS:SI   - addr of pattern
;       BX      - rectangle height
;       CX      - rectangle width
;
;       ES:DI   - rectangle upper left corner
;------------------------------------------
draw_rect       proc
                push bx                                 ;|
                push cx                                 ;|reg saving
                push di                                 ;|

                call draw_pat_line                      ; call draw_pat_line

                pop di                                  ;|
                pop cx                                  ;|reg restoring
                pop bx                                  ;|

                add di, 160                             ;|next line
                sub bx, 2                               ;|

@@while:;-----------------------------------------------; while (BX > 0) {
                push bx                                 ;|
                push cx                                 ;|      reg saving
                push di                                 ;|

                push si                                 ;       save pattern middle triad addr

                call draw_pat_line                      ;       call draw_pat_line

                pop si                                  ;       restore patterm middle triad addr

                pop di                                  ;|
                pop cx                                  ;|      reg restoring
                pop bx                                  ;|

                add di, 160                             ;|      next line
                dec bx                                  ;|
                cmp bx, 0                               ;       if dx > 0 -> jump @@while
jg @@while;---------------------------------------------; while end }

                add  si, 3d
                push bx                                 ;|
                push cx                                 ;|reg saving
                push di                                 ;|

                call draw_pat_line                      ; call draw_pat_line

                pop di                                  ;|
                pop cx                                  ;|reg restoring
                pop bx                                  ;|

                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               draw_string
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws a string by addr ES:DI
; Entry:
;       AH      ; color attr
;       DS:SI   ; string memory addr
;       CX      ; string length
;       ES:DI   ; line beginning addr
; Desroy:
;       AL, BX, CX, SI, DI
;------------------------------------------
draw_string     proc
                cld                                     ; DF = 0 (++)
@@while:;-----------------------------------------------; while (CX != 0) {
                lodsb                                   ;       al = ds:[si++]
                stosw                                   ;       es:[di++] = ax
                loop @@while
;-------------------------------------------------------; while end }

                ret
                endp
;------------------------------------------
;##########################################

end start

