.model tiny
.186
locals @@

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
                mov     dx, offset split_text_error_msg  ;|print(split_text_error_msg)
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
                mov     RECT_WIDTH, bx                  ; RECT_WIDTH = bx
                sub     bx, 2d                          ;|
                mov     LABEL_RECT_WIDTH, bx            ;| LABEL_RECT_WIDTH = RECT_WIDTH - 2

                call    atoi_10                         ; bx(rect_height) = atoi_10(2nd arg)
                mov     RECT_HEIGHT, bx                 ; RECT_HEIGHT = bx
                sub     bx, 2                           ;|
                mov     LABEL_RECT_HEIGHT, bx           ;| LABEL_RECT_HEIGHT = RECT_HEIGHT - 2

                call    atoi_16                         ; bl = rect color attr
                mov     RECT_COLOR_ATTR, bl             ; RECT_COLOR_ATTR = bl
                call    input_rect_style

                call    tablet_centering

                mov     bx, CONSOLE_WIDTH               ;|
                inc     bx                              ;|
                shl     bx, 1d                          ;| LABEL_RECT_ADDR = RECT_ADDR + (CONSOLE_WIDTH + 1) * 2
                add     bx, RECT_ADDR                   ;|
                mov     LABEL_RECT_ADDR, bx             ;|

                push    si                              ; save last com arg addr
                mov     bx, VIDEOSEG
                mov     es, bx
                mov     di, RECT_ADDR
                mov     si, offset RECT_STYLE
                mov     cx, RECT_WIDTH
                mov     bx, RECT_HEIGHT
                mov     ah, RECT_COLOR_ATTR
                call    clear_screen
                call    draw_rect                       ;|draw_rect: ENTR(AH, DS:SI, BX, CX, ES:DI), DESTR(AX, SI)
                pop     si                              ; restore last com arg addr

                ; si - bias of user label string
                push    cs
                pop     es
                mov     di, offset STR_ARR
                mov     ax, LABEL_RECT_WIDTH
                call    split_text

                mov     dx, LABEL_RECT_HEIGHT
                mov     cx, LABEL_RECT_WIDTH
                mov     ax, VIDEOSEG
                mov     es, ax
                mov     di, LABEL_RECT_ADDR
                mov     ah, LABEL_COLOR_ATTR
                mov     si, offset STR_ARR
                call    print_string_arr





                mov     ax, 4c00h                       ;|
                int     21h                             ;| exit(0)


;##########################################
;               clear_screen
;------------------------------------------
;------------------------------------------
; Descr:
;       Clears screen
; Entry:
;       None
; Destr:
;       None
;------------------------------------------
clear_screen proc
                push ax bx cx dx

                mov ax, 0620h
                mov bx, 0h
                mov cx, 0h
                mov dx, 1998h
                int 10h

                pop dx cx bx ax

                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;             draw_n_chars
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws CX chars by addr ES:DI
; Entry:
;       AH      ; color attr
;       CX      ; string len
;       DS:SI   ; string memory addr
;       ES:DI   ; line beginning addr
; Desroy:
;       AL, BX, CX, SI, DI
;------------------------------------------
draw_n_chars    proc

                push    ax bx cx si di                  ; save regs

                cld                                     ; DF = 0 (++)
@@while:;-----------------------------------------------; while (CX != 0) {
                lodsb                                   ;       al = ds:[si++]
                stosw                                   ;       es:[di+=2] = ax
                dec     cx
                cmp     cx, 0h
                jne @@while
;-------------------------------------------------------; while end }
@@end:
                pop     di si cx bx ax                  ; restore regs

                ret
                endp
;------------------------------------------
;##########################################



;##########################################
;               print_string_arr
;------------------------------------------
;------------------------------------------
; Descr:
;           Print string_arr lines to ES:DI addr
; Entry:
;           DS:SI   -  string_arr addr (src)
;           ES:DI   -  dest addr
;           DX      -  lines cnt
;           CX      -  line length
;           AH      -  color attr
;
; Constants:
;           CONSOLE_WIDTH
;
; Desroy:   BX, SI, DI, DX
;------------------------------------------------------;
; WARNING:
;       this functions work with UCSD Strings (Pascal strings)
;       if your string isn't this format, the first byte of
;       every line will be not displayed
;------------------------------------------------------;
print_string_arr proc

@@while:

                mov     bl, [si]                        ; string_arr[0] - len of line

                inc     si
                call    draw_n_chars
                dec     si

                add     si, cx
                inc     si
                add     di, CONSOLE_WIDTH * 2d

                dec     dx
                cmp     dx, 0d
                jne     @@while

                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;           input_rect_style
;------------------------------------------
;------------------------------------------
; Descr:
;       scan rect style mode from comand line args (PSP)
;       if mode == 0 -> scan user style string into RECT_STYLE
;       else -> copy built-in style into RECT_STYLE
;       after execution, SI will point to the next command line argument
; Entry:
;       DS:SI   - style mode addr in PSP
; Desroy:
;       AX, BX, CX, SI, DI, ES
;------------------------------------------
input_rect_style proc
                call    atoi_10                         ; bx = style_mode(4rd arg)
                cmp     bx, 0
                je      @@scan_user_style
@@set_built_in_style:
                push    si

                dec     bx
                mov     si, BUILT_IN_STYLES[bx]

                push    cs
                pop     es
                mov     di, offset RECT_STYLE

                mov     cx, RECT_STYLE_LEN
                rep     movsw

                pop     si
                jmp     @@end

@@scan_user_style:
                push    cs
                pop     es
                mov     di, offset RECT_STYLE
                mov     cx, RECT_STYLE_LEN
                rep     movsw
@@end:
                ret
                endp
;------------------------------------------
;##########################################


;##########################################
;               draw_pattern_line
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
draw_pattern_line   proc
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
                push    bx cx di                            ; reg saving                                ;|

                call    draw_pattern_line                   ; call draw_pattern_line

                pop     di cx bx                            ; reg restore

                add     di, 160                             ;|next line
                sub     bx, 2                               ;|

@@while:;-----------------------------------------------; while (BX > 0) {
                push bx                                 ;|
                push cx                                 ;|      reg saving
                push di                                 ;|

                push si                                 ;       save pattern middle triad addr

                call draw_pattern_line                      ;       call draw_pattern_line

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

                call draw_pattern_line                      ; call draw_pattern_line

                pop di                                  ;|
                pop cx                                  ;|reg restoring
                pop bx                                  ;|

                ret
                endp
;------------------------------------------
;##########################################



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
;       DL      ; word end sim
;
; Desroy:
;       CX, DL
;------------------------------------------
scan_next_word  proc
                push    si ax                           ; reg save

                cld                                     ; DF = 0 (++)

                xor     cx, cx                          ; cx = 0
                xor     dx, dx                          ; dx = 0

@@while:;-----------------------------------------------; while (al != word end sim) {
                lodsb                                   ;       al = ds:[si++]
                mov     dl, al

                cmp     al, 20h                         ;|if ax == <space>(20h): jmp end

                je      @@end                           ;|

                cmp     al, LINE_BREAK_CHAR             ;|if ax == LINE_BREAK_CHAR: jmp end
                je      @@end                           ;|

                cmp     al, TEXT_END_CHAR
                je      @@end

                cmp     al, CARRIAGE_RET_CHAR           ;| if ax == <carriage return> (0Dh): jmp end
                je      @@end                           ;|

                inc     cx

                jmp     @@while
;-------------------------------------------------------; while end }
@@end:
                mov     dl, al
                pop     ax si                           ; reg restore
                ret
                endp
;------------------------------------------
;##########################################

;##########################################
;               split_text
;------------------------------------------
;------------------------------------------
; Descr:
;       Split text into lines in str_arr
;       Do line breaks if len of line > AX
;       if line break is impossible split_text will return error
;       if line cnt > str_arr_width split_text will return error
;
;       a line break character is stored in LINE_BREAK_CHAR constant
; Entry:
;       DS:SI       ; src text addr
;       ES:DI       ; output text array addr
;       AX          ; line length (should be < 128)
;
; Desroy:
;       AX, BX, CX, DX, SI, DI
;------------------------------------------
; WARNING:
;           words len should be less than 128
;           if you store addr of com line arg in ES
;            you should do extra check, that
;             com args len isn't zero and ES points to the text
;------------------------------------------
split_text      proc

                xor     dx, dx
                xor     bx, bx                          ; line_len
                inc     di                              ; string[0] = line_len

@@while:;-----------------------------------------------; while () {
                call    scan_next_word                  ;| cx - new word len
                cmp     dl, SPACE_CHAR                  ; if dl == ' ' -> cx++
                jne     @@word_proc
                inc     cx
@@word_proc:
                cmp     cx, ax                          ;|
                jg      @@error                         ;| if (cx > line_len) -> error

                add     bx, cx                          ;| bx += len(word)
                cmp     bx, ax                          ;| if (cur_line_len + len(word) > max_line_len) -> line_break
                jg      @@line_break                    ;|

                rep     movsb                           ;| while(cx--) : es:[di++] = ds:[si++]
                cmp     dl, SPACE_CHAR
                je      @@not_skip_end_sim
                inc     si
@@not_skip_end_sim:

                cmp     dl, LINE_BREAK_CHAR             ;| if line_break -> new_line
                je      @@new_line                      ;|

                cmp     dl, TEXT_END_CHAR               ;| if text end -> text end
                je      @@text_end

                cmp     dl, CARRIAGE_RET_CHAR           ;| if text end -> text end
                je      @@new_line

                jmp @@while

@@text_end:
                sub     bx, cx                          ; bx - char_idx before adding overflowing word
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len
                jmp     @@end

@@line_break:
                sub     bx, cx                          ; bx - char_idx before adding overflowing word
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len

                add     di, ax                          ; next_line
                inc     di
                inc     di

                xor     bx, bx

                jmp     @@word_proc


@@new_line:
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len

                add     di, ax                          ; next_line
                inc     di
                inc     di

                xor     bx, bx

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
;               tablet_centering
;------------------------------------------
;------------------------------------------
; Descr:
;       compute addr of left upper corner of center aligned rectangle
;       uses information from tablet data section
;       changes RECT_ADDR
; Entry:
;       CONSOLE_HEIGHT_BYTE
;       CONSOLE_WIDTH_BYTE
;       RECT_HEIGHT
;       RECT_WIDTH
; Destr: None
; Return:
;        RECT_ADDR
;------------------------------------------
; WARNING: RECT_HEIGHT, RECT_WIDTH should less than CONSOLE_HEIGHT_BYTE, CONSOLE_WIDTH_BYTE
;------------------------------------------
tablet_centering    proc

                push    ax bx cx di                  ; save registers
                xor     ax, ax                          ; ax = 0
                mov     bx, RECT_HEIGHT                 ; bx = RECT_HEIGHT
                mov     cx, RECT_WIDTH                  ; cx = RECT_WIDTH

                mov     al, CONSOLE_HEIGHT_BYTE              ;|
                sub     ax, bx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_HEIGHT_BYTE - bx) / 2 * 80 * 2
                mul     CONSOLE_WIDTH_BYTE                   ;|
                shl     ax, 1                           ;|

                mov     di, ax                          ; di = ax
                xor     ax, ax                          ; ax = 0

                mov     al, CONSOLE_WIDTH_BYTE               ;|
                sub     ax, cx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_WIDTH_BYTE - cx) / 2 * 2
                shl     ax, 1                           ;|

                add     di, ax                          ; di += ax.
                                                        ; di - addr of left upper corner of center aligned rectangle
                mov     RECT_ADDR, di                   ; RECT_ADDR = di

                pop     di cx bx ax                  ; regs resotre

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
;       <carriage return> (0Dh)
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

                stosw                                   ; es:[di+=2] = ax
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
ARGS_ADDR               equ 0082h
DEC_DIGITS_SHIFT        equ 30h
UPPERCASE_HEX_SHIFT     equ 37h
LOWERCASE_HEX_SHIFT     equ 57h
CONSOLE_SCROLLING_CNT   equ 2d
CONSOLE_WIDTH           equ 80d
CONSOLE_HEIGHT          equ 25d

VIDEOSEG                equ 0b800h
X_CORD                  equ 5d
Y_CORD                  equ 5d

DEC_NUM_BASE            db 10d
HEX_NUM_BASE            equ 16d

tablet_string           db 'Sweet February with Valentine!$'
atoi10_error_msg        db 'atoi10: string contains non-decimal characters$'
atoi16_error_msg        db 'atoi16: string contains non-hex characters$'
split_text_error_msg    db 'split_text: the word does not fit on the line$'

LINE_BREAK_CHAR         equ '@'
TEXT_END_CHAR           equ '&'
SPACE_CHAR              equ ' '

CARRIAGE_RET_CHAR db 0Dh, '$'
RS1 db "+=+|.|+=+$"
RS2 db "0-0I*I0-0$"

BUILT_IN_STYLES dw offset RS1, offset RS2


CONSOLE_WIDTH_BYTE      db CONSOLE_WIDTH
CONSOLE_HEIGHT_BYTE     db CONSOLE_HEIGHT
;##########################################
;           tablet info
;##########################################
RECT_STYLE_LEN          equ 9d
RECT_STYLE              dw  RECT_STYLE_LEN dup(?)
RECT_COLOR_ATTR         db  00h
RECT_HEIGHT             dw  0000h
RECT_WIDTH              dw  0000h
RECT_ADDR               dw  0000h
;##########################################


;##########################################
;           label info
;##########################################
LABEL_COLOR_ATTR        db  01001110b
LABEL_RECT_WIDTH        dw  0000h
LABEL_RECT_HEIGHT       dw  0000h
LABEL_RECT_ADDR         dw  0000h
STR_ARR_SZ              equ 1000h
STR_ARR                 db str_arr_sz dup(0h)
;##########################################




end start

