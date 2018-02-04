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

dsp_page        equ     00h
mesh_char       equ     '*'
mesh_pos_x      equ     30
mesh_pos_y      equ     1
mesh_width      equ     10
mesh_height     equ     20
wait_tck        equ     18

note_C          equ     4554
note_Cs         equ     4308
note_D          equ     4058
note_Ds         equ     3837
note_E          equ     3616
note_F          equ     3419
note_Fs         equ     3225
note_G          equ     3044
note_Gs         equ     2875
note_A          equ     2712
note_As         equ     2560
note_B          equ     2415


txt01   db      'ADDTRIS','$'
txt02   db      'GAME OVER','$'
txt03   db      'Score: ','$'
txt04   db      'Press a key...','$'
txt05   db      '              ','$'
txt06   db      'Controls:','$'
txt07   db      'Navig. ... arrows','$'
txt08   db      'Quit ..... q','$'
snd01   dw      note_C, 3, note_D, 3, note_E, 3, note_F, 3, note_G, 4, 0, 0
snd02   dw      note_G, 3, note_F, 3, note_E, 3, note_D, 3, note_C, 4, 0, 0
snd03   dw      note_F, 2, note_G, 2, 0, 0
timer_d dw      wait_tck
timer_l dw      ?
timer_h dw      ?
cur_xy  dw      ?
cur_ch  db      ?
score   dw      ?
cursor  dw      ?

.code
        org 100h
start:
        call    hide_cursor
        call    clrscr
        
        ;print addtris
        mov     dh,01h
        mov     dl,01h
        mov     cx,offset txt01
        call    print_text_at
        
        mov     dh,07h
        mov     dl,01h
        mov     cx,offset txt06
        call    print_text_at
        
        mov     dh,08h
        mov     dl,01h
        mov     cx,offset txt07
        call    print_text_at
        
        mov     dh,09h
        mov     dl,01h
        mov     cx,offset txt08
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

        ;play song
        mov     si,offset snd01
        call    play_song    
        
        ;press a key
        mov     dh,12
        mov     dl,34
        mov     cx,offset txt04
        call    print_text_at
        
        ;wait a key
        mov     ah,00h          ;remove keystroke from buffer
        int     16h             ;ah = bios scan code, al = ascii
        
        ;delete message
        mov     dh,12
        mov     dl,34
        mov     cx,offset txt05
        call    print_text_at
go2:        
        ;set timer
        mov     ah,00h          ;get system timer - 18.2/sec
        int     1ah             ;al 0 if timer has not overflowed past 24 hrs
                                ;cx,dx ticks from last reset cx is high, dx low
        mov     [timer_l],dx    ;dx is low
        mov     [timer_h],cx    ;cx is high
        
        ;new number
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
        
        ;should play note?
        mov     ax,[timer_d]
        cmp     ax,wait_tck
        jne     wwait
        
        ;wait for synchronization
        mov     ax,1            ;wait 1 tick
        call    wait_tcks
        
        ;play_note
        mov     bx,note_C       ;set note
        call    set_note
        mov     di,1            ;length of sound in ticks 
        call    play_note
        
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
        int     1ah             ;al 0 if timer has not overflowed past 24 hrs
                                ;cx,dx ticks from last reset cx is high, dx low
        mov     ax,[timer_l]
        mov     bx,[timer_h]
        add     ax,[timer_d]
        jnc     wwait2
        inc     bx
wwait2:
        cmp     cx,bx
        jl      wwait     
        cmp     dx,ax
        jl      wwait
        mov     [timer_l],dx    ;system timer low word
        mov     [timer_h],cx    ;system timer high word
        
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
        ;play song
        mov     si,offset snd02
        call    play_song
        
        ;print game over
        mov     dh,12
        mov     dl,36
        mov     cx,offset txt02
        call    print_text_at
                
        ;wait a key
        mov     ah,00h          ;remove keystroke from buffer
        int     16h             ;ah = bios scan code, al = ascii

addtris_end:        
        call    clrscr
        call    show_cursor
        
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
        
        ;play song
        mov     si,offset snd03
        call    play_song
        
        ;wait
        mov     ax,2            ;wait 2 ticks
        call    wait_tcks
        
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
        mov     ah,05h          ;select active display page
        mov     al,dsp_page
        int     10h

        mov     ah,02h          ;set cursor position
        mov     bh,dsp_page     ;page number
        mov     dh,00h          ;row
        mov     dl,00h          ;column
        int     10h
        
        mov     ah,09h          ;write char and attribute at cursor position
        mov     al,' '          ;character
        mov     bh,dsp_page     ;page number
        mov     bl,00000111b    ;attribute
        mov     cx,80*25        ;count of characters
        int     10h

        ret

;*********************************
; Print Text At
;*********************************
;dh=row
;dl=column
;cx=text
print_text_at:        
        mov     ah,02h          ;set cursor position
        mov     bh,dsp_page     ;page number
        int     10h
        
        mov     ah,09h          ;print text
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
        push    cx
        
        mov     cx,ax
        
        mov     ah,02h          ;set cursor position
        mov     bh,dsp_page     ;page number
        int     10h
        
        mov     ah,02h          ;print char
        mov     dl,cl
        int     21h
        
        pop     cx
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
        mov     bh,dsp_page     ;page number
        int     10h
        
        mov     ah,08h          ;read al=character and ah=attr
        mov     bh,dsp_page     ;page number
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
        mov     dx,40h
        in      al,dx
        mov     dx,[timer_l]
        xor     al,dl
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
        
;*********************************
; Hide cursor
;*********************************
hide_cursor:
        mov     ah,03h          ;get cursor position and shape
        int     10h
        mov     [cursor],cx     ;save start and end of scan line
        
        mov     ah,01h          ;set cursor shape
        mov     ch,20h
        int     10h
        
        ret

;*********************************
; Show cursor
;*********************************
show_cursor:
        mov     ah,01h          ;set cursor shape
        mov     cx,[cursor]
        int     10h
        
        ret
        
;*********************************
; Wait ticks
;*********************************
wait_tcks:
        ;ax = wait ticks
        push    bx
        push    cx
        push    dx
        push    si
        
        mov     si,ax
        
        ;read timer
wait_tcks_2:
        mov     ah,00h          ;get system timer - 18.2/sec
        int     1ah             ;al 0 if timer has not overflowed past 24 hrs
                                ;cx,dx ticks from last reset cx is high, dx low
        mov     bx,dx
        
        ;wait one tick
wait_tcks_1:
        mov     ah,00h          ;get system timer - 18.2/sec
        int     1ah             ;al 0 if timer has not overflowed past 24 hrs
                                ;cx,dx ticks from last reset cx is high, dx low
        cmp     bx,dx
        je      wait_tcks_1
        
        dec     si
        jnz     wait_tcks_2
        
        pop     si
        pop     dx
        pop     cx
        pop     bx
                
        ret
        
;*********************************
; Speaker
;*********************************
;
; We will setup particular countdouwn at timer 2 in order to produce
; specific frequency
;
;               1193180 
; COUNTDOWN = ---------
;             FREQUENCY
;
;
;  TABLE OF MUSICAL NOTE FREQUENCIES (Hz)
; ======================================
; Octave 0    1    2    3    4    5    6    7
; Note
; C     16   33   65  131  262  523 1046 2093
; C#    17   35   69  139  277  554 1109 2217
; D     18   37   73  147  294  587 1175 2349
; D#    19   39   78  155  311  622 1244 2489
; E     21   41   82  165  330  659 1328 2637
; F     22   44   87  175  349  698 1397 2794
; F#    23   46   92  185  370  740 1480 2960
; G     24   49   98  196  392  784 1568 3136
; G#    26   52  104  208  415  831 1661 3322
; A     27   55  110  220  440  880 1760 3520
; A#    29   58  116  233  466  932 1865 3729
; B     31   62  123  245  494  988 1975 3951
;
; First we have to tell timer 2 that we're about to load a new countdown value
; OUT 43h, B6h
;
; For example, if our low and high bytes are 54 and 124 then we do:
; OUT 42h, 54
; OUT 42h, 124
;
; Then we have to connect speaker to timer 2.
; To do this, we must set bits 0 and 1 of the value on port 61h on (or off).
; VALUE = IN( 61h )
; VALUE = VALUE OR 3      (Turn on bits 1 and 2)
; OUT 61h, VALUE


;*********************************
; Set note
;*********************************
set_note:
        ;bx = note countdown
        push    dx
        push    ax
        
        mov     dx,43h
        mov     al,0b6h
        out     dx,al           ;want to load new value to timer 2
        
        mov     dx,42h
        mov     al,bl
        out     dx,al           ;load low value of countdown
        mov     al,bh
        out     dx,al           ;load high value of countdown
        
        pop     ax
        pop     dx
        
        ret
        
;*********************************
; Play note
;*********************************
play_note:
        ;di = num of ticks
        push    dx
        push    ax
        push    cx
        push    bx
                
        ;set speaker on
        mov     dx,61h
        in      al,dx
        or      al,3            ;set bits 0 and 1 on
        out     dx,al           ;connect speaker to timer 2
        
        ;wait n ticks
        mov     ax,di
        call    wait_tcks
        
        ;set speaker off
        mov     dx,61h
        in      al,dx
        and     al,252          ;set bits 0 and 1 off
        out     dx,al           ;disconnect speaker to timer 2
        
        pop     bx
        pop     cx
        pop     ax
        pop     dx
        
        ret

;*********************************
; Play song
;*********************************        
play_song:
        ;si = offset song
        mov     bx,[si]         ;load note
        
        or      bx,0
        jz      play_song_1     ;end of song
        call    set_note
        inc     si
        inc     si
        
        mov     di,[si]         ;load wait ticks
        call    play_note
        inc     si
        inc     si
        jmp     play_song
        
play_song_1:        
        ret        
        
        end start
