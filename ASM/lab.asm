;.386
PRINT_STRING MACRO params
                     push ax
                     mov  ah,09h
                     mov  dx,offset params
                     int  21h
                     pop  ax
ENDM

.model small

.data
        screen_hight            dw 200
        screen_width            dw 320
        color                   db 0fh                                                   ;white
        ground_color            db 06h                                                   ;brown
        charactor_init          dw 38440d                                                ;320*120+40,charactor(40*20)
        charactor_color         db 04h
        charactor_position      dw 38440d
        charactor_last_position dw 50940d
        exit_                   db 0h
        score                   dw 0h
        jump                    db 00h
        highest_score           dw 0h
        mesg_1                  db 'ESC to exit,Space jump and start',0ah,0Dh,'$'
        mesg_2                  db 'press Space to restart the game','$'
        score_output            db 'HI=',12 dup('0'),'$'
        end_game_over           db 01h
        ;obstacle position
        obstacle_init           dw 41899d                                                ;320*130+300 起始點
        obstacle_position       dw 0d,0d
        obstacle_color          db 00h                                                   ;black
        obstacle_number         dw 2d
        obstacle_position_index dw 0d

.stack 100h

.code
                  STORE_SCORE_DATA proto near c,arg:word,arg2:word        ;arg 分數 arg2偏移量
                  OBSTACLE         proto near c,arg:byte


        main:     
                  mov              ax,@data
                  mov              ds,ax
                  call             INIT_BACKGROUND
        ;call OUTPUT_SCORE
        GAME_LOOP:
.if end_game_over == 01h
                  call             OUTPUT_SCORE
   
                  PRINT_STRING     mesg_2
                  mov              dx,0000h
                  mov              score,dx
                  call             RESTART
                  call             INIT_BACKGROUND
                  cmp              exit_,01h
                  jz               exit_program
.endif
              call   RANDOM_OBSTACLE_GENERATE
              invoke OBSTACLE,obstacle_color
              mov    di,charactor_last_position
              mov    ah,obstacle_color
.if es:[di] == ah
              mov    end_game_over,01h
              jmp    GAME_LOOP
.endif
              call OUTPUT_SCORE
              inc  word ptr [score]
              xor  di,di
              xor  ah,ah
              call SPACE_ESC
              call OBSTACLE_MOVE
.if jump ==0h
              call DELAY2
              call DELAY2
.endif
                                cmp          exit_,01h
                                jnz          GAME_LOOP
        exit_program:           
                                call         INIT_SCREEN

                                mov          ax,4c00h
                                int          21h

        ;set the vedio segment 0a000h and go into mode 13h
INIT_BACKGROUND proc
                                push         ax
                                mov          ax,0a000h
                                mov          es,ax
                                mov          ax,0013h
                                int          10h
                                call         WRITE_SCREEN_BACKGROUND
                                call         WRITE_CHARACTOR
                                PRINT_STRING mesg_1
                                pop          ax
                                ret
INIT_BACKGROUND endp
        ;write the backgroud and the ground
WRITE_SCREEN_BACKGROUND PROC
                                push         ax
                                push         di
                                xor          di,di
                                mov          ah,color
        WRITE_BACKGROUND_LOOP:                                              ;background 0~320*200
                                mov          es:[di],ah
                                inc          di
                                cmp          di,320d*200d
                                jnz          WRITE_BACKGROUND_LOOP
                                xor          di,di
                                mov          di,320d*160d
                                mov          ah,ground_color
        WRITE_GROUND_LOOP:                                                  ;ground 320*160~320*200
                                mov          es:[di],ah
                                inc          di
                                cmp          di,320d*200d
                                jnz          WRITE_GROUND_LOOP
                                pop          di
                                pop          ax
                                ret
WRITE_SCREEN_BACKGROUND ENDP

        ;畫角色
WRITE_CHARACTOR proc
                                push         ax
                                push         di
                                push         cx
                                push         dx
                                xor          dx,dx
                                xor          cx,cx
                                xor          di,di
                                mov          di,charactor_position
                                mov          ah,charactor_color
                                mov          al,obstacle_color
        CHARACTOR_LOOP:         
.if es:[di] == al
                                mov          end_game_over,01h
.endif
              mov es:[di],ah
              inc di
              inc cx
.if cx < 20d
              jmp CHARACTOR_LOOP
.endif
                           xor  cx,cx
                           add  di,300d
                           inc  dx
                           cmp  dx,40d
                           jnz  CHARACTOR_LOOP
                           sub  di,300d
                           mov  charactor_last_position,di
                           pop  dx
                           pop  cx
                           pop  di
                           pop  ax
                           ret
WRITE_CHARACTOR endp
        ;清除舊的角色
WRITE_CHARACTOR_CL proc
                           push ax
                           push di
                           push cx
                           push dx
                           xor  dx,dx
                           xor  cx,cx
                           xor  di,di
                           mov  di,charactor_position
                           mov  ah,color
        CHARACTOR_LOOP_CL: 
                           mov  es:[di],ah
                           inc  di
                           inc  cx
.if cx < 20d
                           jmp  CHARACTOR_LOOP_CL
.endif
              xor cx,cx
              add di,300d
              inc dx
.if dx < 40d
              jmp CHARACTOR_LOOP_CL
.endif
                           pop  dx
                           pop  cx
                           pop  di
                           pop  ax
                           ret
WRITE_CHARACTOR_CL endp
        ;是否有跳躍或離開
SPACE_ESC proc
                           push ax
                           mov  ah,01h                ;掃描但不等待
                           int  16h
.if al==1bh
                           mov  exit_,01h
.elseif al==20h
                           mov  jump,01h
                           call CHARACTOR_JUMP
.endif
                       mov  ax,0c00h                        ;clear keyboard buffer
                       int  21h
                       pop  ax
                       ret
SPACE_ESC endp

        ;from 320*160 to 320*40
CHARACTOR_JUMP proc
                       push ax
                       push di
                       mov  bx,2560d                        ;8 lines
        JUMP_LOOP_UP:  
                       inc  word ptr [score]
                       call RANDOM_OBSTACLE_GENERATE
                       call WRITE_CHARACTOR_CL
                       call OBSTACLE_MOVE
                       sub  charactor_position,bx
                       call WRITE_CHARACTOR
                       call OUTPUT_SCORE
.if end_game_over == 01h
                       jmp  exit_jump
.endif
                       cmp  charactor_position,(320d*40d)+40
                       call DELAY
                       jnz  JUMP_LOOP_UP

        JUMP_LOOP_DOWN:
                       inc  word ptr [score]
                       call WRITE_CHARACTOR_CL
                       call OBSTACLE_MOVE
                       add  charactor_position,bx
                       call WRITE_CHARACTOR
                       call OUTPUT_SCORE
.if end_game_over == 01h
                       jmp  exit_jump
.endif
                       cmp  charactor_position,38440d
                       call DELAY
                       jnz  JUMP_LOOP_DOWN
                       mov  jump,00h
        exit_jump:     
                       pop  di
                       pop  ax
                       ret
CHARACTOR_JUMP endp
        ;DELAY cx:dx microsecond
DELAY PROC
                       push ax
                       push dx
                       push cx
                       mov  ax,8600h
                       mov  cx,0000h
                       mov  dx,06fffh
                       int  15h
                       pop  cx
                       pop  dx
                       pop  ax
                       ret
DELAY ENDP
        ;DELAY2 cx:dx microsecond
DELAY2 PROC
                       push ax
                       push dx
                       push cx
                       mov  ax,8600h
                       mov  cx,0000h
                       mov  dx,04000h
                       int  15h
                       pop  cx
                       pop  dx
                       pop  ax
                       ret
DELAY2 ENDP

INIT_SCREEN proc
                       push ax
                       mov  ax,03h
                       int  10h
                       pop  ax
                       ret
INIT_SCREEN endp

RESTART proc
                       push ax
                       mov  charactor_position,38440d
                       mov  obstacle_position[0],0
                       mov  obstacle_position[2],0
                       mov  obstacle_number,0d
                       mov  obstacle_position_index,0d
                       mov  score,00h
                       mov  jump,00h
                       mov  ah,00h
                       int  16h
.if al == 20h
                       mov  end_game_over,00h
.elseif al == 1bh
                       mov  exit_,01h
.endif
                 mov  ax,0c00h              ;clear keyboard buffer
                 int  21h
                 pop  ax
                 ret
RESTART endp

OBSTACLE proc near c,color_arg:byte
                 push ax
                 push cx
                 push dx
                 push di
.if obstacle_number == 0
                 jmp  leave_obstacle
.endif
                            mov  cx,obstacle_number
                            mov  si,0
        obstacle_loop:      
                            push cx
                            mov  cx,0d
                            mov  dx,0d
                            mov  di,obstacle_position[si]
                            mov  ah,color_arg
        write_obstacle_loop:
                            mov  es:[di],ah
                            inc  di
                            inc  cx
.if cx < 20d
                            jmp  write_obstacle_loop
.endif
              xor cx,cx
              add di,300d
              inc dx
.if dx < 30d
              jmp write_obstacle_loop
.endif
                       add    si,2h
                       pop    cx
                       loop   obstacle_loop
        leave_obstacle:
                       pop    di
                       pop    dx
                       pop    cx
                       pop    ax
                       ret
OBSTACLE endp

        ;移動所有障礙物每次1d
OBSTACLE_MOVE proc
                       push   ax
                       push   cx
                       push   dx
                       push   si
                       mov    cx,obstacle_number
                       mov    si,0d
                       mov    ax,1d                                  ;each move shift
                       cmp    cx,0
                       jz     leave_move
                       invoke OBSTACLE,color
.if word ptr [obstacle_position] != 0000h
                       sub    word ptr [obstacle_position],ax
.endif
.if word ptr [obstacle_position+2] != 0000h
              sub word ptr [obstacle_position+2],ax
.endif
                               call   OBSTACLE_BOUNDARY
                               invoke OBSTACLE,obstacle_color
        leave_move:            
                               pop    si
                               pop    dx
                               pop    cx
                               pop    ax
                               ret
OBSTACLE_MOVE endp
        ;清除碰到邊界的障礙物
CLAER_OBSTACLE proc
                               push   ax
                               push   dx
                               push   di
                               mov    di,obstacle_position[0]
                               mov    ah,color
        write_obstacle_loop_cl:
                               mov    es:[di],ah
                               inc    di
                               inc    cx
.if cx < 20d
                               jmp    write_obstacle_loop_cl
.endif
              xor cx,cx
              add di,300d
              inc dx
.if dx < 30d
              jmp write_obstacle_loop_cl
.endif
                                 mov  obstacle_position[0],0d
                                 call SHIFT_OBSTACLE
                                 dec  word ptr [obstacle_number]
                                 sub  word ptr [obstacle_position_index],2d
                                 pop  di
                                 pop  dx
                                 pop  ax
                                 ret
CLAER_OBSTACLE endp

        ;用ivrine16的函式產生亂數，當亂數除41等於0時且障礙物數量(obstacle_number)不等於三時，再新增一個障礙物
RANDOM_OBSTACLE_GENERATE proc
                                 push ax
                                 push dx
                                 push bx
                                 push si
.if obstacle_number == 2                                                           ;最多兩個障礙物
                                 jmp  leave_generate
.endif
              mov ah,2ch
              int 21h                               ;CH:CL hour/min,DH:DL second:1/100second
              xor dh,dh
              add dx,70                             ;70~179
              xor cx,cx                             ;clear hour/min
              mov si,obstacle_position_index
.if obstacle_number != 0
              mov bx,obstacle_init
              sub bx,obstacle_position[si]
.else
             int 21h
             mov cx,dx
             xor ch,ch
.endif
        ;&& bx < 300d
.if dx > 160 && (bx > 250d) || (bx < 60d && bx > 30d) || cx==0
              mov bx,obstacle_init
              mov obstacle_position[si],bx
              inc word ptr [obstacle_number]
              add word ptr [obstacle_position_index],2d
.endif
        leave_generate:          
                                 pop  si
                                 pop  bx
                                 pop  dx
                                 pop  ax
                                 ret
RANDOM_OBSTACLE_GENERATE endp
        ;將obstacle_position前移一元素
SHIFT_OBSTACLE proc
                                 push ax
                                 mov  ax,obstacle_position[2]
                                 mov  obstacle_position[0],ax
                                 xor  ax,ax
                                 mov  obstacle_position[2],ax
                                 pop  ax
                                 ret
SHIFT_OBSTACLE endp

        ;如果obstacle_position[0]的位置除以320等於0則清除該obstacle並將剩餘兩個obstacle_position前移
OBSTACLE_BOUNDARY proc
                                 push ax
                                 mov  ax,obstacle_position[0]
.if ax < 41602d
                                 call CLAER_OBSTACLE
.endif
                          pop  ax
                          ret
OBSTACLE_BOUNDARY endp

OUTPUT_SCORE proc
                          push ax
                          push cx
                          push bx
                          push di
                          mov  dx,score
.if dx > highest_score
                          mov  highest_score,dx
.endif
                         mov          di,offset score_output
                         call         CLEAR_SCORE_DATA
                         mov          di,offset score_output
                         invoke       STORE_SCORE_DATA,score,3d
                         invoke       STORE_SCORE_DATA,highest_score,9d        ;加9因為中間有一個空格3(開頭)+5(score)+1(空格)
                         mov          dx,0119h                                 ;dh row dh colum
                         mov          ah,02h
                         int          10h
                         PRINT_STRING score_output
                         pop          di
                         pop          bx
                         pop          cx
                         pop          ax
                         ret
OUTPUT_SCORE endp
        ;清除output_score中儲存數值的地方
CLEAR_SCORE_DATA proc
                         push         ax
                         push         dx
                         push         cx
                         mov          cx,11d                                   ;;;設n+1個空格才能跑n個，尚不知道為甚麼
        clear_loop:      
                         mov          [di+3],' '
                         inc          di
                         loop         clear_loop
                         pop          cx
                         pop          dx
                         pop          ax
                         ret
CLEAR_SCORE_DATA endp

        ;arg1分數 arg2_ 偏移量
STORE_SCORE_DATA proc near c,arg1:word,arg2_:word
                         push         di
                         mov          ax,arg1
                         mov          si,arg2_
                         mov          cx,0
        Hex2Dec:         
                         inc          cx
                         mov          bx,10
                         mov          dx,0
                         div          bx
                         push         dx
                         cmp          ax,0
                         jne          Hex2Dec
                         add          di,si
        dec2Ascll:       
                         pop          ax
                         add          al,30h
                         mov          [di],al
                         inc          di
                         loop         dec2Ascll
                         pop          di
                         ret
STORE_SCORE_DATA endp
end main