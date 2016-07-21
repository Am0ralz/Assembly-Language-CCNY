;Angel Morales
;csc210      
;Fall2015
;This program changes the file from text format to base 85 
;---------Referecences----------: 
;http://www.dailyfreecode.com/tutorial/easy-assembly_language-49.aspx
;http://www.dcode.fr/ 
;http://stuff.pypt.lt/ggt80x86a/asm6.htm
;[Kip R. Irvine]Assembly Language for x86 Processors (7th Edition) (pdf){Zzzzz}

.Model Medium
.Stack 100h 
.386

.data
 
;----Buffer To Store Data----
OutBuff	DB 5 DUP(?)
InBuff    DB 5 DUP(?)
;------File Handle--------- 
OFilehandle DW ? 
Filehandle DW ?  ; to store file handle
;-----I/O File----------              
INPUTF  DB 100 dup(?)    ; file to be opened
OUTPUTF DB 100 dup(?)  ; file to be output 
;-------File Error------
T_Error DB "An error has occured(TailError)!$"
CreFile DB "File Created!$"
OpFile  DB "File Opened!$"
OpenError DB "An error has occured(opening)!$"
WriteError DB "An error has occured(writing)!$"
ReadError DB "An error has occured(readiing)!$"
CreateError DB "An error has occurred (CREATING)!$"             
  

.code 

main proc
;--COMMMAND TAIL -- chp.14.
  Mov ax, seg OUTPUTF
  Mov ds, ax
  
  Push es
  Pusha              ; save general registers 
     
  
  Mov ah , 62h       ; get PSP segment address
  Int 21h            ; returned in BX 
  Mov es , bx        ; copied to ES
  Mov di , 81h       ; PSP offset of command tail 
  Sub cx , cx        ; byte count 
  Mov cl , es:[di-1] ; get length byte 
  cmp cx , 0         ; is the tail empty? 
  je TailError       ; yes: exit
   
  Mov al,20h
  cld                ; scan in forward direction
  repz scasb         ; scan for non space 
  jz TailError       ; all spaces found 
  Dec di             ; non space found 
  Mov al,es:[di]     ; copy tail to buffer 
  cmp al,2dh
	jne L3
	jmp TailError
L3:
	stc
	pushf 
	
	
 CommandA:
   Mov al, 20h 
   cld 
   repz scasb 
   jz TailError
   Dec di
   
 Mov si, OFFSET INPUTF
 CommandB:
   Mov al,es:[di]
   Mov [si], al  
   Inc di  
   Inc si
   Mov al , es:[di]
   cmp al , 20h 
   jz CommandC
   jmp CommandB
     
  CommandC:
   Mov BYTE PTR [si], 0 
   
   Mov al , 20h
   Sub cx , di 
   repz scasb 
   jz TailError
   Dec di 
   
   Mov si, OFFSET OUTPUTF
    
  CommandD:
   Mov al, es:[di]
   Mov [si], al
   Inc di
   Inc si
   Mov AL , es:[di]
   cmp AL , 20h
   jz FTail
   cmp AL , 0Dh 
   jz FTail
   Loop CommandD
    
   FTail:
      Mov BYTE PTR [si],0
   Popf
   Popa
   Pop es 
  Pushf

;--OPEN INPUT FILE-- 
;http://stuff.pypt.lt/ggt80x86a/asm6.htm
  Mov ah,3Dh            ; function 3Dh -open a file
  Mov al,0              ; 0= read 
  sub cx,cx  
  Mov dx,OFFSET INPUTF   ; put adress of filename in dx
  Int 21h               ; call DOS service  
  jc ErrorOpening       ; jump if carry flag set - error!
  Mov Filehandle,ax     ; ax Holds handle ,save it for later
  Mov dx,OFFSET OpFile  ; Display open message on board
  Mov ah,09h            ; using funstion 09h
  Int 21h               ; call DOS service

;--CREATE OUTPUT FILE--
  Mov ah,3ch            ; function 3Ch - create a file
  sub al,al              
  sub cx,cx             ; clear cx - make ordinary file
  MOV dx,OFFSET OUTPUTF ; put offset of filename in dx 
  Int 21h               ; call DOS service 
  jc ErrorCreating      ; jump if there is an error 
  Mov OFilehandle, ax   ; ax Holds handle ,save it for later           
  Mov dx,OFFSET CreFile ; Display CREATE message on board
  Mov ah,09h            ; using funstion 09h
  Int 21h  	
	
  Popf
  ;Ret
  
  Mov OutBuff[0],200
  Mov dx,OFFSET OutBuff
  Mov ah,40h
  Mov cx,1
  Mov bx,OFilehandle
  Int 21h
 
 e64:
  Mov InBuff[0],0      
  Mov InBuff[1],0
  Mov InBuff[2],0
  Mov InBuff[3],0
  Mov ah,3fh
  Mov bx,Filehandle
  Mov dx, offset InBuff
  Mov cx, 4
  Int 21h
  cmp ax,0
  Mov cx,ax
  jz e64Done 
	
;--INPUT:4 CHARACTERS, OUTPUT:5 CHARACTERS 

;======get first out byte=====;
  Mov al,InBuff[0]
  Shr al,2
  add al,33
  Mov OutBuff[0],al
	
;======get fifth out byte====;	

  Mov al,InBuff[3]
  and al,63
  add al,33
  Mov OutBuff[4],al
;======get second out byte====;
	
  Mov al, InBuff[0]
  Mov ah, InBuff[1]
  Shl al,6
  shr al,1
  shr ah,3
  add al,ah
  add al,33
  Mov OutBuff[1],al
;======get third out byte====;	
	
  Mov ah, InBuff[1]
  Mov al, InBuff[2]
  shl ax, 5
  shr ax, 2
  add ah,33
  Mov OutBuff[2],ah 
;======get fourth out byte====;  
  Mov ah, InBuff[2]
  Mov al, InBuff[3]
  shl ax, 3
  shr ax, 1
  add ah,33
  Mov OutBuff[3],ah

	
	
;--WRITE TO FILE--	
  Mov ah,40h
  Mov bx,OFilehandle
  Mov dx,offset OutBuff
  add cx,1
  Int 21h
  jmp e64
e64Done:
 

;--CLOSE THE FILE--
  Mov ah, 3Eh             ; function 3Eh - close a file
  Mov bx, Filehandle      ; put file handle in bx
  Int 21h                 ; call DOS service
  Mov ah, 3Eh             ; function 3Eh - close a file
  Mov bx, OFilehandle     ; put file handle in bx
  Int 21h                 ; call DOS service
;--  

Exit:
  Mov ax,4Ch            ; end program with an errorlevel =1
  Int 21h
main endp
   
;*********** DEFINE ERROR MESSAGES *********** 
;http://stuff.pypt.lt/ggt80x86a/asm6.htm
  TailError:
  Mov dx,offset T_Error   ; display an Write error message
  Mov ah,09h              ; using funstion 09h
  Int 21h                 ; call DOS service
  Mov ax,4ch            ; end program with an errorlevel =1
  Int 21h
 
  
  
  
  
  ErrorWriting:
  Mov dx,offset WriteError; display an Write error message 
  Mov ah,09h              ; using funstion 09h
  Int 21h                 ; call DOS service 
  Mov ax,4Ch            ; end program with an errorlevel =1
  Int 21h                 ; call DOS service 
 
 
  ErrorReading:
  Mov dx,offset ReadError ; display an Read error message 
  Mov ah,09h              ; using funstion 09h
  Int 21h                 ; call DOS service 
  Mov ax,4Ch            ; end program with an errorlevel =1
  Int 21h                 ; call DOS service 
   
  ErrorCreating:
  Mov dx,offset CreateError ; display an error
  Mov ah,09h              ; using funstion 09h
  Int 21h                 ; call DOS service 
  Mov ax,4Ch            ; end program with an errorlevel =1
  Int 21h                 ; call DOS service
  
  ErrorOpening:
  
  Mov dx,offset OpenError ; display an error
  Mov ah,09h              ; using funstion 09h
  Int 21h                 ; call DOS service 
  Mov ax,4Ch            ; end program with an errorlevel =1
  Int 21h                 ; call DOS service
  
  
  
             
  
  END main