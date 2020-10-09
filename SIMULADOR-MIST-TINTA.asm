
;*********************  DefiniÃ§Ã£o do processador *****************************

			#include p16F877A.inc 
			__config _HS_OSC & _WDT_OFF & _LVP_OFF & _PWRTE_ON 

;************************** MemÃ³ria de programa ******************************
 		
			cblock 0x20
			sensora
			valvb
			ab
			motor
			valvc
			endc
			DELAY EQU 0x24
			VEZES EQU 0x25 

			ORG	0 

RESET 		nop             
 			goto START 

;***************************** InterrupÃ§Ã£o **********************************
 			ORG 4 

;*************************** Inicio do programa ******************************



START		bsf STATUS,RP0    ;Vai para o Bank1 de memÃ³ria
			movlw b'00000000' ;Gravando em W todos os pinos como saida
			movwf TRISD		  
			movlw b'00001111' ;Gravando em W botões K como entrada
			movwf TRISB
			
			
			bsf STATUS, RP0 ;Indo para Bank1 de memoria e zerando variáveis
			movlw 0x00
			MOVWF sensora
			MOVWF valvb
			MOVWF motor
			MOVWF valvc
			MOVWF ab

			bcf STATUS,RP0    ;Vai para o Bank0 de memÃ³ria
			movlw b'00000000' ;Apagando todos os LEDS
			movwf PORTD
			



CHECAR
			BTFSC PORTB, 0 ;Checando K1
			goto AGUARDA ;Função para aguardar um pouco de tempo antes de checar o proximo botao (necessario para nao bugar)
			goto APERTADO;Função para seguir com as ações necessárias caso o botão seja pressionado

CHECAR2
			BTFSC PORTB, 1 ;Checando K2
			goto AGUARDA2
			goto APERTADO2
CHECA_AB
			movlw 0X01 ;Checa se K1 e K2 (respectivos a e b) estão ativados, caso sim poderemosentão checar o K3 caso o usuario deseje ativar o motor
			subwf ab, 0
			BTFSS STATUS, Z
			goto AGUARDA3 ;Caso contrario aguardamos um pouco de tempo e vamos para checagem do proximo
			goto CHECAR_M
CHECA_C
			movlw 0X01 ;Checando K4 (respectivo C) mas antes precisamos checar algumas condições para que C possa ser ativado
			subwf sensora, 0
			BTFSS STATUS, Z
			goto AGUARDA4 ; Checamos se a variavel de controle de a (K1) está com valor logico 1, caso sim podemos prosseguir, caso não, devemos perder tempo e checar o proximo
			movlw 0X01
			subwf valvb, 0; Caso a eseja ligado, temos que checar e garantir que b (K2) esteja desativado, caso contrário perdemos tempo e checamos o proximo
			BTFSC STATUS, Z
			goto AGUARDA4
			BTFSC PORTB, 3 ; Dadas condições atendidas, checar se o usuario apertará o não K4
			goto AGUARDA4
			goto APERTADO_C
C_ON
			BTFSC PORTB, 3 ;Caso C esteja ativado, somente poderemos operar em dois botoes; K4 para desligar C ou K1 para desligar A e consequentemente C, os outros devem ficar em 0
			goto AGUARDA_C_ON ;Caso não haja pressionamento no botão K4, perde tempo e cheque K1
			goto APAGA_C_ON ;Caso pressionado, desativar C e apagar seus LEDS
C_ON_A
			BTFSC PORTB, 0 ;Checando A quando C está ON, necessário pois diferente da função CHECAR, precisamos levar em consideração uma intervenção direta na variavel C que antes estava Ligada
			goto AGUARDA_C_ON_A ;Caso não apertado, perdemos tempo e volta para C_ON
			MOVLW 0X00
			MOVWF sensora
			goto APERTADO_A_C_ON ;Caso pressionado, zera-se a variável A, perde tempo para evitar ruidos na proxima checagem inicial e apagamos C e colocamos valor 0 em sua variavel
			goto APAGA_C_ON
VALIDA
			movlw 0X01 ; As funções de validação servem para comparar se a variavel possui 1 ou não, caso possua apaga-se pois terá valor 0, caso não possua acende pois se tornara em valor 1
			addwf sensora
			movlw 0X01
			subwf sensora, 0
			BTFSS STATUS, Z
			goto APAGA
			goto ACENDE
VALIDA2
			movlw 0X01
			addwf valvb
			movlw 0X01
			subwf valvb, 0
			BTFSS STATUS, Z
			goto APAGA2
			goto ACENDE2
			
ACENDE
			
			movlw b'11000000'  ;Acende os LEDS de A e checa se B está ligado, caso esteja, função que acende os dois LEDS e salva na variável ab para poder checar K3 do motor deve ser chamada.
			movwf PORTD	
			movlw 0X01
			subwf valvb, 0
			BTFSS STATUS, Z
			goto CHECAR2 ;Caso B esteja desligado, checar proximo botão
			goto ACENDE_AB
ACENDE2
					
			movlw b'00110000' ;Acende os LEDS de B e checa se A está ligado, caso esteja, função que acende os dois LEDS e salva na variável ab para poder checar K3 do motor deve ser chamada.
			movwf PORTD	
			movlw 0X01
			subwf sensora, 0
			BTFSS STATUS, Z
			goto CHECAR ;Caso A esteja desligado, checar proximo botão
			goto ACENDE_AB
ACENDE_AB
			movlw 0x01 ;Contabiliza que AB estão ligados, acende os LEDS, e assim vai para checagem de K3 (motor) 
			movwf ab
			movlw b'11110000'
			movwf PORTD	
			goto CHECAR_M
CHECAR_M
			BTFSC PORTB, 2 ;ativação do motor, caso não pressionado, volta a checar A e B caso o usuário queira desativá-los
			goto AGUARDA3 ;Perdendo tempo e indo para proximo botao para checagem
			goto APERTADO_M ;Perdendo tempo evitando ruidos e indo para validação da variavel e LEDs
VALIDA_M
			movlw 0X01 ;Contabiliza 1 em W para comparação, caso motor ja esteja com 1, apaga-se o LED do motor, caso esteja em 0, acende-se o LED do motor
			addwf motor
			movlw 0X01
			subwf motor, 0
			BTFSS STATUS, Z
			goto APAGA3
			goto ACENDE3
VALIDA_C
			movlw 0X01 ; Contabiliza 1 em W para comparação, caso C esteja ligado, apaga-se o LED, caso esteja desligado significa que deve acendê-lo 
			addwf valvc
			movlw 0X01
			subwf valvc, 0
			BTFSS STATUS, Z
			goto APAGA4
			goto ACENDE4	
ACENDE3
			movlw 0x01 ;Gravando 1 em motor e ligando seu respectivo LED
			movwf motor
			movlw b'00001100' ;a proposito de estética, acende-se o LED do motor e apaga os outros pois sao irrelevantes visto que o motor so acende quando os outros dois estiverem ligasdos.
			movwf PORTD
			call PERDE_TEMPO	
			goto CHECAR_M ;Retornando a sua função principal
ACENDE4
			movlw b'11000011' ; Acendendo valvula C (so pode ser ativada com valor de A em 1, por isso acende-se os dois LEDS)
			movwf PORTD
			call PERDE_TEMPO	
			goto AGUARDA_C_ON
APAGA
			movlw 0x00 ;Função de apagar A, checa depois de B está ativado para que possa deixar ligado somente os LEDS de B, a variável é zerada.
			movwf sensora
			movwf ab
			movlw b'00000000' 
			movwf PORTD
			movlw 0x01
			subwf valvb, 0
			BTFSS STATUS, Z
			goto CHECAR
			goto ACENDE2		

APAGA2
			movlw 0x00 ;Função de apagar B, checa depois de A está ativado para que possa deixar ligado somente os LEDS de A, a variável é zerada.
			movwf valvb
			movwf ab
			movlw b'00000000' 
			movwf PORTD
			movlw 0x01
			subwf sensora, 0
			BTFSS STATUS, Z
			goto CHECAR
			goto ACENDE
APAGA3
			movlw 0x00 ;Apagando Motor e devolvendo estado anterior (A e B ligados)
			movwf motor
			movlw b'11110000' 
			movwf PORTD
			goto CHECAR
APAGA4
			movlw 0x00 ;;Função de apagar C, checa depois de A está ativado para que possa deixar ligado somente os LEDS de A, a variável é zerada.
			movwf valvc
			movlw b'00000000' 
			movwf PORTD
			movlw 0x01
			subwf sensora, 0
			BTFSS STATUS, Z
			goto AGUARDA4
			goto ACENDE
PERDE_TEMPO
 			MOVLW d'80' ;Função que 'perde' tempo, aguardando um intervalo de tempo sem nenhuma instrução (necessário para evitar alguns bugs)
 			MOVWF VEZES
LOOP_VEZES
 			MOVLW d'255'
		 	MOVWF DELAY
 			CALL DELAY_US
 			DECFSZ VEZES,1
 			GOTO LOOP_VEZES
			RETURN
DELAY_US
 			NOP
 			NOP
 			DECFSZ DELAY,1
 			GOTO DELAY_US
 			RETURN			


AGUARDA
		call PERDE_TEMPO ;Aguarda um pouco de tempo e vai para checagem do próximo botão
		goto CHECAR2
AGUARDA2
		call PERDE_TEMPO
		goto CHECA_AB
AGUARDA3
		call PERDE_TEMPO
		goto CHECA_C
AGUARDA4
		call PERDE_TEMPO
		goto CHECAR
AGUARDA_C_ON
		call PERDE_TEMPO
		goto C_ON_A
AGUARDA_C_ON_A
		call PERDE_TEMPO
		goto C_ON
APERTADO
		BTFSS PORTB, 0 ;Espera o usuario soltar o botão e perde tempo para evitar ruidos, apos isso vai para a validação das variaveis e LEDS
		goto APERTADO
		call PERDE_TEMPO
		goto VALIDA
APERTADO2
		BTFSS PORTB, 1
		goto APERTADO2
		call PERDE_TEMPO
		goto VALIDA2
APERTADO_M
		BTFSS PORTB, 2
		goto APERTADO_M
		call PERDE_TEMPO
		goto VALIDA_M
APERTADO_C
		BTFSS PORTB, 3
		goto APERTADO_C
		call PERDE_TEMPO
		goto VALIDA_C
APERTADO_A_C_ON
		BTFSS PORTB, 0
		goto APERTADO_A_C_ON
		call PERDE_TEMPO
		goto APAGA4
APAGA_C_ON
		BTFSS PORTB, 3 ;Função especifica para A ativado quando C também estiver ativado, caso A seja desligado, espera o usuario soltar o botao, perde tempo para evitar ruidos e vai para função de Apagar e zerar C 
		goto APAGA_C_ON 
		call PERDE_TEMPO
		goto APAGA4




END