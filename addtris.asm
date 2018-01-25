;******************************************************************************
;       addtris.asm
;
;       https://github.com/berk76/addtris
;       
;       Addtris is free software; you can redistribute it and/or modify
;       it under the terms of the GNU General Public License as published by
;       the Free Software Foundation; either version 3 of the License, or
;       (at your option) any later version. <http://www.gnu.org/licenses/>
;       
;       Written by Jaroslav Beran <jaroslav.beran@gmail.com>, on 23.1.2018
;
;       How to compile:
; 
;       tasm addtris
;       tlink addtris /t
;
;******************************************************************************

.model tiny        

.data

mesh_char       equ     '*'
mesh_pos_x      equ     30
mesh_pos_y      equ     1
mesh_width      equ     10
mesh_height     equ     20
wait_tck        equ     18

txt01   db      'ADDTRIS','$'
txt02   db      'GAME OVER','$'
txt03   db      'Score: ','$'
timer_d dw      wait_tck
timer   dw      ?
cur_xy  dw      ?
cur_ch  db      ?
score   dw      ?

.code
        org 100h
start:
        call    clrscr
        
        ;print addtris
        mov     dh,01h
        mov     dl,01h
        mov     cx,offset txt01
        call    print_text_at
        
        ;print mesh
        mov     cx,mesh_pos_y
        mov     al,mesh_char
pmesh1:
        mov     dh,cl
        mov     dl,mesh_pos_x
        call    print_char_at
        mov     dl,mesh_pos_x + mesh_width * 2 
        call    print_char_at
        inc     cx
        cmp     cx,mesh_pos_y + mesh_height + 1
        jne     pmesh1

        mov     dh,cl
        mov     cx, mesh_pos_x
pmesh2:        
        mov     dl,cl
        call    print_char_at
        inc     cx
        cmp     cx,mesh_pos_x + mesh_width * 2 + 1
        jne     pmesh2
        
        ;reset score
        mov     [score],0
        call    print_score
        
        ;set timer
        mov     ah,00h          ;get system timer
        int     1ah
        mov     [timer],dx      ;18.2/sec
        
        ;new number
go2:
        mov     [timer_d],wait_tck
        
        mov     dh,mesh_pos_y
        mov     dl,mesh_pos_x + mesh_width ; * 2 / 2
        mov     [cur_xy],dx
        xor     ax,ax 
        call    get_random      ;random num in al
        mov     bl,10
        div     bl              ;modulus in ah
        add     ah,'0'
        mov     [cur_ch],ah

        ;check if there is empty space
        mov     dx,[cur_xy]
        call    get_char_at
        cmp     al,' '
        jnz     go3
go1:
        mov     dx,[cur_xy]
        mov     al,[cur_ch]
        call    print_char_at
        
wwait:
        ;controls
        mov     ah,01h
        int     16h             ;ah = bios scan code, al = ascii
        jz     wwait1           ;no key pressed
        
        mov     ah,00h          ;remove keystroke from buffer
        int     16h             ;ah = bios scan code, al = ascii

        cmp     al,'q'
        je      addtris_end
        call    controls
        
wwait1:        
        ;wait
        mov     ah,00h          ;get system timer
        int     1ah
        mov     ax,[timer]
        add     ax,[timer_d]
        cmp     dx,ax
        jl      wwait
        mov     [timer],dx      ;18.2/sec
        
        ;check if there is empty space
        mov     dx,[cur_xy]
        inc     dh
        call    get_char_at
        cmp     al,' '
        jne     go4
                
        ;delete char
        mov     dx,[cur_xy]
        mov     al,' '
        call print_char_at
        
        ;increase position
        inc     dh
        mov     [cur_xy],dx
        
        jmp     go1
go4:
        call    check_score
        jmp     go2
go3:

        ;print game over
        mov     dh,12
        mov     dl,36
        mov     cx,offset txt02
        call    print_text_at
                
        ;wait a key
        mov     ah,08h          ;read char with no echo
        int     21h

addtris_end:        
        call    clrscr
        
        ;return control back to dos
        mov     ah,4ch          ;dos terminate program
        mov     al,00h          ;return code will be 0           
        int     21h
        
;*********************************
; Check score
;*********************************
check_score:
        mov     dx,[cur_xy]
        
        inc     dh
        call    get_char_at
        cmp     al,'0'
        jl      check_end
        cmp     al,'9'
        jg      check_end
        mov     ch,al
        sub     ch,'0'
        
        inc     dh
        call    get_char_at
        cmp     al,'0'
        jl      check_end
        cmp     al,'9'
        jg      check_end
        mov     cl,al
        sub     cl,'0'
        
        add     cl,ch
        xor     ax,ax
        mov     al,cl
        mov     bl,10
        div     bl
        mov     bl,[cur_ch]
        sub     bl,'0'
        cmp     ah,bl
        jne     check_end
        
        mov     al,[cur_ch]
        call    print_char_at
        dec     dh
        mov     al,' '
        call    print_char_at
        dec     dh
        call    print_char_at
        
        inc     [score]
        call    print_score
        
check_end:
        ret
        
;*********************************
; Print score
;*********************************
print_score:
        mov     dh,03h
        mov     dl,01h
        mov     cx,offset txt03
        call    print_text_at
        
        mov     ax,[score]
        call print_num_d
        
        ret

;*********************************
; Controls
;*********************************
controls:
        cmp     ah,48h
        je      key_up
        cmp     ah,4bh
        je      key_left
        cmp     ah,4dh
        je      key_right
        cmp     ah,50h
        je      key_down
controls_end:
        ret
key_up:
        mov     dl,[cur_ch]
        cmp     dl,'0'
        je      controls_end
        sub     dl,'0'
        mov     al,10
        sub     al,dl
        add     al,'0'
        mov     [cur_ch],al
        ;print char
        mov     dx,[cur_xy]
        call    print_char_at
        ret
key_left:
        ;check if there is empty space
        mov     dx,[cur_xy]
        dec     dl
        dec     dl
        call    get_char_at
        cmp     al,' '
        jnz     controls_end
        ;delete char
        mov     dx,[cur_xy]
        mov     al,' '
        call print_char_at
        ;print char
        dec     dl
        dec     dl
        mov     [cur_xy],dx
        mov     al,[cur_ch]
        call    print_char_at
        ret
key_right:
        ;check if there is empty space
        mov     dx,[cur_xy]
        inc     dl
        inc     dl
        call    get_char_at
        cmp     al,' '
        jnz     controls_end
        ;delete char
        mov     dx,[cur_xy]
        mov     al,' '
        call print_char_at
        ;print char
        inc     dl
        inc     dl
        mov     [cur_xy],dx
        mov     al,[cur_ch]
        call    print_char_at
        ret
key_down:
        mov     [timer_d],1
        ret

;*********************************
; Clear Screen
;*********************************
clrscr:
        mov     ah,05h  ;select active display page
        mov     al,01h
        int     10h

        mov     ah,02h  ;set cursor position
        mov     bh,01h  ;page number
        mov     dh,00h  ;row
        mov     dl,00h  ;column
        int     10h
        
        mov     cx,80*25
clrscr1:
        mov     ah,02h
        mov     dl,' '
        int     21h
        loop    clrscr1
        
        ret
        
;*********************************
; Print Text At
;*********************************
;dh=row
;dl=column
;cx=text
print_text_at:        
        mov     ah,02h  ;set cursor position
        mov     bh,01h  ;page number
        int     10h
        
        mov     ah,09h  ;print text
        mov     dx,cx
        int     21h     

        ret
        
;*********************************
; Print Char At
;*********************************
;dh=row
;dl=column
;al=char
print_char_at:
        push    ax
        push    bx
        push    dx
        
        mov     ah,02h  ;set cursor position
        mov     bh,01h  ;page number
        int     10h
        
        mov     ah,02h  ;print char
        mov     dl,al
        int     21h
        
        pop     dx
        pop     bx
        pop     ax
        
        ret
        
;*********************************
; Get Character From Position
;*********************************
;dh=row
;dl=column
;al=char
get_char_at:
        push    bx
        mov     ah,02h          ;set cursor position
        mov     bh,01h          ;page number
        int     10h
        
        mov     ah,08h          ;read al=character and ah=attr
        mov     bh,01h          ;page number
        int     10h
        pop     bx
        
        ret        
        
;*********************************
; Get Random Number
;*********************************
 ; get random number and
; store it off in al
get_random:
        push    dx
        mov     dx, 40h
        in      al, dx
        pop     dx
        
        ret
         
;*********************************
; Print decimal number
;*********************************
;ax=num
print_num_d:
        mov     cx,10000
        xor     si,si
print_loop:
        xor     dx,dx
        div     cx      ;result in ax, remain in dx
        
        cmp     cx,1    ;print cx == 1
        je      print_print
        cmp     al,0    ;print if al != 0
        jne     print_print
        cmp     si,0    ;print if already printed before
        je      print_div
print_print:
        mov     si,1    ;already printed
        push    dx
        mov     dl,al   ;print al
        add     dl,'0'
        mov     ah,02h
        int     21h
        pop     dx
print_div:        
        cmp     cx,1
        je      print_end
        mov     bx,10
        push    dx
        xor     dx,dx
        mov     ax,cx
        div     bx
        mov     cx,ax
        pop     ax
        jmp     print_loop
print_end:        
        ret
        
        end start
