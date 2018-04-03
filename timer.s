PINSEL0 EQU 0xE002C000
IOPIN EQU 0xE0028000
U0RBR EQU 0xE000C000
U0THR EQU 0xE000C000
U0IER EQU 0xE000C004
U0IIR EQU 0xE000C008
U0FCR EQU 0xE000C008
U0LCR EQU 0xE000C00C
U0LSR EQU 0xE000C014
U0SCR EQU 0xE000C01C
U0DLL EQU 0xE000C000
U0DLM EQU 0xE000C004
IO0DIR    EQU    0XE0028008
IO0SET    EQU    0XE0028004
IO0CLR    EQU    0XE002800C
; control words to configure UART
En_RxTx0 EQU 0x5
S_fmt EQU 0x83
S_fmt2 EQU 0x3
Speed EQU 97
    AREA Serial, CODE, READONLY
    EXPORT __main
__main BL SetupUART0
;--------To Display the characters to the screen
    LDR r0, =myString1
    LDRB r1, [r0],#1 ;load ASCII code of character
next1 BL CharOut_0 ; display on Serial#l
    LDRB r1, [r0],#1
    CMP r1, #0
    BNE next1
;--------To accept the characters from the keyboard
    MOV r0, #0x40000000
    MOV R7,#0
inptString BL CharIn_0 ; get serial input from Serial#l
    STRB r1, [r0],#1 ; put in safe place (memory)
    SUB R9,R1,#0X30
    CMP r1, #'*' ; check if input was *
    BNE sum ; repeat loop unless input was *
    BEQ OH
sum    MOV R7,R7,LSL#1
    ADD R8,R7,R7,LSL#2
    ADD R8,R8,R9
    MOV R7,R8
    CMP R1,#'*'
    BNE inptString
;--------To Display the characters of my string2 to the screen
loo    LDR r0, =myString2
    LDRB r1, [r0],#1 ;load ASCII code of character
next2 BL CharOut_0 ; display on Serial#l
    LDRB r1, [r0],#1
    CMP r1, #0
    BNE next2
;--------To Display the accepted string
    MOV r0, #0x40000000
    LDRB r1, [r0],#1
next3 BL CharOut_0
    LDRB r1, [r0],#1
    CMP r1, #"*"
    BNE next3
    B downc
; reset PINSEL0 occurs before UART output completes so add delay
    LDR r10, =0x8000 ;simple delay count value
delay SUBS r10, r10, #1 ;count down delay
    BNE delay ;loop until counted down delay
OH     B loo     
downc    LDR R1,=IO0DIR
        LDR R0,=0X00FF0000
        STR R0,[R1]
        LDR R2,=IO0SET
        LDR R3,=IO0CLR
repeat     MOV    R4,R7
        MOV R4,R4,LSL#16
NEXT    STR R4,[R2]
        LDR R5,=0XFF0000
delay1    SUBS R5,R5,#1
        BNE delay1
        STR R4,[R3]
        SUB R4,R4,#0X00010000
        CMP R4,#0X00000000
        beq STOP
        BNE NEXT
        B repeat
STOP    B STOP
;Set up all the SFRs for UART0 requirements only
SetupUART0 STMFD sp!, {lr} ;not strictly needed but be consistent
    LDR r4, =En_RxTx0 ;pattern to enable RxD0 and TXD0
    LDR r6, =PINSEL0 ;point to pin control register
    STR r4, [r6] ;set pins as Tx0 and Rx0
    LDR r3, =U0THR ;UART0 Base address
    LDR r5, =U0LCR ;UART0 LCR address
    MOV r4, #S_fmt ;for 8 bits, no Parity, 1 Stop bit
    STRB r4, [r5] ; set format in LCR
    MOV r4, #97 ;for 9600 Baud Rate @ l5MHz VPB Clock
    STRB r4, [r3] ;set baud rate
    MOV r4, #S_fmt2 ;set DLAB = 0 so addresses are . .
    STRB r4, [r5] ;.. now TX/RX buffers
    LDMFD sp!, {pc} ; return (could use MOV pc,lr)
;----------Output one character using serial port 0
CharOut_0 STMFD sp!, {lr} ;not strictly needed here
    LDR r3, =U0THR ;UART base address
    LDR r5, =U0LSR ;UART LSR address
wait_rdy LDRB r2, [r5] ;get UART status
    TST r2, #0x20 ;check for transmit buffer empty
    BEQ wait_rdy ;loop until TX buffer empty
    AND r1, r1,#0xFF ;ensure callee has only set byte
    STRB r1, [r3] ;load transmit buffer
    LDMFD sp! , {pc} ;return (could use MOV pc,lr)
;------------Wait for input of one character at serial port 0 then read it
CharIn_0 STMFD sp!, {lr} ; not strictly needed here
    LDR r3, =U0RBR ;UART base address
    LDR r5, =U0LSR ;UART base address
wait_rcd0 LDRB r2, [r5] ;get UART status
    TST r2, #0x1 ;check if receive buffer has something
    BEQ wait_rcd0 ;loop until RX buffer has value
    LDRB r1, [r3] ;get received value
    LDMFD sp!, {pc} ;could use MOV pc,lr
myString1 dcb "\n ENTER HEXADECIMAL DIGIT(0-F): ",0
myString2 dcb "\n DIGIT ENTERED IS ",0