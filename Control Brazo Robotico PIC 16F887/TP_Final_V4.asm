;==============================================================================
;   Processor: PIC16F887
;   TP Final
;   Author: Venancio, Calisaya, Irigoin
;==============================================================================

;==============================================================================
;   DEFINITIONS
;==============================================================================
	list		p=16f887	
	#include	<p16f887.inc>	


	__CONFIG    _CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG    _CONFIG2, _WRT_OFF & _BOR21V

       
;==============================================================================
;   VARIABLES
;============================================================================== 		
;Display
digit_1		equ  0x28
digit_2		equ  0x29
digit_3		equ  0x2A
		
Disp		equ  0x2B
		
Unidad		equ  0x2D
Decena		equ  0x2E
Centena		equ  0x2F
		
;ADC
adc_L		equ  0x72
adc_H		equ  0x73
		
Cont_adc	equ  0x30

;Servos
Ang_1		equ  0x20
Ang_2		equ  0x21
Ang_3		equ  0x22
Ang_4		equ  0x23
		
S_E		equ  0x24
		
;Comunicacion
Data_		equ  0x35		
	
;Push_Pop
W_temp		equ  0x70
STATUS_temp	equ  0x71
	
;==============================================================================
;   RESET
;============================================================================== 
RESET	org   0x00
	goto  main
	
	org   0x04
	goto  ISR
	
;==============================================================================
;   CONGIG_
;==============================================================================	
main
	;Inicializacion de puertos
	clrf	PORTA	    ;Multiplexado de Display
	clrf	PORTB	    ;RB0int
	clrf	PORTC	    ;Comunicacion serie y control de servos
	clrf	PORTD	    ;Salidas para segmentos de Display
	clrf	PORTE	    ;ADC
	
	;Configuracion de puertos
	bsf	STATUS,RP0
	
	movlw	b'00000000'
	movwf	TRISA	    ;Multiplexado de display
	
	movlw	0x01
	movwf	TRISB	    ;Envio de datos
	
	movlw	b'10000000'
	movwf	TRISC	    ;Comunicacion y servps
	
	movlw	b'00000000'
	movwf	TRISD	    ;Display
	
	movwf	b'00000001'
	movwf	TRISE	    ;RE0 entrada
	
	;Configuracion ANSEL's
	bsf	STATUS,RP1
	
	movlw	b'00100000' ;RE0 entrada analogica
	movwf	ANSEL
	
	movlw	b'00000000'
	movwf	ANSELH	    ;desactivo las entradas analogicas en el PORTB
	
	bcf	STATUS,RP0
	bcf	STATUS,RP1
	
	;Config_conversor
	banksel	ADCON1
	movlw	b'10000000'	;Configuro justificado a la izq y vref=vcc
	movwf	ADCON1
	
	banksel	ADCON0
	movlw	b'01010101'	;Canal 5,prescaler recomendado para 4MHz, ADC on
	movwf	ADCON0
	
	;Inicializacion de variables
	movlw	0x20
	movwf	FSR
	
	movlw	b'00000001'
	movwf	Disp
	
	clrf	digit_1
	clrf	digit_2
	clrf	digit_3
	
	movlw	0x01
	movwf	Cont_adc
	
	call	Init_ang
	
	clrf	Unidad
	clrf	Decena
	clrf	Centena
	
	
;==============================================================================
;   CONFIG_INT y Timer's
;==============================================================================		
Config_int
	bsf	STATUS,RP0
	
	;Timer0
	movlw	b'00000010'	
	movwf	OPTION_REG	;prescaler 1:8, reloj interno
	
	;Interrupciones PIE1
	movlw	b'00100000'	;RX
	movwf	PIE1
	
	;Comunicacion serie
	movlw	.25
	movwf	SPBRG
	
	movlw	b'00100100'
	movwf	TXSTA
	
	movlw	b'11010000'	;PEIE, RB0
	movwf	INTCON
	
	;Timer2
	movlw	.49
	movwf	PR2		;Delay de 16 ms
	
	bcf	STATUS,RP0
	
	;Comunicacion
	movlw	b'10010000'
	movwf	RCSTA
	
	;Timer2
	movlw	b'00101111'	
	movwf	T2CON		;prescaler 1:16 y postscaler 1:5
	bcf	ADCON0,1	;enciendo el conversor
	
;==============================================================================
;   CODE SEGMENT
;==============================================================================	
Programa
	call	Ser_1
	call	Ser_2
	call	Ser_3
	call	Ser_4
	decfsz	Cont_adc
	goto	Display
	bsf	ADCON0,1
	btfsc	ADCON0,1
	goto	$-1
	call	ADCint
	
Display
	movf	Disp,0
	movwf	PORTA		;Logica positiva
	
	btfsc	Disp,0
	movf	digit_1,0
	
	btfsc	Disp,1
	movf	digit_2,0
	
	btfsc	Disp,2
	movf	digit_3,0
	
	btfsc	Disp,3
	movlw	.10
	
	call	Display_valor	;Catodo comun -Logica positiva-
	
	movwf	PORTD
	call	Delay
		
	bcf	STATUS,C
	rlf	Disp,1
	
	btfss	Disp,4
	goto	Display
	movlw	0x01
	movwf	Disp
	goto    Programa
	
;==============================================================================
;   INT_
;==============================================================================	
ISR
	;PUSH
	movlw	W_temp
	swapf	STATUS,0
	movwf	STATUS_temp
	
	btfsc	PIR1,5
	call	Recepcion
	
	btfsc	INTCON,1
	call	RB0int
	
ISR_End
	;POP
	swapf	STATUS_temp,0
	movwf	STATUS
	swapf	W_temp,1
	swapf	W_temp,0
	
	retfie
	
;==============================================================================
;   INT_Reception
;==============================================================================		
Display_valor
	addwf	PCL,1
	retlw	b'00111111' ;0
	retlw	b'00000110' ;1
	retlw	b'01011011' ;2
	retlw	b'01001111' ;3
	retlw	b'01100110' ;4
	retlw	b'01101101' ;5
	retlw	b'01111101' ;6
	retlw	b'00000111' ;7
	retlw	b'01111111' ;8
	retlw	b'01101111' ;9	
	retlw	b'00111001' ;C
;INTE
RB0int
	movf	adc_L,0
	movwf	Data_
	call	Transmision
	
	movf	Ang_1,0
	movwf	Data_
	call	Transmision
	
	movf	Ang_2,0
	movwf	Data_
	call	Transmision
	
	movf	Ang_3,0
	movwf	Data_
	call	Transmision
	
	movf	Ang_4,0
	movwf	Data_
	call	Transmision
	
	bcf	INTCON,1
	
	return
	
Init_ang	;Se inicializan con un angulo de 90°
	movlw	.69
	movwf	Ang_1
	movwf	Ang_2
	movwf	Ang_3
	movwf	Ang_4
	return
	
;Servos
Ser_1
	bcf	INTCON,2
	bsf	PORTC,5
	movf	Ang_1,0
	movwf	TMR0	    ;precarga de 6 a 131 (dependiendo del duty cycle)
	btfss	INTCON,2
	goto	$-1
	bcf	PORTC,5
	return
	
Ser_2
	bcf	INTCON,2
	bsf	PORTC,4
	movf	Ang_2,0
	movwf	TMR0
	btfss	INTCON,2
	goto	$-1
	bcf	PORTC,4
	return

Ser_3
	bcf	INTCON,2
	bsf	PORTC,3
	movf	Ang_3,0
	movwf	TMR0
	btfss	INTCON,2
	goto	$-1
	bcf	PORTC,3
	return
	
Ser_4
	bcf	INTCON,2
	bsf	PORTC,1
	movf	Ang_4,0
	movwf	TMR0
	btfss	INTCON,2
	goto	$-1
	bcf	PORTC,1
	return
	
Delay
	clrf	TMR2	    ;Comienza desde cero
	bcf	PIR1,1	    ;bajo la bandera
	btfss	PIR1,1	    ;espero a que se cumpla el tiempo
	goto	$-1
	return
	
;ADC
ADCint
	movlw	.50
	movwf	Cont_adc	;Se toman muestras cada 1 segundo
	movf	ADRESH,0
	movwf	adc_H
	banksel	ADRESL
	movf	ADRESL,0
	movwf	adc_L
	banksel	ADRESH
	
	bcf	STATUS,C
	btfsc	adc_H,0
	bsf	STATUS,C
	rrf	adc_L,1		;saco el bit menos significativo
	
	call	Bin2BCD		;Transformo a BCD
	movf	Centena,0
	movwf	digit_3
	movf	Decena,0
	movwf	digit_2
	movf	Unidad,0
	movwf	digit_1
	
	bcf	PIR1,6
	
	return
	
;Conversion
Bin2BCD
	movf	adc_L,0
	movwf	Unidad
	clrf	Decena
	clrf	Centena
	
BCD_0
	movlw	.10
	subwf	Unidad,0
	btfss	STATUS,C
	return
	
BCD_1
	movwf	Unidad
	incf	Decena,1
	movlw	.10
	subwf	Decena,0
	btfss	STATUS,Z
	goto	BCD_0
	
BCD_2
	clrf	Decena
	incf	Centena,1
	goto	BCD_0

Recepcion
	;Servo a elegir
	movf	RCREG,0
	movwf	S_E
	movlw	0x10
	subwf	S_E,0		;acondiciona para moverlo a FSR
	movwf	FSR
	btfss	PIR1,RCIF
	goto	$-1
	
	;Datos
	movf	RCREG,0
	movwf	Centena
	movlw	0x30
	subwf	Centena,1	;acondiciona datos
	btfss	PIR1,RCIF
	goto	$-1
	
	
	movf	RCREG,0
	movwf	Decena
	movlw	0x30
	subwf	Decena,1
	btfss	PIR1,RCIF
	goto	$-1
	
	movf	RCREG,0
	movwf	Unidad
	movlw	0x30
	subwf	Unidad,1
	
	clrf	INDF
	call	BCD2Bin
	
	return

BCD2Bin
	movf	Centena,1
	btfsc	STATUS,Z
	goto	BCD2Bin_D
	decf	Centena,1
	
	movlw	.100
	addwf	INDF,1
	goto	BCD2Bin
	
BCD2Bin_D
	movf	Decena,1
	btfsc	STATUS,Z
	goto	BCD2Bin_U
	decf	Decena,1
	
	movlw	.10
	addwf	INDF,1
	goto	BCD2Bin_D
	
BCD2Bin_U
	movf	Unidad,1
	btfsc	STATUS,Z
	return
	
	decf	Unidad,1
	incf	INDF,1
	goto	BCD2Bin_U
	
Transmision
	;envio la opcion de control
	movf	Data_,0
	movwf	TXREG
	bsf	STATUS,RP0
	btfss	TXSTA,1
	goto	$-1
	bcf	STATUS,RP0
	return
	
;==============================================================================	
	end



