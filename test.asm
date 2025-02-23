@@center_allign:
                mov     bx, bp
                sub     bx, LABEL_RECT_WIDTH
                neg     bx
                shr     bx, 1d
                shl     bx, 1d
                jmp     @@allign_end

@@right_allign:
                mov     bx, bp
                sub     bx, LABEL_RECT_WIDTH
                neg     bx
                shl     bx, 1d
                jmp     @@allign_end

