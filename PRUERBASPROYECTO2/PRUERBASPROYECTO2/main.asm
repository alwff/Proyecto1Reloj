;******************************************************************
;
; Universidad del Valle de Guatemala 
; IE2023:: Programación de Microcontroladores
; Proyecto1.asm
; Autor: Alejandra Cardona 
; Proyecto: Proyecto1
; Hardware: ATMEGA328P
; Creado: 27/02/2024
; Última modificación: 14/03/2024
;
; Código de cambio de estados tomado de la clase del 22 de febrero, elaborado por Pablo Mazariegos.
;
;******************************************************************
; ENCABEZADO
;******************************************************************

.INCLUDE "M328PDEF.inc" 

;Definiendo etiqueta de estado:
.DEF ESTADO = R21 

.CSEG
.ORG 0x00 
JMP MAIN 

;Interrupción de estados
.ORG 0x0008 
JMP ISR_PCINT1 

;Interrupción timer 0
.ORG 0x0020   
JMP ISR_TIMER0_OVF 

;******************************************************************
; MAIN 
; STACK POINTER
;******************************************************************

MAIN: 
	LDI R16, LOW(RAMEND) 
	OUT SPL, R16 
	LDI R17, HIGH(RAMEND) 
	OUT SPH, R17 

;******************************************************************
; 
;		TABLA DE VALORES
; A	  B	  C	  D	  E	  F	  G 
; PD0 PD1 PD2 PD3 PD4 PD5 PD6
;
; DD - PD7
; 
;******************************************************************

SEG: .DB 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
; 0,1,2,3,4,5,6,7,8,9

;******************************************************************
; CONFIGURACIÓN 
;******************************************************************

SETUP: 

	LDI	R16, 0b0000_0000 ; Apagado
	STS	UCSR0B, R16 ; Deshabilita TX Y RX

	SBI PORTC, PC0 ; Habilita PULL-UP
	CBI DDRC, PC0 ; Habilita PC0 como entrada -- Boton1

	SBI PORTC, PC1 ; Habilita PULL-UP
	CBI DDRC, PC1 ; Habilita PC1 como entrada -- Boton2

	SBI PORTC, PC2 ; Habilita PULL-UP
	CBI DDRC, PC2 ; Habilita PC2 como entrada -- Boton3

	; Inicio de salidas 
	LDI R17, (1 << PC5)|(1 << PC4)|(1 << PC3) ; Habilita los pines definidos
	OUT DDRC, R17 ; Carga el valor al puerto deseado

	LDI R17, (1 << PD7)|(1 << PD6)|(1 << PD5)|(1 << PD4)|(1 << PD3)|(1 << PD2)|(1 << PD1)|(1 << PD0)
	OUT DDRD, R17

	LDI R17, (1 << PB5)|(1 << PB4)|(1 << PB3)|(1 << PB2)|(1 << PB1)|(1 << PB0)
	OUT DDRB, R17
	; Fin de salidas 

	CLR R16 
	CLR R17
	; Limpia registros usados para configurar pines

	; OUT PORTC, R16 

	LDI R16, (1 << PCINT10)|(1 << PCINT9)|(1 << PCINT8) ; PCINTX -- 8=PC0, 9=PC1, 10=PC2  
	STS PCMSK1, R16 ; Habilita PCINT en los pines PC8,PC9,PC10

	LDI R16, (1 << PCIE1) 
	STS PCICR, R16 ;  Habilita la ISR PCINT[14:8] --Pin Change Interrupt Control Reg

	CALL Init_T0 ; Inicializa timer0 

	SEI ; Habilita todas las interrupciones

	; Se limpian los registros
	LDI ESTADO, 0
	;R16 configuración de setup e interrupción de pulsador
	;R17 configuración de setup y contador del timer
	LDI R18, 0 ; Contador de timer0 para blink - 10ms
	LDI R19, 0 ; Revisa si está encedido o no PD7 (2 puntos del display)
	LDI R20, 0 ; Copia el valor del registro para out en el transistor
	;R21 definido como ESTADO
	LDI R22, 0 ; contador - unidad de hora
	LDI R23, 0 ; contador - unidad de minuto
	LDI R24, 0 ; contador - unidad de segundo
	LDI R25, 0 ; contador - decena de segundo
	LDI R26, 0 ; contador - decena de minuto
	LDI R27, 0 ; contador - decena de hora
	LDI R28, 0 ; contador 500 ms (2--1s)
	LDI R29, 0 ; valor de z
	LDI R30, 0 ; multiusos
	LDI R31, 0 ; 
	CLR R2 ; alarma - unidad de minuto
	CLR R3 ; alarma - decena de minuto
	CLR R4 ; alarma - unidad de hora
	CLR R5 ; alarma - decena de hora
	
;******************************************************************
; LOOP 
;******************************************************************

LOOP: 
	SBRS ESTADO, 0 ; Si el bit 0 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP ESTADO_XXX0  ; Si es 0, pasa a estado 0
	JMP ESTADO_XXX1 ; -- Si set, estado 1

;******************************************************************
; Selector de estados
;******************************************************************

ESTADO_XXX0: 
	SBRS ESTADO, 1 ; Si el bit 1 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP  ESTADO_XX00 ; Si 0
	JMP  ESTADO_XX10 ; -- Si 1 -- ;0;

ESTADO_XX00: 
	SBRS ESTADO, 2
	JMP ESTADO_X000
	JMP ESTADO_X100

ESTADO_X000:
	SBRS ESTADO, 3 
	JMP ESTADO_0000 ; Estado 0
	JMP ESTADO_1000 ; Estado 8

ESTADO_XXX1:
	SBRS ESTADO, 1 
	JMP ESTADO_XX01 
	JMP ESTADO_XX11

ESTADO_XX11: 
	SBRS ESTADO, 2 
	JMP ESTADO_X011 
	JMP ESTADO_X111 

ESTADO_X111: 
	SBRS ESTADO, 3 
	JMP ESTADO_0111 ; Estado 7
	;JMP ESTADO_1111 ; Estado 15, nop.
	JMP LOOP

;ESTADO_1111: ; Estado 15
;	NOP ; do nothing, solo son 9 estados [0:8]

ESTADO_XX10: ; -- ;0;
	SBRS ESTADO, 2 
	JMP ESTADO_X010 
	JMP ESTADO_X110 

ESTADO_X100: 
	SBRS ESTADO, 3 
	JMP ESTADO_0100 ; Estado 4
	;JMP ESTADO_1100 ; Estado 12
	JMP LOOP

ESTADO_XX01:
	SBRS ESTADO, 2 
	JMP ESTADO_X001 
	JMP ESTADO_X101

ESTADO_X001: 
	SBRS ESTADO, 3 
	JMP ESTADO_0001 ; Estado 1
	;JMP ESTADO_1001 ; Estado 9
	JMP LOOP

ESTADO_X010: 
	SBRS ESTADO, 3 
	JMP ESTADO_0010 ; Estado 2
	;JMP ESTADO_1010 ; Estado 10
	JMP LOOP

ESTADO_X011: 
	SBRS ESTADO, 3 
	JMP ESTADO_0011 ; Estado 3
	;JMP ESTADO_1011 ; Estado 11
	JMP LOOP

ESTADO_X101: 
	SBRS ESTADO, 3 
	JMP ESTADO_0101 ; Estado 5
	;JMP ESTADO_1101 ; Estado 13
	JMP LOOP

ESTADO_X110: 
	SBRS ESTADO, 3 
	JMP ESTADO_0110 ; Estado 6
	;JMP ESTADO_1110 ; Estado 14
	JMP LOOP

;******************************************************************
; Función de estados
;******************************************************************
LOOPI: 
	SBRS ESTADO, 0 ; Si el bit 0 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP ESTADO_XXX0  ; Si es 0, pasa a estado 0
	JMP ESTADO_XXX1 ; -- Si set, estado 1

ESTADO_0000: ; Estado 0
	CBI PORTC, PC4 ; azul - no blink - apagado
	SBI PORTC, PC5 ; Estado 0 rojo - no blink - encedido
	CALL U_SEG
	CALL D_SEG
	CALL U_MIN
	CALL D_MIN
	CALL U_HORA
	CALL D_HORA

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE LOOPI 
	CLR R18
	;SBI PINC, PC4 ; azul - blink
	;SBI PINC, PC5 ; rojo - blink
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

; CAMBIO DE HORA AUTOMÁTICO
	INC R28
	CPI R28, 2 ; 1000 ms 
	BRNE LOOPI 
	CLR R28

	;Unidades de segundo
	INC R24 ; Registro para unidades de segundos
	CPI R24, 10 ; Al llegara a 9 seg
	BRNE LOOPI
	CLR R24

	;Decenas de segundo
	INC R25 ; Registro para decenas de segundos
	CPI R25, 6 ; Al llegara a 59 seg
	BRNE LOOPI
	CLR R25

	;Unidades de minuto
	INC R23 ; Registro para unidades de minutos
	CPI R23, 10 ; Al llegara a 9 minutos
	BRNE LOOPI
	CLR R23

	;Decenas de minuto
	INC R26 ; Registro para decenas de minutos
	CPI R26, 6 ; Al llegara a 59 minutos
	BRNE LOOPI
	CLR R26

	;Unidades de hora
	LDI R30, 2
	CPSE R30, R27
	JMP CONTADOR_1
	LDI R30, 3
	CPSE R30, R22
	JMP CONTADOR_1
	CLR R22
	CLR R27
	

	CONTADOR_1:
		INC R22 ; Registro para unidades de hora
		CPI R22, 10 ; Al llegara a 9 horas
		BRNE LOOPI
		CLR R22
		;Decenas de hora
		INC R27 ; Registro para decenas de hora
		JMP LOOP 

	; Comparador de alarma
	/*
	CPSE R23,R2 ; Compara unidades de minuto
	JMP LOOPI
	CPSE R26,R3 ; Compara decenas de minuto
	JMP LOOPI
	CPSE R22,R4 ; Compara unidades de hora
	JMP LOOPI
	CPSE R27,R5 ; Compara decenas de hora
	SBI PORTC, PC3 ; enciende buzzer
	*/
	JMP LOOP

ESTADO_0001: ; Estado 1
; Muestra fecha
	CBI PORTC, PC5; rojo - no blink - apagado
	SBI PINC, PC4 ; azul - fijo
	JMP LOOP 

LOOPI2: 
	SBRS ESTADO, 0 ; Si el bit 0 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP ESTADO_XXX0  ; Si es 0, pasa a estado 0
	JMP ESTADO_XXX1 ; -- Si set, estado 1

ESTADO_0010: ; Estado 2
; Muestra alarma
	SBI PORTC, PC5 ; Enciende PC5 - rojo	
	SBI PORTC, PC4 ; Enciende PC4 - azul
	; = Violeta fijo
	CALL U_MIN_ALARMA
	CALL D_MIN_ALARMA
	CALL U_HORA_ALARMA
	CALL D_HORA_ALARMA

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE LOOPI2
	CLR R18
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000	

	JMP LOOP

ESTADO_0011: ; Estado 3
; Configura hora
	CBI PORTC, PC4; azul - no blink - apagado
	CALL U_HORA
	CALL D_HORA

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_0011
	CLR R18
	;SBI PINC, PC4 ; azul - blink
	SBI PINC, PC5 ; rojo - blink
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP

ESTADO_0100: ; Estado 4
; Configura minutos
	CBI PORTC, PC4; azul - no blink - apagado
	CALL U_MIN
	CALL D_MIN

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_0100
	CLR R18
	;SBI PINC, PC4 ; azul - blink
	SBI PINC, PC5 ; rojo - blink
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP

ESTADO_0101: ; Estado 5
; Configura meses
	CBI PORTC, PC4; azul - no blink - apagado

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_0101
	CLR R18
	SBI PINC, PC4 ; azul - blink
	;SBI PINC, PC5 ; rojo - blink
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP

ESTADO_0110: ; Estado 6
; Configura días
	CBI PORTC, PC5; rojo - no blink - apagado
; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_0110
	CLR R18
	SBI PINC, PC4 ; azul - blink
	;SBI PINC, PC5 ; rojo - blink
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP 

ESTADO_0111: ; Estado 7
; Configura alarma-hora
	CALL U_HORA_ALARMA
	CALL D_HORA_ALARMA

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_0111
	CLR R18
	SBI PINC, PC4 ; azul - blink
	SBI PINC, PC5 ; rojo - blink
	;Violeta
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP

ESTADO_1000: ; Estado 8
; Configura alarma-minutos
	CALL U_MIN_ALARMA
	CALL D_MIN_ALARMA

; BLINK 
	CPI R18, 50 ; 500 ms
	BRNE ESTADO_1000
	CLR R18
	SBI PINC, PC4 ; azul - blink
	SBI PINC, PC5 ; rojo - blink
	;Violeta
	SBI PIND, PD7 ; blink 2 puntos

	SBIS PORTD, PD7 ; ¿está encendido PD7?
	LDI R19, 0b0000_0000
	SBIC PORTD, PD7 ; ¿está apagado PD7?
	LDI R19, 0b1000_0000

	JMP LOOP

;******************************************************************
; Interrupciones de estados
;******************************************************************

ISR_PCINT1: 
	PUSH R16 
	IN R16, SREG 
	PUSH R16 

	SBRS ESTADO, 0 ; Si el bit 0 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP ESTADO_XXX0_ISR  ; Si es 0, pasa a estado 0
	JMP ESTADO_XXX1_ISR ; -- Si set, estado 1

;******************************************************************
; Selector de estados
;******************************************************************

ESTADO_XXX0_ISR: 
	SBRS ESTADO, 1 ; Si el bit 1 del registro ESTADO está en set (1) entonces brinca una línea --
	JMP  ESTADO_XX00_ISR ; Si 0
	JMP  ESTADO_XX10_ISR ; -- Si 1 -- ;0;

ESTADO_XX00_ISR: 
	SBRS ESTADO, 2
	JMP ESTADO_X000_ISR
	JMP ESTADO_X100_ISR

ESTADO_X000_ISR:
	SBRS ESTADO, 3 
	JMP ESTADO_0000_ISR ; Estado 0
	JMP ESTADO_1000_ISR ; Estado 8

ESTADO_XXX1_ISR:
	SBRS ESTADO, 1 
	JMP ESTADO_XX01_ISR
	JMP ESTADO_XX11_ISR

ESTADO_XX11_ISR: 
	SBRS ESTADO, 2 
	JMP ESTADO_X011_ISR
	JMP ESTADO_X111_ISR

ESTADO_X111_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0111_ISR ; Estado 7
	;JMP ESTADO_1111_ISR ; Estado 15, nop.
	JMP ISR_POP

ESTADO_XX10_ISR: ; -- ;0;
	SBRS ESTADO, 2 
	JMP ESTADO_X010_ISR 
	JMP ESTADO_X110_ISR 

ESTADO_X100_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0100_ISR ; Estado 4
	;JMP ESTADO_1100_ISR ; Estado 12
	JMP ISR_POP

ESTADO_XX01_ISR:
	SBRS ESTADO, 2 
	JMP ESTADO_X001_ISR
	JMP ESTADO_X101_ISR

ESTADO_X001_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0001_ISR ; Estado 1
	;JMP ESTADO_1001_ISR ; Estado 9
	JMP ISR_POP

ESTADO_X010_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0010_ISR ; Estado 2
	;JMP ESTADO_1010_ISR ; Estado 10
	JMP ISR_POP

ESTADO_X011_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0011_ISR ; Estado 3
	;JMP ESTADO_1011_ISR ; Estado 11
	JMP ISR_POP

ESTADO_X101_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0101_ISR ; Estado 5
	;JMP ESTADO_1101_ISR ; Estado 13
	JMP ISR_POP

ESTADO_X110_ISR: 
	SBRS ESTADO, 3 
	JMP ESTADO_0110_ISR ; Estado 6
	;JMP ESTADO_1110_ISR ; Estado 14
	JMP ISR_POP

;******************************************************************
; Función de estados
;******************************************************************

ESTADO_0000_ISR: ; Estado 0
	; De estado 0 a 1
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	LDI ESTADO, 1 ; Pasa a estado 1

	; De estado 0 a 2
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	LDI ESTADO, 2 ; Pasa a estado 2

	; De estado 0 a 3
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 3 ; Pasa a estado 3

	JMP ISR_POP
	
ESTADO_0001_ISR: ; Estado 1
	; De estado 1 a 0 
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	LDI ESTADO, 0 ; Pasa a estado 0

	; De estado 1 a 2
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	LDI ESTADO, 2 ; Pasa a estado 2

	; De estado 1 a 5
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 5 ; Pasa a estado 5

	JMP ISR_POP

ESTADO_0010_ISR: ; Estado 2
	; De estado 2 a 0 
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 0 ; Pasa a estado 0

	; De estado 2 a 1
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	LDI ESTADO, 1 ; Pasa a estado 1

	; De estado 2 a 7
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	LDI ESTADO, 7 ; Pasa a estado 7

	JMP ISR_POP

ESTADO_0011_ISR: ; Estado 3
	; De estado 3 a 4 
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 4 ; Pasa a estado 4

	; Suma 
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	JMP IC_HORA ; Incrementa

	; Resta
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	JMP DC_HORA; Decrementa

	JMP ISR_POP

ESTADO_0100_ISR: ; Estado 4
	; De estado 4 a 0 
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 0 ; Pasa a estado 0

	; Suma 
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	JMP IC_MIN ; Incrementa

	; Resta
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	JMP DC_MIN; Decrementa

	JMP ISR_POP

ESTADO_0101_ISR: ; Estado 5
	; De estado 5 a 6 
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 6 ; Pasa a estado 6

	; Suma 

	; Resta

	JMP ISR_POP

ESTADO_0110_ISR: ; Estado 6
	; De estado 6 a 1 
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	LDI ESTADO, 1 ; Pasa a estado 1

	; Suma 

	; Resta

	JMP ISR_POP

ESTADO_0111_ISR: ; Estado 7
	; De estado 7 a 8
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	LDI ESTADO, 8 ; Pasa a estado 8

	; Suma 
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	JMP IC_HORA_ALARMA ; Incrementa

	; Resta
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	JMP DC_HORA_ALARMA ; Decrementa

	JMP ISR_POP

ESTADO_1000_ISR: ; Estado 8
	; De estado 8 a 2
	IN R16, PINC
	SBRS R16, PC0 ; Si P1 pulso down
	LDI ESTADO, 2 ; Pasa a estado 2

	; Suma 
	IN R16, PINC
	SBRS R16, PC1 ; Si P2 pulso down
	JMP IC_MIN_ALARMA ; Incrementa

	; Resta
	IN R16, PINC
	SBRS R16, PC2 ; Si P3 pulso down
	JMP DC_MIN_ALARMA ; Decrementa

	JMP ISR_POP


ISR_POP: 
	SBI PCIFR, PCIF1 ; Pin Change Interrupt Flag Register, Pin Change Interrupt Flag (Pin Change Interrupt Flag) 
	POP R16 
	OUT SREG, R16 
	POP R16 
	RETI

;******************************************************************
; TIMER0 
;******************************************************************

Init_T0: 
LDI R17, (1 << CS02)|(1 << CS00) ;config prescaler 1024 
OUT TCCR0B, R17 
LDI R17, 99 ;valor desbordamiento 
OUT TCNT0, R17 ; valor inicial contador 
LDI R17, (1 << TOIE0) 
STS TIMSK0, R17 
RET 

;Interrupción Overflow

ISR_TIMER0_OVF: 
LDI R17, 99 ; cargar el valor de desbordamiento 
OUT TCNT0, R17 ; cargar valor inicial 
SBI TIFR0, TOV0 ; borrar bandra TOV0 
INC R18 ; incrementar contador 10 ms 
RETI 

;******************************************************************
; SUBRUTINAS PARA HORA 
;******************************************************************

 U_SEG:
 ;unidades de segundos
	CBI PORTB, PB4 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R24
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB4 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29 ; Muestra segmentos
	
	LDI R20, 0b0010_0000
	OUT PORTB, R20 ; Muestra en la posicion del transistor seleccionado
	
	RET

D_SEG:
;decenas de segundos
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R25
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0001_0000
	OUT PORTB, R20

	RET

U_MIN:
;unidades de minutos
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R23
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_1000
	OUT PORTB, R20

	RET

D_MIN:
;decenas de minutos
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R26
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0100
	OUT PORTB, R20

	RET

U_HORA:
;unidades de hora
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB0

	MOV R29, R22
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0010
	OUT PORTB, R20

	RET

D_HORA:
;decenas de hora
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1

	MOV R29, R27
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0001
	OUT PORTB, R20

	RET

;;; Modificación de minutos ;;;

IC_MIN:
	;Unidades
	CPI R23, 9	; Compara el valor inmediato con el valor en el registro
	BRNE IC_U_MIN ; Si no se cumple la condición salta a IC_U_MIN
	CLR R23	; De lo contrario; al alcanzar el inmediato se limpia el registro

	;Decenas
	CPI R26, 5 ; Compara el valor inmediato con el valor en el registro
	BRNE IC_D_MIN ; Si no se cumple la condición salta a IC_D_MIN
	CLR R26 ; De lo contrario; al alcanzar el inmediato se limpia el registro

	JMP ISR_POP

DC_MIN:
	;Unidades
	CPI R23, 9	
	BRNE DC_U_MIN ; Si no se cumple la condición salta a DC_U_MIN
	CLR R23	

	;Decenas
	CPI R26, 5 
	BRNE DC_D_MIN ; Si no se cumple la condición salta a DC_D_MIN
	CLR R26 

	JMP ISR_POP

	IC_U_MIN: ; Incrementa unidades de minuto
		INC R23
		JMP ISR_POP
	IC_D_MIN: ; Incrementa decenas de minuto
		INC R26
		JMP ISR_POP
	DC_U_MIN: ; Decrementar unidades de minuto
		DEC R23
		JMP ISR_POP
	DC_D_MIN: ; Decrementar decenas de minuto
		DEC R26
		JMP ISR_POP

;;; Modificación de hora ;;;

IC_HORA: ; Incrementa
	LDI R30, 2
	CPSE R30, R27
	JMP LIMITE
	LDI R30, 3
	CPSE R30, R22
	JMP LIMITE
	CLR R22
	CLR R27
	JMP ISR_POP
	LIMITE:
		LDI R30, 9
		CPSE R22, R30	; Compara los registros
		JMP IC_U_HORA ; Si no se cumple la condición salta a IC_U_HORA
		CLR R22	; De lo contrario; al alcanzar el inmediato se limpia el registro

		;Decenas
		LDI R30, 9
		CPSE R27, R30 ; Compara el valor inmediato con el valor en el registro
		JMP IC_D_HORA ; Si no se cumple la condición salta a IC_D_HORA
		CLR R27 ; De lo contrario; al alcanzar el inmediato se limpia el registro
		JMP ISR_POP

DC_HORA: ; Decrementa

	LDI R30, 2
	CPSE R30, R27
	JMP LIMITEDC
	LDI R30, 3
	CPSE R30, R22
	JMP LIMITEDC
	CLR R22
	CLR R27
	JMP ISR_POP
	LIMITEDC:
		LDI R30, 0 ; 9
		CPSE R22, R30	; Compara los registros
		JMP DC_U_HORA ; Si no se cumple la condición salta a IC_U_HORA
		LDI R22, 3	; De lo contrario; al alcanzar el inmediato se limpia el registro

		;Decenas
		LDI R30, 0 ; 2
		CPSE R27, R30 ; Compara los registros
		JMP DC_D_HORA ; Si no se cumple la condición salta a IC_D_HORA
		LDI R27, 2 ; De lo contrario; al alcanzar el inmediato se limpia el registro
		JMP ISR_POP

	IC_U_HORA: ; Incrementa unidades de minuto
		INC R22
		JMP ISR_POP
	IC_D_HORA: ; Incrementa decenas de minuto
		INC R27
		JMP ISR_POP
	DC_U_HORA: ; Decrementar unidades de minuto
		DEC R22
		JMP ISR_POP
	DC_D_HORA: ; Decrementar decenas de minuto
		DEC R27
		JMP ISR_POP

;******************************************************************
; SUBRUTINAS PARA ALARMA 
;******************************************************************

U_MIN_ALARMA:
;unidades de minutos
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R2
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB2
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_1000
	OUT PORTB, R20

	RET

D_MIN_ALARMA:
;decenas de minutos
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB1
	CBI PORTB, PB0

	MOV R29, R3
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB1
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0100
	OUT PORTB, R20

	RET

U_HORA_ALARMA:
;unidades de hora
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB0

	MOV R29, R4
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB0

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0010
	OUT PORTB, R20

	RET

D_HORA_ALARMA:
;decenas de hora
	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1

	MOV R29, R5
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R29
	LPM R29, Z

	CBI PORTB, PB5 ; Apaga el transistor para evitar ghosting
	CBI PORTB, PB4
	CBI PORTB, PB3
	CBI PORTB, PB2
	CBI PORTB, PB1

	ADD R29, R19 ; Suma al contador el registro
	OUT PORTD, R29
	LDI R20, 0b0000_0001
	OUT PORTB, R20

	RET

;;; Modificación de minutos ;;;

IC_MIN_ALARMA:
	;Unidades
	LDI R30, 9
	CPSE R2, R30	; Compara los registros
	JMP IC_U_MIN_ALARMA ; Si no se cumple la condición salta a IC_U_MIN_ALARMA
	CLR R2	; De lo contrario; al alcanzar el inmediato se limpia el registro

	;Decenas
	LDI R30, 5
	CPSE R3, R30 ; Compara los registros
	JMP IC_D_MIN_ALARMA ; Si no se cumple la condición salta a IC_D_MIN
	CLR R3 ; De lo contrario; al ser iguales se limpia el registro

	JMP ISR_POP

DC_MIN_ALARMA:
	;Unidades
	LDI R30, 9
	CPSE R2, R30	; Compara los registros
	JMP DC_U_MIN_ALARMA ; Si no se cumple la condición salta a DC_U_MIN_ALARMA
	CLR R2	; De lo contrario; al alcanzar el inmediato se limpia el registro

	;Decenas
	LDI R30, 5
	CPSE R3, R30 ; Compara los registros
	JMP DC_D_MIN_ALARMA ; Si no se cumple la condición salta a DC_D_MIN_ALARMA
	CLR R3 ; De lo contrario; al ser iguales se limpia el registro

	JMP ISR_POP

	IC_U_MIN_ALARMA: ; Incrementa unidades de minuto
		INC R2
		JMP ISR_POP
	IC_D_MIN_ALARMA: ; Incrementa decenas de minuto
		INC R3
		JMP ISR_POP
	DC_U_MIN_ALARMA: ; Decrementar unidades de minuto
		DEC R2
		JMP ISR_POP
	DC_D_MIN_ALARMA: ; Decrementar decenas de minuto
		DEC R3
		JMP ISR_POP

;;; Modificación de hora ;;;

IC_HORA_ALARMA: ; Incrementa
	LDI R30, 2
	CPSE R5, R30
	JMP LIMITE_ALARMA
	LDI R30, 3
	CPSE R4, R30
	JMP LIMITE_ALARMA
	CLR R4
	CLR R5
	JMP ISR_POP
	LIMITE_ALARMA:
		LDI R30, 9
		CPSE R4, R30	; Compara los registros
		JMP IC_U_HORA_ALARMA ; Si no se cumple la condición salta a IC_U_HORA
		CLR R4	; De lo contrario; al alcanzar el inmediato se limpia el registro

		;Decenas
		LDI R30, 2
		CPSE R5, R30 ; Compara el valor inmediato con el valor en el registro
		JMP IC_D_HORA_ALARMA ; Si no se cumple la condición salta a IC_D_HORA
		CLR R5 ; De lo contrario; al alcanzar el inmediato se limpia el registro
		JMP ISR_POP

DC_HORA_ALARMA: ; Decrementa

	LDI R30, 2
	CPSE R5, R30
	JMP LIMITEDC_ALARMA
	LDI R30, 3
	CPSE R4, R30
	JMP LIMITEDC_ALARMA
	CLR R4
	CLR R5
	JMP ISR_POP
	LIMITEDC_ALARMA:
		LDI R30, 9 ; 9
		CPSE R4, R30 ; Compara los registros
		JMP DC_U_HORA_ALARMA ; Si no se cumple la condición 
		LDI R30, 0	; De lo contrario
		MOV R4, R30

		;Decenas
		LDI R30, 2 ; 2
		CPSE R5, R30 ; Compara los registros
		JMP DC_D_HORA_ALARMA ; Si no se cumple la condición 
		LDI R30, 0 ; De lo contrario
		MOV R5, R30 ;
		JMP ISR_POP

	IC_U_HORA_ALARMA: ; Incrementa unidades de minuto
		INC R4
		JMP ISR_POP
	IC_D_HORA_ALARMA: ; Incrementa decenas de minuto
		INC R5
		JMP ISR_POP
	DC_U_HORA_ALARMA: ; Decrementar unidades de minuto
		DEC R4
		JMP ISR_POP
	DC_D_HORA_ALARMA: ; Decrementar decenas de minuto
		DEC R5
		JMP ISR_POP
