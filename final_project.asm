.386
;以下是螢幕顯示繪圖模式(setmode,setcolor)
character MACRO params        ;畫小恐龍的macro
    
ENDM

SetMode macro mode          ;設定顯示模式 13h繪圖 03h文字
            mov  ah,00h
            mov  al,mode
            int  10h
            pop  ax
endm

SetColor macro color          ;設定背景色
             push ax
             push bx
             mov  ah,0bh
             mov  bh,00h
             mov  bl,color
             int  10h
             pop  bx
             pop  ax
endm

.model small

.data

.stack 100h
.code
main proc
         mov ax,@data
         mov dx,ax


         mov ax,4c00h
         int 21h
main endp
end main