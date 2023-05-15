DOSSEG
    .MODEL SMALL
    .STACK 32
    .DATA

encoded     DB  80 DUP(0)
temp        DB  '0x', 160 DUP(0)
fileHandler DW  ?
filename    DB  'in.txt', 0          ; Trebuie sa existe acest fisier 'in/in.txt'!
outfile     DB  'out/out.txt', 0        ; Trebuie sa existe acest director 'out'!
message     DB  80 DUP(0)
msglen      DW  ?
padding     DW  0
iterations  DW  0 

x           DW  ?
x0          DW  ?
xx0         DW  ?

a           DW  0
b           DW  0
prenume DB 'Cristian', 0
nume DB 'Coltan', 0
length_prenume DW 8
length_nume DW 6

sys_time DB 4 DUP(0)
xaux DW 2 DUP(0)
iteratii_padd DW ?

tabel DB 'Bqmgp86CPe9DfNz7R1wjHIMZKGcYXiFtSU2ovJOhW4ly5EkrqsnAxubTV03a=L/d', 0

    .CODE
    
START:
    MOV     AX, @DATA
    MOV     DS, AX

    CALL    FILE_INPUT                  ; NU MODIFICATI!
    
    CALL    SEED                        ; TODO - Trebuie implementata

    CALL    ENCRYPT                     ; TODO - Trebuie implementata
    
    CALL    ENCODE                      ; TODO - Trebuie implementata
    
                                        ; Mai jos se regaseste partea de
                                        ; afisare pe baza valorilor care se
                                        ; afla in variabilele x0, a, b, respectiv
                                        ; in sirurile message si encoded.
                                        ; NU MODIFICATI!
    MOV     AH, 3CH                     ; BIOS Int - Open file
    MOV     CX, 0
    MOV     AL, 1                       ; AL - Access mode ( Write - 1 )
    MOV     DX, OFFSET outfile          ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    CALL    WRITE                       ; NU MODIFICATI!

    MOV     AH, 4CH                     ; Bios Int - Terminate with return code
    MOV     AL, 0                       ; AL - Return code
    INT     21H

FILE_INPUT:
    MOV     AH, 3DH                     ; BIOS Int - Open file
    MOV     AL, 0                       ; AL - Access mode ( Read - 0 )
    MOV     DX, OFFSET filename         ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    MOV     AH, 3FH                     ; BIOD Int - Read from file or device
    MOV     BX, [fileHandler]           ; BX - File handler
    MOV     CX, 80                      ; CX - Number of bytes to read
    MOV     DX, OFFSET message          ; DX - Data buffer
    INT     21H
    MOV     [msglen], AX                ; Return: AX - number of read bytes

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H

    RET

SEED:
    MOV CX, [length_prenume]
    MOV SI, OFFSET prenume

FIND_A:
    MOV AL, [SI]
    CBW
    ADD a, AX
    INC SI
    LOOP FIND_A

    MOV AX, a

    MOV CX, [length_nume]
    MOV SI, OFFSET nume

FIND_B:
    MOV AL, [SI]
    CBW
    ADD b, AX
    INC SI
    LOOP FIND_B

    MOV AX, b

    MOV AX, 0

    MOV BL, 255
    CBW
    MOV AX, a
    DIV BL  ;imparte AX la BL, 
            ;in AH pune rest, in AL pune cat

    MOV AL, AH
    MOV AH, 0 
    MOV a, AX ;;salvam in a valoarea

    ;MOV DL, AH
    ;MOV AH, 2
    ;INT 21H

    MOV BL, 255
    CBW
    MOV AX, b
    DIV BL

    MOV AL, AH
    MOV AH, 0
    MOV b, AX ;;salvam in b valoarea

    ;MOV DL, AH
    ;MOV AH, 2
    ;INT 21H

    MOV     AH, 2CH                     ; BIOS Int - Get System Time
    INT     21H
                                        ; TODO1: Completati subrutina SEED
                                        ; astfel incat la final sa fie salvat
                                        ; in variabila 'x' si 'x0' continutul 
                                        ; termenului initial
    MOV sys_time, CH
    MOV sys_time + 1, CL
    MOV sys_time + 2, DH
    MOV sys_time + 3, DL
;folosim xaux si xaux + 2 pentru a stoca dx , respectiv ax

;CH * 3600
    MOV AX, 0
    MOV AL, [sys_time]
    MOV BX, 3600
    MUL BX
    MOV [xaux], DX
    MOV [xaux+2], AX

;CL * 60
    MOV AX, 0
    MOV AL, [sys_time+1]
    MOV BX, 60
    MUL BX

;CH * 3600 + CL * 60
    MOV DX, [xaux]
    ADD AX, xaux+2
    ADC DX, 0
    MOV[xaux],DX
    MOV[xaux+2],AX

;DH
    MOV AX, 0
    MOV AL, [sys_time+2]
    MOV DX, [xaux]
;CH * 3600 + CL * 60 + DH
    ADD AX, xaux+2
    ADC DX, 0
    MOV [xaux], DX
    MOV [xaux+2],AX

;(CH * 3600 + CL * 60 + DH) * 100
    MOV BX, 100
    MOV CX, DX
    MUL BX
    MOV [xaux+2], AX
    MOV [x0], DX
    MOV AX,CX
    MUL BX
    ADD DX, AX
    ADD DX, x0
    MOV [xaux], DX

;(CH * 3600 + CL * 60 + DH) * 100 + DL
    MOV AX, 0
    MOV DX, xaux
    MOV AL, [sys_time+3]
    ADD AX, xaux+2
    ADC DX, 0
    MOV [xaux], DX
    MOV [xaux+2],AX

;(CH * 3600 + CL * 60 + DH) * 100 + DL mod 255
    MOV CX, 255
    DIV CX
    MOV x0, DX
    MOV xx0, DX

;;;;test 1 pdf(Scut)
;MOV x0, 15h
;MOV xx0, 15h
;;;;

    MOV SI, OFFSET message
    MOV CX, msglen
    DEC CX ;facem msglen -1 iteratii

    MOV x, DX 
    ;MOV x, 15h ;- test 1 (Scut)

    MOV AX, 0
    MOV AL, [SI]
    MOV BX, [x]
    XOR AX, BX
    MOV [SI], AL
    INC SI

RANDD:
    MOV AX, [x0]
    MOV BX, a ;a ;62h- test 1(Scut) ;;a=40h-Cristian
    MUL BX

    MOV BX, b ;b ;233- test 1(Scut) ;;b=63h-Coltan
    ADD AX, BX

    MOV BX, 255
    DIV BX
    MOV [x], DX

    MOV AX, 0
    MOV AL, [SI]
    MOV BX, [x]
    XOR AX, BX
    MOV [SI], AL
    INC SI
    MOV x0, BX
    LOOP RANDD

    MOV AX,[xx0]
    MOV [x0],AX

    RET
ENCRYPT:
    MOV     CX, [msglen]
    MOV     SI, OFFSET message
                                            ; TODO3: Completati subrutina ENCRYPT
                                            ; astfel incat in cadrul buclei sa fie
                                            ; XOR-at elementul curent din sirul de
                                            ; intrare cu termenul corespunzator din
                                            ; sirul generat, iar mai apoi sa fie generat
                                            ; si termenul urmator
    RET
RAND: ;randd este implementata in subrutina SEED
    MOV     AX, [x]
                                            ; TODO2: Completati subrutina RAND, astfel incat
                                            ; in cadrul acesteia va fi calculat termenul
                                            ; de rang n pe baza coeficientilor a, b si a 
                                            ; termenului de rang inferior (n-1) si salvat
                                            ; in cadrul variabilei 'x'

    RET
ENCODE: ;encode este implementata in subrutina SEED

                                            ; TODO4: Completati subrutina ENCODE, astfel incat
                                            ; in cadrul acesteia va fi realizata codificarea
                                            ; sirului criptat pe baza alfabetului COD64 mentionat
                                            ; in enuntul problemei si rezultatul va fi stocat
                                            ; in cadrul variabilei encoded
    MOV AX, 0
    MOV BX, 0
    MOV CX, 0
    MOV DX, 0

    MOV AX, msglen
    MOV BX, 3
    DIV BX

    MOV [iteratii_padd], DX
    MOV padding, DX
    MOV iterations, AX
    MOV CX, AX

    CMP DX, 1
    JE PADDING2

    CMP DX, 2
    JE PADDING1

    JMP endd

    PADDING2:
    MOV SI, OFFSET message
    MOV AX, msglen

    ADD SI, AX
    MOV byte ptr [SI], 0
    MOV byte ptr [SI+1], 0
    INC AX
    INC AX
    MOV msglen, AX
    JMP endd 

PADDING1:
    MOV SI, OFFSET message
    MOV AX, msglen

    ADD SI, AX
    MOV byte ptr [SI], 0
    INC AX
    MOV msglen, AX
    JMP endd 

endd:
;loop cx = ax ;repetam loop ul de cate ori se imparte exact nr de caractere la 3
    MOV DI, OFFSET encoded
    MOV SI, OFFSET message

criptare_loop:
    MOV AL, [SI]
    AND AL, 252
    SHR AL, 2
    PUSH SI

    MOV SI, OFFSET tabel
    CBW 
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL
;pana aici am criptat bit 1
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 3
    SHL AL, 4

    INC SI
    MOV BL, [SI]
    AND BL, 240
    SHR BL, 4

    OR AL, BL
    PUSH SI
    
    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL
;pana aici am criptat bit 2
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 15
    SHL AL, 2

    INC SI
    MOV BL, [SI]
    AND BL, 192
    SHR BL, 6

    OR AL, BL
    PUSH SI

    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL
;pana aici am criptat bit 3
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 63

    PUSH SI
    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL
;pana aici am criptat bit 4
    INC DI
    POP SI
    INC SI
LOOP criptare_loop

MOV DX, iteratii_padd
CMP DX, 0
JNZ criptare_padding

JMP fara_padd

criptare_padding: ;aici daca avem 000000 o sa inlocuim cu +
    MOV AX, iterations
    INC AX
    MOV iterations, AX
    MOV AX,0

    MOV AL, [SI]
    AND AL, 252
    SHR AL, 2
    PUSH SI

    MOV SI, OFFSET tabel
    CBW 
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL
;pana aici am criptat bit 1
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 3
    SHL AL, 4

    INC SI
    MOV BL, [SI]
    AND BL, 240
    SHR BL, 4

    OR AL, BL
    
    CMP AL, 0
    JE zero1

    PUSH SI
    
    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL

    JMP continue1
zero1:
    PUSH SI
    MOV [DI], 43

continue1:
;pana aici am criptat bit 2
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 15
    SHL AL, 2

    INC SI
    MOV BL, [SI]
    AND BL, 192
    SHR BL, 6

    OR AL, BL

    CMP AL, 0
    JE zero2

    PUSH SI

    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL

    JMP continue2
zero2:
    PUSH SI
    MOV [DI], 43

continue2:
;pana aici am criptat bit 3
    INC DI
    POP SI

    MOV AL, [SI]
    AND AL, 63

    CMP AL, 0
    JE zero3

    PUSH SI
    MOV SI, OFFSET tabel
    CBW
    ADD SI, AX
    MOV BL, [SI]

    MOV [DI], BL

    JMP continue3
zero3:
    PUSH SI
    MOV [DI], 43

continue3:
;pana aici am criptat bit 4
    INC DI
    POP SI
    INC SI

fara_padd:

    RET

WRITE_HEX:
    MOV     DI, OFFSET temp + 2
    XOR     DX, DX

DUMP:
    MOV     DL, [SI]
    PUSH    CX
    MOV     CL, 4

    ROR     DX, CL
    
    CMP     DL, 0ah
    JB      print_digit1

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     next_digit

print_digit1:  
    OR      DL, 30h
    MOV     byte ptr [DI] ,DL

next_digit:
    INC     DI
    MOV     CL, 12
    SHR     DX, CL
    CMP     DL, 0ah
    JB      print_digit2

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     AGAIN

print_digit2:    
    OR      DL, 30h
    MOV     byte ptr [DI], DL

AGAIN:
    INC     DI
    INC     SI
    POP     CX
    LOOP    dump
    
    MOV     byte ptr [DI], 10
    RET

WRITE:
    MOV     SI, OFFSET x0
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21h

    MOV     SI, OFFSET a
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET b
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET x
    MOV     CX, 1
    CALL    WRITE_HEX    
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET message
    MOV     CX, [msglen]
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, [msglen]
    ADD     CX, [msglen]
    ADD     CX, 3
    INT     21h

    MOV     AX, [iterations]
    MOV     BX, 4
    MUL     BX
    MOV     CX, AX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET encoded
    INT     21H

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H
    RET
    END START