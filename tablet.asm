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

CALL_DRAW_LABEL_ERROR_PROC macro
                mov     ah, 09h                          ;|
                mov     dx, offset label_error_msg       ;|print(atoi10_error_msg)
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
;        label align mode
;        label message
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

                call    atoi_16                         ;| bl = rect color attr
                mov     RECT_COLOR_ATTR, bl             ;| RECT_COLOR_ATTR = bl

                call    input_rect_style                ; input number of built-in style or user custom style pattern

                call    atoi_16                         ;| ALIGN_MODE: check draw label description
                mov     LABEL_ALIGN_MODE, bl            ;|

                call    tablet_centering                ;  centering tablet on the screen using CONSOLE_SCROLLING_DELTA

                mov     bx, CONSOLE_WIDTH               ;|
                inc     bx                              ;|
                shl     bx, 1d                          ;| LABEL_RECT_ADDR = RECT_ADDR + (CONSOLE_WIDTH + 1) * 2
                add     bx, RECT_ADDR                   ;|
                mov     LABEL_RECT_ADDR, bx             ;|

                push    si                              ; save last com arg addr
                mov     bx, VIDEOSEG                    ;|
                mov     es, bx                          ;|
                mov     di, RECT_ADDR                   ;| preparing args for draw_rect
                mov     si, offset RECT_STYLE           ;|
                mov     cx, RECT_WIDTH                  ;|
                mov     bx, RECT_HEIGHT                 ;|
                mov     ah, RECT_COLOR_ATTR             ;|
                call    clear_screen                    ;
                call    draw_rect                       ;|draw_rect: ENTR(AH, DS:SI, BX, CX, ES:DI), DESTR(AX, SI)
                pop     si                              ; restore last com arg addr

                ; si - bias of user label string        ;|
                push    cs                              ;|
                pop     es                              ;| preparing args for split_text
                mov     di, offset STR_ARR              ;|
                mov     ax, LABEL_RECT_WIDTH            ;|
                call    split_text                      ; split_text: ENTR(DS:SI, ES:DI, AX), RET(BP), DESTR(AX, BX, CX, DX, SI, DI, BP)

                ; bp - lines cnt
                mov     al, LABEL_ALIGN_MODE
                call    draw_label


                mov     ax, 4c00h                       ;|
                int     21h                             ;| exit(0)


;##########################################
;               draw_label
;------------------------------------------
;------------------------------------------
; Descr:
;       Draws text label in rectangle
; Entry:
;           LABEL_RECT_HEIGHT
;           LABEL_RECT_WIDTH
;           VIDEOSEG
;           LABEL_RECT_ADDR
;           LABEL_COLOR_ATTR
;           STR_ARR
;           AL                  ; aligning mode
;           BP                  ; lines cnt
;------------------------------------------------------------------
;           ->aligning mode (AL):
;           [x] 1st bit : if = 1 : aligning on the center
;           [x] 2nd bit : if = 1 : aligning on the right edge
;           [x] 3rd bit : <reserved>
;           [x] 4th bit : <reserved>
;           aligns on the left edge by default (1,2 bits = 0)
;           -----------
;           [x] 5th bit : if = 1 : aligning to the center height
;           [x] 6th bit : if = 1 : aligning to the bottom
;           [x] 7th bit : <reserved>
;           [x] 8th bit : <reserved>
;           aligns to the top by default (5,6 bits = 0)
;------------------------------------------------------------------
;
; Destr:
;       None
;------------------------------------------
draw_label proc
                cmp     bp, LABEL_RECT_HEIGHT
                jg      @@height_overflow_error

                mov     di, LABEL_RECT_ADDR             ; di - dst start

                mov     cx, ax                          ; save ax(align mode)
                xor     ax, ax                          ; prepare ax for calculations(ax = 0)


                test    cl, 00001000b
                jnz     @@center_align

                test    cl, 00000100b
                jnz     @@bottom_align

                jmp     @@top_align                     ; default align

@@center_align:
                mov     ax, bp                          ;|
                sub     ax, LABEL_RECT_HEIGHT           ;|
                neg     ax                              ;| ax = ((LABEL_RECT_HEIGHT - LINES_CNT) // 2) * CONSOLE_WIDTH * 2
                shr     ax, 1d                          ;|
                mul     CONSOLE_WIDTH_BYTE              ;|
                shl     ax, 1d                          ;|

                add     di, ax
                jmp     @@top_align

@@bottom_align:
                mov     ax, bp                          ;|
                sub     ax, LABEL_RECT_HEIGHT           ;|
                neg     ax                              ;| ax = (LABEL_RECT_HEIGHT - LINES_CNT) * CONSOLE_WIDTH * 2
                mul     CONSOLE_WIDTH_BYTE              ;|
                shl     ax, 1d                          ;|

                add     di, ax
                jmp     @@top_align
@@top_align:

                mov     ax, cx                          ; restore ax(align mode)

                mov     dx, LABEL_RECT_HEIGHT           ;|
                mov     cx, VIDEOSEG                    ;|
                mov     es, cx                          ;| preparing args for print_string_arr
                mov     cx, LABEL_RECT_WIDTH            ;|
                mov     ah, LABEL_COLOR_ATTR            ;|
                mov     si, offset STR_ARR              ;|
                call    print_string_arr                ;  ENTR(DS:SI, ES:DI, DX, CX, AX), Destr(BX, SI, DI, DX, BP)
                ret

@@height_overflow_error:
                CALL_DRAW_LABEL_ERROR_PROC

                endp
;------------------------------------------
;##########################################


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

                mov al, CONSOLE_HEIGHT_BYTE             ; al = CONSOLE_HEIGHT (number of lines to scroll)
                mov ah, 06h                             ; ah = 06 (scroll window)

                mov bx, 0h                              ; video attr

                mov cx, 0h                              ; CH, CL - row, clm of lower-right corner of rectangle to scroll blank
                mov dx, 1998h                           ; DH, DL - row, clm of upper-left corner of rectangle to scroll/blank

                int 10h                                 ; call videosrevices

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
                cmp     cx, 0h
                je      @@end

                lodsb                                   ;       al = ds:[si++]
                stosw                                   ;       es:[di+=2] = ax
                dec     cx
                jmp     @@while
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
;
;           Aligns string
;               to the center          if AL = 1000xxxxb
;               to the right side      if Al = 0100xxxxb
;               else to the left side
;
;
; Entry:
;           DS:SI   -  string_arr addr (src)
;           ES:DI   -  dest addr
;           DX      -  lines cnt
;           CX      -  line length
;           AL      -  aligning mode
;           AH      -  color attr
;
; Constants:
;           CONSOLE_WIDTH
;
; Desroy:   BX, SI, DI, DX, BP
;------------------------------------------------------;
; WARNING:
;       this functions work with UCSD Strings (Pascal strings)
;       if your string isn't this format, the first byte of
;       every line will be not displayed
;------------------------------------------------------;
print_string_arr proc

@@while:
                xor     bx, bx                          ; bx = 0
                mov     bl, [si]                        ; bx = string_arr[0] - len of line
                mov     bp, bx                          ; save cur line length
                xor     bx, bx                          ; bx = 0

                test    al, 10000000b
                jnz     @@center_allign
                test    al, 01000000b
                jnz     @@right_allign

                jmp     @@allign_left

@@center_allign:
                mov     bx, bp                          ;|
                sub     bx, LABEL_RECT_WIDTH            ;|
                neg     bx                              ;| bx = ((LABEL_RECT_WIDTH - LINE_LEN) // 2) * 2
                shr     bx, 1d                          ;|
                shl     bx, 1d                          ;|
                jmp     @@allign_left

@@right_allign:
                mov     bx, bp                          ;|
                sub     bx, LABEL_RECT_WIDTH            ;|
                neg     bx                              ;| bx = (LABEL_RECT_WIDTH - LINE_LEN) * 2
                shl     bx, 1d                          ;|
                jmp     @@allign_left


@@allign_left:

                inc     si                              ; skip pascal string first byte (str[0] = len)

                add     di, bx                          ; accounting alignment
                xchg    cx, bp                          ; save cx
                call    draw_n_chars
                xchg    cx, bp                          ; resore cx
                sub     di, bx                          ; restore di

                dec     si                              ; restore si

                add     si, cx                          ;| next line
                inc     si                              ;|
                add     di, CONSOLE_WIDTH * 2d          ;|
                dec     dx                              ;|

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
                push    si                              ; save si

                dec     bx                              ;|
                shl     bx, 1d                          ;| index praparing
                mov     si, BUILT_IN_STYLES[bx]

                push    cs                              ;|
                pop     es                              ;|
                mov     di, offset RECT_STYLE           ;| copy actual rect style to RECT_STYLE
                mov     cx, RECT_STYLE_LEN              ;|
                rep     movsb                           ;|

                pop     si
                jmp     @@end

@@scan_user_style:
                push    cs                              ;|
                pop     es                              ;|
                mov     di, offset RECT_STYLE           ;| copy actual rect style to RECT_STYLE
                mov     cx, RECT_STYLE_LEN              ;|
                rep     movsb                           ;|
                inc     si                              ; skip space
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
; Return:
;       BP          ; lines cnt
; Desroy:
;       AX, BX, CX, DX, SI, DI, BP
;------------------------------------------
; WARNING:
;           words len should be less than 128
;           if you store addr of com line arg in ES
;            you should do extra check, that
;             com args len isn't zero and ES points to the text
;------------------------------------------
split_text      proc

                xor     bp, bp
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
                je      @@text_end

                jmp @@while

@@text_end:
                sub     bx, cx                          ; bx - char_idx before adding overflowing word
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len
                inc     bp
                jmp     @@end

@@line_break:
                sub     bx, cx                          ; bx - char_idx before adding overflowing word
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len

                add     di, ax                          ; next_line
                inc     bp
                inc     di
                inc     di

                xor     bx, bx

                jmp     @@word_proc


@@new_line:
                sub     di, bx
                dec     di
                mov     es:[di], bl                     ; str_arr[0] - line len

                add     di, ax                          ; next_line
                inc     bp

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

                mov     al, CONSOLE_HEIGHT_BYTE         ;|
                sub     ax, bx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_HEIGHT_BYTE - bx) / 2 * 80 * 2
                mul     CONSOLE_WIDTH_BYTE              ;|
                shl     ax, 1                           ;|

                mov     di, ax                          ; di = ax
                xor     ax, ax                          ; ax = 0

                mov     al, CONSOLE_WIDTH_BYTE          ;|
                sub     ax, cx                          ;|
                shr     ax, 1                           ;| ax = (CONSOLE_WIDTH_BYTE - cx) / 2 * 2
                shl     ax, 1                           ;|

                add     di, ax                          ; di += ax.
                                                        ; di - addr of left upper corner of center aligned rectangle
                add     di, CONSOLE_SCROLLING_DELTA     ;
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

;##########################################
;           general constatns
;##########################################
ARGS_ADDR               equ 0082h
CONSOLE_WIDTH           equ 80d
CONSOLE_HEIGHT          equ 25d
CONSOLE_SCROLLING_DELTA equ (1 * CONSOLE_WIDTH) * 2
VIDEOSEG                equ 0b800h
;##########################################

;##########################################
;           atoi constatns
;##########################################
DEC_NUM_BASE            db 10d
HEX_NUM_BASE            equ 16d
DEC_DIGITS_SHIFT        equ 30h
UPPERCASE_HEX_SHIFT     equ 37h
LOWERCASE_HEX_SHIFT     equ 57h
;##########################################

;##########################################
;           string constatns
;##########################################
LINE_BREAK_CHAR         equ '@'
TEXT_END_CHAR           equ '&'
SPACE_CHAR              equ ' '
CARRIAGE_RET_CHAR db 0Dh, '$'
;##########################################

;##########################################
;                TMP
;##########################################
CONSOLE_WIDTH_BYTE      db CONSOLE_WIDTH
CONSOLE_HEIGHT_BYTE     db CONSOLE_HEIGHT
;##########################################

;##########################################
;           error messages
;##########################################
atoi10_error_msg        db 'atoi10: string contains non-decimal characters$'
atoi16_error_msg        db 'atoi16: string contains non-hex characters$'
split_text_error_msg    db 'split_text: the word does not fit on the line$'
label_error_msg         db 'draw_label: the text does not fit on the label box$'
;##########################################

;##########################################
;           tablet constatns
;##########################################
RS1 db "+=+|.|+=+$"
RS2 db "0-0I*I0-0$"
RS3 db "╔═╗║║.╚═╝$"
RS4 db "/^\!.!\_/$"
BUILT_IN_STYLES dw offset RS1, offset RS2, offset RS3, offset RS4
;##########################################

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
LABEL_ALIGN_MODE        db  00h
STR_ARR_SZ              equ 1000h
STR_ARR                 db str_arr_sz dup(0h)
;##########################################




end start

