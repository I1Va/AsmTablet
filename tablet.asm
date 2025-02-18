.model tiny
.186
locals @@

.code
org 100h

;------------------------------------------
; Args:
;        rect width
;        rect height
;        color attr
;        style_mode
;                if (style_mode == 0) :
;                        style string
;        message
;------------------------------------------


start:
                mov     si, ARGS_ADDR                   ; si = 1st arg addr

                call    atoi_10                         ; bx = atoi_10(1st arg)
                mov     cx, bx                          ; cx(rect_width) = bx(atoi10 ret val)

                call    atoi_10                         ; bx(rect_height) = atoi_10(2nd arg)

                push    bx                              ; save bx(rect_height)
                call    atoi_16                         ;|


                mov     ah, bl                          ;| ah(color attr) = atoi(3rd arg)


                pop     bx                              ; restore bx(rect_height)

                push    bx                              ; save bx(rect_height)
                push    ax                              ; save ax(rect color attr)

                call    atoi_10                         ; bx = style_mode(4rd arg)
                cmp     bx, 0                           ;|if (bx == 0):
                je      USER_STYLE                      ;|      (5th arg = custom user style)
                dec     bx                              ;|else:
                add     bx, bx                          ;|      di - addr of style with index = (bx - 1)
                mov     di, bx                          ;|      (di = (bx - 1) * 2)


                mov     bp, si                          ;| save si (addr of current arg).
                                                        ;| I use mov, because push will cause confusion after USER_STYLE:

                mov     si, STYLES_ARR[di]              ; rect style pattern addr

USER_STYLE:
                mov     dx, VIDEOSEG                    ;|
                mov     es, dx                          ;|es = VIDEOSEG

                pop     ax                              ; restore ax(color attr)
                pop     bx                              ; restore bx(rect_height)

                call    align_cord_cmp                  ;|align_cord_cmp:
                                                        ;|      Entry: CONSOLE_HEIGH, CONSOLE_WIDTH, BX, CX
                                                        ;|      Return: DI
                                                        ;|      Destr: DI

                push    di                              ; save rect corner addr

                call    draw_rect                       ;|draw_rect:
                                                        ;|      Entry:   AH, DS:SI, BX, CX, ES:DI
                                                        ;|      Destroy: AX, SI

                pop     di                              ; restore rect corner addr
                mov     si, bp                          ; restore si(addr of current arg)
                mov     ah, 11001110b                   ; label color attr
                add     di, (80 * 2 + 2) * 2            ; DI = addr of label addr on screen

                call    draw_string                     ;|draw_string
                                                        ;|      Entry:    AH, DS:SI, ES:DI
                                                        ;|      Destroy:  AL, BX, CX, SI, DI

                mov ax, 4c00h                           ;|
                int 21h                                 ;| exit(0)


;##########################################
;               scan_next_word
;------------------------------------------
;------------------------------------------
; Descr:
;       Scan word by DS:SI addr
;       Return it's length
;       Return word terminating sim
; Entry:
;       DS:SI   ; src text addr
; Return:
;       CX      ; length of scaned word
;       DL      ; word terminating sim
;
; Desroy:
;       CX, DL
;------------------------------------------
scan_next_word  proc
                cld                                     ; DF = 0 (++)

                push    si ax
                cld                                     ; DF = 1 (++)
                xor     cx, cx
                xor     dx, dx
@@while:;-----------------------------------------------; while (al != 0) {
                xor     ax, ax                          ;       ax = 0
                lodsb                                   ;       al = ds:[si++]

                cmp     al, 20h                         ;|if ax == <space>(20h): jmp end
                je      @@end                           ;|

                cmp     al, LINE_BREAK_CHAR             ;|if ax == LINE_BREAK_CHAR: jmp end
                je      @@end                           ;|

                cmp     al, TEXT_END_CHAR
                je      @@end

                cmp     al, CARRIAGE_RET_CHAR            ;|if ax == <carriage return> (0Dh): jmp end
                je      @@end                           ;|

                inc     cx
                jmp     @@while
;-------------------------------------------------------; while end }
@@end:
                mov     dl, al
                pop     ax si
                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               memncpy
;------------------------------------------
;------------------------------------------
; Descr:
;       copy word of len=CX from DS:SI to ES:DI
;
; Entry:
;       CX      ; word len
;       DS:SI   ; src addr
;       ES:DI   ; dest addr
; Desroy:
;       CX
;------------------------------------------
memncpy         proc

                push ax si
                cld                                     ; DF = 0 (++)

@@while:;-----------------------------------------------; while (CX != 0) {
                lodsb                                   ;       al = ds:[si++]
                stosw                                   ;       es:[di++] = ax
                loop @@while
;-------------------------------------------------------; while end }
                pop si ax
                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               split_text
;------------------------------------------
;------------------------------------------
; Descr:
;       Split text into lines in string_arr
;       Do line breaks if len of line > CX
;       if line break is impossible split_text will return error
;       if line cnt > string_arr_width split_text will return error
;
;       a line break character is stored in LINE_BREAK_CHAR constant
; Entry:
;       DS:SI       ; src text addr
;       ES:DI       ; output text array addr
;       AX          ; line length (should be < 128)
;
; Desroy:
;       ?
;------------------------------------------
split_text      proc

                mov     bx, 1d                          ;| bx - cur word string index, string[0] = len_of_line
                xor     dx, dx
@@while:;-----------------------------------------------; while (Al != 0) {
                cmp     dl, TEXT_END_CHAR
                je      @@end

                call    scan_next_word                  ;| cx - new word len
                inc     cx                              ;| (including space char)

                cmp     cx, ax                          ;|
                jg      @@error                         ;| if (cx > line len) -> error

                add     bx, cx                          ;| bx += len(word)
                cmp     bx, ax                          ;|
                jg      @@line_break                    ;| if (cur_line_pos > line_len) -> line_break

                call    memncpy

                cmp     dl, LINE_BREAK_CHAR             ;| if line_break -> new_line
                je      @@new_line                      ;|

                cmp     dl, TEXT_END_CHAR               ;| if text end -> text end
                je      @@new_line

                jmp @@while

@@line_break:
                sub     bx, cx
@@new_line:
                sub     di, bx                          ;|
                dec     di                              ;|
                mov     es:[di], bx                     ;| string_arr[0] = len of line
                add     di, bx                          ;|
                inc     di                              ;|

                xchg    bx, ax                          ;|
                sub     bx, ax                          ;|
                xchg    bx, ax                          ;| line break
                add     di, bx                          ;| di += (ax - bx)
                mov     bx, 1d                          ;|

                add     bx, cx
                call    memncpy

                jmp     @@while
;-------------------------------------------------------; while end }
@@end:
                ret
@@error:
                CALL_SPLIT_TEXT_ERROR_PROC
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
; Destr:
;       AX, SI
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
;               align_cord_cmp
;------------------------------------------
;------------------------------------------
; Descr:
;       compute addr of left upper corner of center aligned rectangle
; Entry:
;
;       CONSOLE_HEIGH
;       CONSOLE_WIDTH
;       BX      - rectangle height
;       CX      - rectangle width
; Destr: DI
; Return:
;       DI - addr of left upper corner
;------------------------------------------
align_cord_cmp  proc
                push    ax                              ; save ax
                xor     ax, ax                          ; ax = 0

                mov     al, CONSOLE_HEIGH               ;|
                sub     ax, bx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_HEIGH - bx) / 2 * 80 * 2
                mul     CONSOLE_WIDTH                   ;|
                shl     ax, 1                           ;|

                mov     di, ax                          ; di = ax
                xor     ax, ax                          ; ax = 0

                mov     al, CONSOLE_WIDTH               ;|
                sub     ax, cx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_WIDTH - cx) / 2 * 2
                shl     ax, 1                           ;|

                add     di, ax                          ; di += ax.
                                                        ; di - addr of left upper corner of center aligned rectangle
                pop ax

                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               draw_string
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws a string by addr ES:DI untill
;       <space> (20h) or <carriage return> (0Dh)
; Entry:
;       AH      ; color attr
;       DS:SI   ; string memory addr
;       ES:DI   ; line beginning addr
; Desroy:
;       AL, BX, CX, SI, DI
;------------------------------------------
draw_string     proc
                cld                                     ; DF = 0 (++)
@@while:;-----------------------------------------------; while (CX != 0) {
                lodsb                                   ;       al = ds:[si++]

                cmp     al, CARRIAGE_RET_CHAR            ;|if ax == <carriage return>(0Dh): jmp end
                je      @@end

                stosw                                   ;       es:[di++] = ax
                jmp @@while
;-------------------------------------------------------; while end }
@@end:
                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               atoi_10
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
;       AX, BX, CX, SI
; Warning:
;       Scan string until <space> (20h) or <carriage return> (0Dh)
; Error proc:
;       If string contains non decimal characters
;       Atoi will exit(1) with err msg
;------------------------------------------
atoi_10         proc

                xor bx, bx                              ; bx = 0
                cld                                     ; DF = 1 (++)

@@while:;-----------------------------------------------; while (CX != 0) {
                xor     ax, ax                          ;       ax = 0
                lodsb                                   ;       al = ds:[si++]

                cmp     al, 20h                         ;|if ax == <space>(20h): jmp end
                je      @@end                           ;|

                cmp     al, CARRIAGE_RET_CHAR           ;|if ax == <carriage return>(0Dh): jmp end
                je      @@end                           ;|

                ATOI_CHECK_DECIMAL_CHAR

                sub     ax, DEC_DIGITS_SHIFT            ;       'digit' -> digit ('3' -> 3)

                xchg    ax, bx                          ;       swap(ax, bx)
                mul     DEC_NUM_BASE                    ;|      ax = ax * 10     FIXME:(переписать на lea/сдвиги)
                add     bx, ax

                jmp     @@while
;-------------------------------------------------------; while end }

@@end:
                ret
@@error:
                CALL_ATOI_10_ERROR_PROC
                endp
;------------------------------------------
;##########################################




;##########################################
;               atoi_16
;------------------------------------------
;------------------------------------------
; Descr:
;       convert hexadecimal string
;        to hexadecimal integer
; Entry:
;       DS:SI   ; string memory addr
; Return:
;       BX = integer gotten from string
; Desroy:
;       AX, BX, CX, SI
; Warning:
;       Scan string until <space> (20h) or <carriage return> (0Dh)
; Error proc:
;       If string contains non decimal characters
;       Atoi will exit(1) with err msg
;------------------------------------------
atoi_16         proc

                xor bx, bx                              ; bx = 0
                cld                                     ; DF = 1 (++)

@@while:;-----------------------------------------------; while (CX != 0) {
                xor     ax, ax                          ;       ax = 0
                lodsb                                   ;       al = ds:[si++]

                cmp     al, 20h                         ;|if ax == <space>(20h): jmp end
                je      @@end                           ;|

                cmp     al, CARRIAGE_RET_CHAR           ;|if ax == <carriage return>(0Dh): jmp end
                je      @@end                           ;|

                ATOI_CHECK_HEX_CHAR


                cmp     al, 39h
                jle     @@digit_shift_proc

                cmp     al, 46h
                jle     @@uppercase_shif_proc

                cmp     al, 66h
                jle     @@lowercase_shif_proc


@@digit_shift_proc:
                sub     al, DEC_DIGITS_SHIFT            ; ASCII -> dec sim value
                jmp     @@general_result_proc           ;

@@uppercase_shif_proc:
                sub     al, UPPERCASE_HEX_SHIFT         ; ASCII -> hex upper case value
                jmp     @@general_result_proc

@@lowercase_shif_proc:
                sub     al, LOWERCASE_HEX_SHIFT         ; ASCII -> hex lower case value
                jmp     @@general_result_proc



@@general_result_proc:
                xchg    ax, bx                          ;       swap(ax, bx)
                shl     ax, 4                           ;|      ax = ax * 16
                add     bx, ax

                jmp     @@while
;-------------------------------------------------------; while end }

@@end:
                ret
@@error:
                CALL_ATOI_16_ERROR_PROC
endp
;------------------------------------------
;##########################################






.data

ATOI_CHECK_DECIMAL_CHAR macro
                cmp     al, 30h                         ;|if (ax < '0') -> jmp error
                jl      @@error                         ;|
                cmp     al, 39h                         ;|if (ax > '9') -> jmp error
                jg      @@error                         ;|
endm

ATOI_CHECK_HEX_CHAR macro
                cmp     al, 30h                         ;|if (al < '0') -> jmp error
                jl      @@error                         ;|

                cmp     al, 66h                         ;|if (ax > 'f') -> jmp error
                jg      @@error                         ;|


                cmp     al, 39h                         ;|if ('9' < al < 'A') -> jmp error
                jle     @@leter_check_upper_end         ;|
@@leter_check_upper:                                    ;|
                cmp     al, 41h                         ;|
                jl      @@error                         ;|
@@leter_check_upper_end:                                ;|


                cmp     al, 46h                         ;|if ('F' < al < 'a') -> jmp error
                jle     @@leter_check2_lower_end        ;|
@@leter_check_lower:                                    ;|
                cmp     al, 61h                         ;|
                jl      @@error                         ;|
@@leter_check2_lower_end:                               ;|
endm


CALL_ATOI_10_ERROR_PROC macro
                mov     ah, 09h                          ;|
                mov     dx, offset atoi10_error_msg      ;|print(atoi10_error_msg)
                int     21h                              ;|

                mov     ax, 4c01h                        ;|
                int     21h                              ;|exit(1)
endm
CALL_SPLIT_TEXT_ERROR_PROC macro
                mov     ah, 09h                          ;|
                mov     dx, offset atoi16_error_msg      ;|print(split_text_error_msg)
                int     21h                              ;|

                mov     ax, 4c01h                        ;|
                int     21h
endm

CALL_ATOI_16_ERROR_PROC macro
                mov     ah, 09h                          ;|
                mov     dx, offset atoi16_error_msg      ;|print(atoi16_error_msg)
                int     21h                              ;|

                mov     ax, 4c01h                        ;|
                int     21h                              ;|exit(1)
endm



ARGS_ADDR               equ 0082h
DEC_DIGITS_SHIFT        equ 30h
UPPERCASE_HEX_SHIFT     equ 37h
LOWERCASE_HEX_SHIFT     equ 57h
CONSOLE_WIDTH           db 80d
CONSOLE_HEIGH           db 25d
CONSOLE_SCROLLING_CNT   equ 2d

VIDEOSEG                equ 0b800h
X_CORD                  equ 5d
Y_CORD                  equ 5d

DEC_NUM_BASE            db 10d
HEX_NUM_BASE            equ 16d

tablet_string           db 'Sweet February with Valentine!$'
atoi10_error_msg        db 'atoi10: string contains non-decimal characters$'
atoi16_error_msg        db 'atoi16: string contains non-hex characters$'
split_text_error_msg    db 'split_text: the word does not fit on the line$'

LINE_BREAK_CHAR         db "@$"
TEXT_END_CHAR           db "&$"

CARRIAGE_RET_CHAR db 0Dh, '$'
RS1 db "+=+|.|+=+$"
RS2 db "0-0I*I0-0$"

STYLES_ARR dw offset RS1, offset RS2

string_arr_width        equ 100
string_arr_height       equ 30

string_arr db string_arr_width*string_arr_height dup(?)

end start

