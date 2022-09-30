;==============================================================================
;   Processor: PIC16F877
;   ED II
;   TP_1
;   Author: Venancio
;   Integrantes: Calisaya, Irigoin, Venancio
;==============================================================================
    
;==============================================================================
;   DEFINITIONS
;==============================================================================
    list p=16f877
    #include <p16f877.inc>
    
;==============================================================================
;   VARIABLES
;==============================================================================      
var_1	    equ  0x20

;==============================================================================
;   CONFIG_
;============================================================================== 
__CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_OFF & _CP_OFF & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_ON
	    
;==============================================================================
;   RESET
;==============================================================================    
Reset	org  0x00
	goto  main 
	
	org  0x04
	nop
;==============================================================================
;   CONFIG_
;==============================================================================		
main
	clrf	PORTB
	clrf	PORTD
	bsf	STATUS,RP0
	movlw	0xFF
	movwf	TRISB
	bcf	OPTION_REG,7
	clrf	TRISD
	bcf	STATUS,RP0
	bcf	STATUS,0
	
;==============================================================================
;   CODE SEGMENT
;==============================================================================		
funcion
	swapf	PORTB,0		;nibble_1/nibble_2
	movwf	var_1		;nibble_2/nibble_1
	movf	PORTB,0		;nibble_1/nibble_2
	addwf	var_1,1		;nibble_1/nibble_2+nibble_2/nibble_1=xxxxxxxx
	bcf	var_1,4		;xxx0xxxx
	movf	var_1,0		;muevo el resultado a W
	movwf	PORTD		;traslado al puerto D
	btfss	STATUS,1	;verifico que se haya producido un digit carry
	goto	funcion		;repite la funcion
	bsf	PORTD,4		;enciende un quinto led
	goto	loop		;pausa el programa hasta su reinicio
	
;==============================================================================		
loop
	nop
	goto loop
	
;==============================================================================		
	end
	
	
	

