.model small


.data
    screen_hight dw 200
    screen_width dw 320
    score_offset equ screen_hight*screen_width
    color db 0fh    ;white
    ground_color db 06h;brown
.stack 100h

.code
main proc
    mov ax,@data
    mov ds,ax
    call INIT_BACKGROUND

;test(press any key to exit)
    mov ax, 00h
    int 16h
    
    mov ax,4c00h
    int 21h
main endp
;set the vedio segment 0a000h and go into mode 13h
INIT_BACKGROUND proc
    push ax
    mov ax,0a000h
    mov es,ax
    mov ax,0013h
    int 10h
    call WRITE_SCREEN_BACKGROUND
    pop ax
    ret
INIT_BACKGROUND endp
;write the backgroud and the ground
WRITE_SCREEN_BACKGROUND PROC
         push ax
         push di
         xor di,di
         mov ah,color
WRITE_BACKGROUND_LOOP:;background 0~320*200
         mov es:[di],ah
         inc di
         cmp di,320d*200d
         jnz WRITE_BACKGROUND_LOOP
        xor di,di
        mov di,320d*160d
        mov ah,ground_color
WRITE_GROUND_LOOP:;ground 320*160~320*200
        mov es:[di],ah
         inc di
         cmp di,320d*200d
         jnz WRITE_GROUND_LOOP
        pop di
        pop ax
        ret
WRITE_SCREEN_BACKGROUND ENDP
end main