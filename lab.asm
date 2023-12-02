PRINT_STRING  MACRO params
    push ax
    mov ah,09h
    mov dx,offset params
    int 21h
    pop ax
ENDM

.model small

.data
    screen_hight dw 200
    screen_width dw 320
    score_offset equ screen_hight*screen_width
    color db 0fh    ;white
    ground_color db 06h;brown
    charactor_init dw 38420d ;320*120+40,charactor(40*20)
    charactor_color db 04h  
    charactor_position dw 38420d
    exit db 0h
    score dw 0h
    highest_score dw 0h
    mesg_1 db 'ESC to exit,Space jump and start',0ah,0Dh,'HI = ','$'
    mesg_2 db 0ah,0dh,'press Space to restart the game','$'
    end_game_over db 01h

.stack 100h

.code
main proc
    mov ax,@data
    mov ds,ax
    call INIT_BACKGROUND
GAME_LOOP:
.if end_game_over == 01h
    PRINT_STRING mesg_2
    call RESTART
    call INIT_BACKGROUND
    cmp exit,01h
    jz exit_program
.endif
    call SPACE_ESC
    cmp exit,01h
    jnz GAME_LOOP
exit_program:
    call INIT_SCREEN

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
    call WRITE_CHARACTOR
    PRINT_STRING mesg_1
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

;畫角色
WRITE_CHARACTOR proc
        push ax
        push di
        push cx
        push dx
        xor dx,dx
        xor cx,cx
        xor di,di
        mov di,charactor_position
        mov ah,charactor_color
CHARACTOR_LOOP:
        mov es:[di],ah
        inc di
        inc cx
    .if cx < 20d
        jmp CHARACTOR_LOOP
    .endif
        xor cx,cx
        add di,300d
        inc dx
    .if dx < 40d
        jmp CHARACTOR_LOOP
    .endif    
        pop dx
        pop cx
        pop di
        pop ax
        ret
WRITE_CHARACTOR endp
;清除舊的角色
WRITE_CHARACTOR_CL proc
        push ax
        push di
        push cx
        push dx
        xor dx,dx
        xor cx,cx
        xor di,di
        mov di,charactor_position
        mov ah,color
CHARACTOR_LOOP_CL:
        mov es:[di],ah
        inc di
        inc cx
    .if cx < 20d
        jmp CHARACTOR_LOOP_CL
    .endif
        xor cx,cx
        add di,300d
        inc dx
    .if dx < 40d
        jmp CHARACTOR_LOOP_CL
    .endif    
        pop dx
        pop cx
        pop di
        pop ax
        ret
WRITE_CHARACTOR_CL endp
;是否有跳躍或離開
SPACE_ESC proc
    push ax
    mov ax,0c00h;clear keyboard buffer
    int 21h
    mov ax,01h
    int 16h
.if al==1bh
    mov exit,01h
.elseif al==20h
    call CHARACTOR_JUMP
.endif
    pop ax
    ret
SPACE_ESC endp

;from 320*160 to 320*40
CHARACTOR_JUMP proc
    push ax
    push di
    ;mov ax,0013h
    ;int 10h
    mov bx,1280d;4 lines
JUMP_LOOP_UP:
    call WRITE_CHARACTOR_CL
    sub charactor_position,bx
    call WRITE_CHARACTOR
    cmp charactor_position,(320d*40d)+20
    call DELAY
    jnz JUMP_LOOP_UP
JUMP_LOOP_DOWN:
    call WRITE_CHARACTOR_CL
    add charactor_position,bx
    call WRITE_CHARACTOR
    cmp charactor_position,38420d
    call DELAY
    jnz JUMP_LOOP_DOWN
    pop di
    pop ax
    ret
CHARACTOR_JUMP endp
;description
DELAY PROC
    push ax
    push dx
    push cx
    mov ax,8600h
    mov cx,0000h
    mov dx,04000h
    int 15h
    pop cx
    pop dx
    pop ax
    ret
DELAY ENDP

INIT_SCREEN proc
        push ax
        mov ax,03h
        int 10h
        pop ax
        ret
INIT_SCREEN endp

RESTART proc
        push ax
        mov ah,00h
        int 16h
.if al == 20h
        mov end_game_over,00h 
.elseif al == 1bh
        mov exit,01h
.endif
        pop ax
        ret   
RESTART endp

ASCII_OUTPUT proc




ASCII_OUTPUT endp

OBASTCLE proc
        push ax


OBASTCLE endp
end main