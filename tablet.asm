.model tiny
.186
locals @@
.code
org 100h
VIDEOSEG equ 0b800h

start:
        mov ax, 5d                                      ; X cord
        mov bx, 5d                                      ; Y cord
        mov cx, 40d                                     ; width
        mov dx, 10d                                     ; height

        push ax                                         ;|
        push bx                                         ;|
        call draw_rect                                  ;| call draw_rect
        pop bx                                          ;|
        pop ax                                          ;|

        ;=============================================
        ; There is should be calculating text position
        add ax, 1
        add bx, 1
        ;=============================================


        mov cx, 30d                                     ;|
        mov dx, offset tablet_string                    ;| call draw_string
        call draw_string                                ;|

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
; draws a line of 3 parts at coords (AX, BX)
; line length = CX
; line pattern adress = DX
; 1st part consists of 1st sim of line_pattern, len = 1
; 2nd - 2nd sim, len = CX - 2
; 3rd - 3rd sim, len = 1
; Entry: AX, BX, CX, DX
; Exit: None
; Destr: None
; WARNING: inf loop expected if length < 0
; WARNING: len of string: max(CX, 3)
;------------------------------------------
draw_pat_line   proc
                push ax                                 ;|
                push bx                                 ;|
                push cx                                 ;| reg save
                push dx                                 ;|
                push es                                 ;|

                imul ax, 160                            ;|
                imul bx, 2                              ;| Calculating video segmemt bias
                add bx, ax                              ;|

                mov ax, VIDEOSEG                        ;| setting segment register
                mov es, ax                              ;| es = VIDEOSEG

                push si                                 ; saving si
                mov si, dx                              ; si = di = patter_line adress

                mov al, byte ptr [si]                   ;| al = MEM[si++]
                inc si                                  ;|
                mov byte ptr es:[bx], al                ; es:[bx] = al

                add bx, 2                               ; next char
                sub cx, 2                               ; remaining len -= 2


@@while:;-----------------------------------------------; while (CX != 0) {
                mov al, byte ptr [si]                   ;       al = MEM[si]
                mov byte ptr es:[bx], al                ;       es:[bx] = al
                add bx, 2                               ;       next char
LOOP @@while;-------------------------------------------; }

                inc si                                  ;| al = MEM[si++]
                mov al, byte ptr [si]                   ;|
                mov byte ptr es:[bx], al                ; es:[bx] = al

                pop si                                  ;|
                pop es                                  ;|
                pop dx                                  ;|
                pop cx                                  ;| reg restore
                pop bx                                  ;|
                pop ax                                  ;|

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

                push dx                                 ; saving prev dx
                mov dx, offset line_pattern             ; dx = &line_pattern
                call draw_pat_line                      ; call draw_pat_line

                pop dx                                  ; restore dx
                inc ax                                  ; next line (X++)
                sub dx, 2                               ; remaining height -= 2

@@while:;-----------------------------------------------; while (DX > 0) {

                push dx                                 ;        saving prev dx
                mov dx, offset line_pattern             ;|       dx = &line_pattern + 3
                add dx, 3                               ;|
                call draw_pat_line                      ;        call draw_pat_line

                pop dx                                  ;        restore dx
                inc ax                                  ;        next line (X++)
                sub dx, 1                               ;        remaining height--

                cmp dx, 0                               ;        if dx > 0 -> jump @@while
jg @@while;---------------------------------------------; while end }

                push dx                                 ; saving dx
                mov dx, offset line_pattern             ;|dx = &line_pattern + 6
                add dx, 6                               ;|

                call draw_pat_line                      ;| call draw_pat_line

                pop dx                                  ; restore dx

                inc ax                                  ; next line (X++)
                sub dx, 2                               ; remaining height--

                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               draw_string
;------------------------------------------
;------------------------------------------
; draws string at coords (AX, BX)
; string length = CX
; string adress = DX
; Entry: AX, BX, CX, DX
; Exit: None
; Destr: None
; WARNING: inf loop expected if length < 0
;------------------------------------------
draw_string     proc
                push ax           ;|
                push bx           ;|
                push cx           ;| reg save
                push dx           ;|
                push es           ;|
                push si           ;|

                imul ax, 160      ;|
                imul bx, 2        ;|
                add bx, ax        ;| es = VIDEOSEG addr with
                mov ax, VIDEOSEG  ;| coords (AX, BX)
                mov es, ax        ;|

                mov si, dx        ; si = string addr

@@while:;-----------------------------------------------; while (CX != 0) {
                mov al, byte ptr [si]                           ; al = MEM[si]
                mov byte ptr es:[bx], al                        ; es:[bx] = al

                add bx, 2                                       ;
                inc si
LOOP @@while;-------------------------------------------; }
                pop si ; |
                pop es ; |
                pop dx ; |
                pop cx ; | reg restore
                pop bx ; |
                pop ax ; |

                ret
                endp
;------------------------------------------
;##########################################

.data
tablet_string db 'Sweet February with Valentine!$'
line_pattern db '+=+|.|+=+$'

end start

