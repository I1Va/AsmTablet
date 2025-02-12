.model tiny
.186
locals @@

.data

ARGS_ADDR               equ 0082h
DIGITS_SHIFT            equ 30h
VIDEOSEG                equ 0b800h
X_CORD                  equ 10d
Y_CORD                  equ 10d

NUM_BASE DB 10d

tablet_string db 'Sweet February with Valentine!$'
atoi_error_msg db 'atoi: string contains non-decimal characters$'

RS1 db "+=+|.|+=+$"
RS2 db "0-0I*I0-0$"

STYLES_ARR dw offset RS1, offset RS2

.code
org 100h
start:

        mov     si, ARGS_ADDR                           ; si = 1st arg addr
        call    atoi                                    ; bx = atoi(1st arg)

        mov     cx, bx                                  ; cx = bx
        call    atoi                                    ; bl = RECT_HEIGHT from com arg

        mov     ah, 01101110b                           ; rect color attr
        mov si, STYLES_ARR[1*(TYPE STYLES_ARR)]         ; rect style pattern addr
        mov dx, VIDEOSEG                                ;|
        mov es, dx                                      ;| es = VIDEOSEG
        mov di, (X_CORD * 80d + Y_CORD) * 2d            ; DI = addr of (X_CORD, Y_CORD)
        call draw_rect

        mov ah, 11001110b                               ; label color attr
        mov si, offset tablet_string                    ; label memory addr
        mov cx, 30d                                     ; cx = label len
        mov di, (11d * 80d + 11d) * 2d                 ; DI = addr of label addr on screen
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

;##########################################
;               n_atoi
;------------------------------------------
;------------------------------------------
; Descr:
;       convert decimal string
;        to decimal integer
; Entry:
;       DS:SI   ; string memory addr
;       CX      ; string length
; Return:
;       BX = integer gotten from string
; Desroy:
;       AX, BX, CX, SI
;------------------------------------------
n_atoi          proc
                push cx                                 ; save cx
                xor ax, ax


@@check_while:;-----------------------------------------; while(cx != 0) {
        lodsb                                           ;|      al = ds:[si++]

        cmp ax, 30h                                     ;|      if (ax < '0') -> jmp error
        jl @@error                                      ;|

        cmp ax, 39h                                     ;|      if (ax > '9') -> jmp error
        jg @@error                                      ;|
        loop @@check_while

;while_end----------------------------------------------; }

                pop cx                                  ; restore cx
                xor bx, bx                              ; bx = 0
                std                                     ; DF = 1 (--)

@@while:;-----------------------------------------------; while (CX != 0) {
                lodsb                                   ;       al = ds:[si--]
                mul NUM_BASE                            ;|FIXME:(переписать) lea    ax, (ax, ax, 4)
                                                        ;|slow   на сдвиги   shl    ax, 2
                add bx, ax
                loop @@while
;-------------------------------------------------------; while end }
@@error:
                mov ah, 09h                             ;|
                mov dx, offset atoi_error_msg           ;|print(atoi_error_msg)
                int 21h                                 ;|

                mov ax, 4c01h                           ;|
                int 21h                                 ;|exit(1)


                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               atoi
;------------------------------------------
;------------------------------------------
; Descr:
;       convert decimal string
;        to decimal integer
; Entry:
;       DS:SI   ; string memory addr
; Return:
;       BX = integer gotten from string
; Desroy:
;       AX, BX, SI
; Warning:
;       Scan string until <space> (20h)
; Error proc:
;       If string contains non decimal characters
;       Atoi will exit(1) with err msg
;------------------------------------------
atoi            proc

                xor bx, bx                              ; bx = 0
                cld                                     ; DF = 1 (++)

@@while:;-----------------------------------------------; while (CX != 0) {
                xor     ax, ax                          ;       ax = 0
                lodsb                                   ;       al = ds:[si++]

                cmp     ax, 20h                         ;|      if ax == <space>(20h): jmp end
                je      @@end                           ;|

                cmp     ax, 30h                         ;|      if (ax < '0') -> jmp error
                jl      @@error                         ;|

                cmp     ax, 39h                         ;|      if (ax > '9') -> jmp error
                jg      @@error                         ;|

                sub     ax, DIGITS_SHIFT                ;       'digit' -> digit ('3' -> 3)
                xchg    ax, bx                          ;       swap(ax, bx)
                mul     NUM_BASE                        ;|      ax = ax * 10     FIXME:(переписать на lea/сдвиги)
                add     bx, ax

                jmp     @@while
;-------------------------------------------------------; while end }

@@end:
                ret
@@error:
                mov ah, 09h                             ;|
                mov dx, offset atoi_error_msg           ;|print(atoi_error_msg)
                int 21h                                 ;|

                mov ax, 4c01h                           ;|
                int 21h                                 ;|exit(1)

                endp
;------------------------------------------
;##########################################

end start

