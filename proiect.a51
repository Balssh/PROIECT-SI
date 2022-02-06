;************************************************************************************
;*	TOATE FUNCTIONALITATILE CERUTE IN CADRUL PROIECTULUI AU FOST IMPLEMENTATE, DAR	*
;*	DIN CAUZA LIMITEI DE 2K A FOST NECESAR SA "COMPRIM" DOUA SAU MAI MULTE FUNCTII	*
;*	INTR-UNA, DE EXEMPLU, PENTRU AFISAREA STATUSULUI MODULULUI AM FOLOSIT O SINGURA	*
;*	COMANDA (TASTA 'V') PENTRU A AFISA ATAT CUVANTUL DE STARE, CAT SI VALOAREA 		*
;*	CURENTA A CONTORULUI SI A REGISTRELOR DE PRESETARE DEODATA, DESI INITIAL LE		*
;*	ASIGNASEM TASTE SEPARATE. EXPLICATII SUPLIMENTARE SE GASESC IN DOCUMENTATIE.	*
;*	CODUL CARE A FOST "COMPRIMAT" ESTE COMENTAT.									*
;************************************************************************************
	
	//////////////////////
	//	ADRESE EXTERNE  //
	//////////////////////
rwAD_LSB		EQU	8000h 	;adresa pentru LSB din constanta de incarcare in counter
rwAD_MB 		EQU	8001h	;adresa pentru MB de incarcare in counter
rwAD_MSB		EQU	8002h	;adresa pentru MSB din constanta de incarcare in counter
rwAD_CNT_LD		EQU 8003h	;adresa pentru citire/scriere valori din/in counter
wAD_START_STOP	EQU	8004h	;adresa pentru comanda de start/stop
rAD_CNT_LSB		EQU	8004h	;adresa pentru citirea LSB din counter
wAD_RST			EQU 8005h	;adresa pentru comanda de reset
rAD_CNT_MB		EQU	8005h	;adresa pentru citirea MB din counter
wAD_RST_INT0	EQU 8006h	;adresa pentru comanda de resetare intreruperi
rAD_CNT_MSB		EQU 8006h	;adresa pentru citirea MSB din counter
rwAD_CW_SW		EQU 8007h 	;adresa pentru scrierea/citirea cuvantului de comanda/stare
wAD_OUT_LSB		EQU	8008h	;adresa pentru scrierea LSB pe liniile de iesire
rAD_IN_LSB		EQU 8008h	;adresa pentru citirea LSB de pe liniile de intrare
wAD_OUT_MSB		EQU	8009h	;adresa pentru scrierea MSB pe liniile de iesire
rAD_IN_MSB		EQU 8009h	;adresa pentru citirea MSB de pe liniile de intrare

	///////////////////////////////////
	//	ADRESE INTERNE PT VARIABILE  //
	///////////////////////////////////
BUFFER			EQU 60h
AD_CNT_STAT		EQU 70h		;adresa statusului curent al contorului
AD_STATUS		EQU 71h		;adresa statusului curent al modulului
CW				EQU 72h		;adresa cuvantului de comanda
LSB				EQU 73h		
MB				EQU 74h
MSB				EQU 75h
CNT_LSB			EQU 76h		;adresa LSB a registrului de citire din contor
CNT_MB			EQU 77h		;adresa MB a registrului de citire din contor
CNT_MSB			EQU 78h		;adresa MSB a registrului de citire din contor
CONST_LSB		EQU 79h		;adresa LSB a registrului de presetare contor
CONST_MB		EQU 7Ah		;adresa MB a registrului de presetare contor
CONST_MSB		EQU 7Bh		;adresa MSB a registrului de presetare contor
SW				EQU 7Ch		;adresa cuvant de stare
IO_LSB			EQU 7Dh		;adresa LSB pentru liniile IO
IO_MSB			EQU 7Eh		;adresa MSB pentru liniile IO
CNT_INIT		EQU 00h		;contorul e initializat cu 0
CNT_UP			EQU 01h		;contorul numara crescator
CNT_DOWN		EQU	02h		;contorul numara descrescator
CNT_STOP		EQU 03h		;contorul e oprit
QUIT			EQU 'Q'
	////////////////
	//	MACROURI  //
	////////////////
;macro pentru scriere de linie noua
PRINT_CR MACRO
	MOV A, #0Dh
	LCALL RUT_TX
	ENDM

;macro pentru scriere "READY"
PRINT_READY MACRO
	MOV DPTR, #MSG_READY
	LCALL PRINT_MSG
	ENDM

;macro pentru scriere '0'
PRINT_0 MACRO
	MOV A, #30h
	LCALL RUT_TX
	ENDM

;macro pentru scriere '1'
PRINT_1 MACRO
	MOV A, #31h
	LCALL RUT_TX
	ENDM
	
	ORG 0h
	LJMP MAIN		;salt la programul principal
	
	ORG 03h
	LJMP RUT_INT0	;salt la rutina de intreruperi externe
	
	ORG 23h
	LJMP RUT_RX		;salt la rutina de receptie seriala
	
	ORG 100h
MAIN:
	////////////////////
	//	INITIALIZARI  //
	////////////////////
	CLR IE.7	;dezactivare globala a intreruperilor
;INITIALIZARE CUVANT DE COMANDA
	MOV A, CNT_INIT
	MOV AD_CNT_STAT, A
	MOV DPTR, #rwAD_CW_SW
	MOVX @DPTR, A
;INITIALIZARE CONTOR	
	MOV DPTR, #rwAD_LSB
	MOVX @DPTR, A
	MOV DPTR, #rwAD_MB
	MOVX @DPTR, A
	MOV DPTR, #rwAD_MSB
	MOVX @DPTR, A
	MOV DPTR, #rwAD_CNT_LD
	MOVX @DPTR, A
;PROGRAMARE UART
	SETB SCON.6		;programare mod de lucru 1 pentru UART – SM1
	CLR SCON.7		;programare mod de lucru 1 pentru UART – SM0
	MOV PCON, #80h	;seteaza factor de multiplicare 2
	SETB IE.4		;validare intreruperi de la UART 
	MOV TMOD, #20h	;programare timer T1 in modul 2
	MOV TL1, #0F3h	;incarca constanta de timp in TL1
	MOV TH1, #0F3h	;incarca constanta de timp in TH1
	SETB TCON.6		;pornire timer T1
	MOV DPTR, #MSG_WLCM
	LCALL PRINT_MSG
	PRINT_READY
	SETB TCON.4		;validare receptie - REN
;PROGRAMARE INTRERUPERI EXTERNE
	SETB IE.0		;validare intrerupere /INT0
	SETB TCON.0		;setare /INT0 pe front cazator
	SETB IE.7		;validare globala a intreruperilor
;ASTEPTARE RECEPTIE COMANDA
	SJMP $
		
	ORG 200h
RUT_TX:
	////////////////////////////////////////////
	//	RUTINA DE TRANSMISIE A UNUI CARACTER  //
	////////////////////////////////////////////
	CLR SCON.4		;invalidare receptie
	MOV SBUF, A		;transfera caracterul din acumulator in SBUFF
	JNB SCON.1,$	;asteptare finalizare transmisie
	CLR SCON.1		;reseteaza flagul de transmisie
	SETB SCON.4		;validare receptie
	RET
	
	ORG 300h
RUT_INT0:
	////////////////////////////////////////////////
	//	RUTINA DE TRATARE A INTRERUPERII EXTERNE  //
	////////////////////////////////////////////////
	MOV DPTR, #MSG_INT0
	LCALL PRINT_MSG
	PRINT_READY
	MOV DPTR, #wAD_RST_INT0
	MOVX @DPTR, A
	RETI
	
	ORG 400h
RUT_RX:
	//////////////////////////////////////////
	//	RUTINA DE RECEPTIE A UNUI CARACTER  //
	//////////////////////////////////////////
	CLR IE.4		;invalidare intreruperi de la UART
	MOV A, SBUF		;copiere in acumulator caracterul receptionat
	CLR SCON.0		;resetare flag de receptie
	LCALL TO_UPR	;transformare caracter receptionat in majuscula
;VERIFICARE CARACTER
	CJNE A, #'S', other0
	LCALL START_STOP
other0:
	CJNE A, #'I', other1
	LCALL INITIALIZE
other1:
	CJNE A, #'V', other2
	LCALL VIEW_STATUS
other2:
	CJNE A, #'P', other3
	LCALL COMMAND_WORD
other3:
	CJNE A, #'L', other5
	LCALL LOAD
;other4:
;	CJNE A, #'T', other5
;	LCALL READ_CNT
other5:
	CJNE A, #'Z', other6
	LCALL READ_IN0
other6:
	CJNE A, #'X', other7
	LCALL READ_IN1
other7:
	CJNE A, #'C', other8
	LCALL READ_IN2
other8:
	CJNE A, #'B', other9
	LCALL WRITE_OUT0
other9:
	CJNE A, #'N', other10
	LCALL WRITE_OUT1
other10:
	CJNE A, #'M', other11
	LCALL WRITE_OUT2
other11:
	CJNE A, #'R', oend
	LCALL RESET
;other12:
;	CJNE A, #'O', other13
;	LCALL READ_CONST
;other13:
;	CJNE A, #'U', oend
;	LCALL READ_STATUS
oend:
	SETB IE.4		;validare intreruperi de la UART
	RETI

	ORG 500h
START_STOP:
	///////////////////////////
	//	RUTINA DE START/STOP //
	///////////////////////////
	MOV A, #'S'
	LCALL RUT_TX
	MOV A, AD_CNT_STAT
	CJNE A, #CNT_INIT, ss0		;verificare daca contorul e pe 0
	MOV DPTR, #MSG_START
	MOV AD_CNT_STAT, #CNT_UP
	SJMP ssend
ss0:
	CJNE A, #CNT_UP, ss1		;verificare daca contorul numara crescator
	MOV DPTR, #MSG_STOP
	MOV AD_CNT_STAT, #CNT_STOP
	SJMP ssend
ss1:
	CJNE A, #CNT_STOP, ss2		;verificare daca contorul e oprit
	MOV DPTR, #MSG_START
	MOV AD_CNT_STAT, #CNT_UP
	SJMP ssend
ss2: RET
ssend:
	LCALL PRINT_MSG
	MOV DPTR, #wAD_START_STOP	;incarcare adresa de start/stop
	MOVX @DPTR, A
	PRINT_READY
	RET

LOAD:
	////////////////////////////////////////////////////
	//	RUTINA DE INCARCARE A CONSTANTELOR CONTORULUI //
	////////////////////////////////////////////////////
	MOV A, #'L'
	LCALL RUT_TX
	MOV DPTR, #MSG_INITIALIZE
	LCALL PRINT_MSG
	MOV DPTR, #MSG_LOAD_CNT_LSB
	LCALL PRINT_MSG
	LCALL READ_BYTE
	CJNE A, #QUIT, ld0		;verificare daca se doreste sarirea peste citire LSB
	PRINT_CR
	SJMP ld1
ld0:
	LCALL ASCII_TO_HEX		;conversie din ascii in hexa
	MOV LSB, A
	MOV DPTR, #rwAD_LSB		;incarcare adresa LSB registru de presetare
	MOVX @DPTR, A			;scriere in registru
ld1:	
	MOV DPTR, #MSG_LOAD_CNT_MB	
	LCALL PRINT_MSG
	LCALL READ_BYTE
	CJNE A, #QUIT, ld2		;verificare daca se doreste sarirea peste citire MB
	PRINT_CR
	SJMP ld3
ld2:
	LCALL ASCII_TO_HEX		;conversie din ascii in hexa
	MOV MB, A
	MOV DPTR, #rwAD_MB		;incarcare adresa MB registru de presetare
	MOVX @DPTR, A			;scriere in registru
ld3:
	MOV DPTR, #MSG_LOAD_CNT_MSB
	LCALL PRINT_MSG
	LCALL READ_BYTE
	CJNE A, #QUIT, ld4		;verificare daca se doreste sarirea peste citire MSB
	SJMP ldend
ld4:
	LCALL ASCII_TO_HEX		;conversie din ascii in hexa
	MOV MSB, A
	MOV DPTR, #rwAD_MSB		;incarcare adresa MSB registru de presetare
	MOVX @DPTR, A			;scriere in registru
ldend:
	PRINT_CR
	PRINT_READY
	RET
	
INITIALIZE:
	////////////////////////////////////////////////
	//	RUTINA DE INCARCARE CONSTANTE IN CONTOARE //
	////////////////////////////////////////////////
	MOV A, #'I'
	LCALL RUT_TX
	MOV DPTR, #MSG_INITIALIZE
	LCALL PRINT_MSG
	MOV DPTR, #rwAD_CNT_LD	;incarcare adresa de incarcare paralela in contoare
	MOVX @DPTR, A			;scriere in contoare
	PRINT_READY
	RET

READ_CNT:
	/////////////////////////////////////////
	//	RUTINA DE CITIRE VALORI DIN CONTOR //
	/////////////////////////////////////////
;	MOV A, #'T'
;	LCALL RUT_TX
;	MOV DPTR, #MSG_READ_CNT
;	LCALL PRINT_MSG
;	LCALL READ_CNT0
;	PRINT_CR
;	PRINT_READY
;	RET
READ_CNT0:
	MOV DPTR, #rwAD_CNT_LD	;incarcare adresa registre de citire din contoare
	MOVX A, @DPTR			;comanda de citire
	MOV DPTR, #rAD_CNT_LSB	;incarcare adresa registru de citire LSB
	MOVX A, @DPTR			;citire LSB
	MOV CNT_LSB, A			;salvare LSB intern
	MOV DPTR, #rAD_CNT_MB	;incarcare adresa registru de citire MB
	MOVX A, @DPTR			;citire MB
	MOV CNT_MB, A			;salvare MB intern
	MOV DPTR, #rAD_CNT_MSB	;incarcare adresa registru de citire MSB
	MOVX A, @DPTR			;citire MSB
	MOV CNT_MSB, A			;salvare MSB intern
	PRINT_CR
	MOV DPTR, #MSG_CNT_VAL
	LCALL PRINT_MSG
;AFISARE VALORI CONTOARE
	MOV A, CNT_LSB
	LCALL PRINT_BYTE
	MOV A, CNT_MB
	LCALL PRINT_BYTE
	MOV A, CNT_MSB
	LCALL PRINT_BYTE
	RET

RESET:
	//////////////////////////
	//	RUTINA DE RESETARE  //
	//////////////////////////
	PUSH ACC
	MOV A, #'R'
	LCALL RUT_TX
	MOV DPTR, #MSG_RESET
	LCALL PRINT_MSG
	MOV DPTR, #wAD_RST			;incarcare adresa de resetare
	MOVX @DPTR, A				;comanda de scriere
	PRINT_READY
	MOV AD_CNT_STAT, #CNT_INIT	;pune statusul contorului pe 0
	POP ACC
	RET

READ_CONST:
	//////////////////////////////////////////////////////////
	//	RUTINA DE CITIRE A CONSTANTELOR INCARCATE IN CONTOR //
	//////////////////////////////////////////////////////////
;	MOV A, #'O'
;	LCALL RUT_TX
;	MOV DPTR, #MSG_READ_CONST
;	LCALL PRINT_MSG
;	LCALL READ_CONST0
;	PRINT_CR
;	PRINT_READY
;	RET
	
READ_CONST0:
	MOV DPTR, #rwAD_LSB		;incarcare adresa registru de presetare LSB
	MOVX A, @DPTR			;comanda de citire
	MOV CONST_LSB, A		;salvare LSB intern
	MOV DPTR, #rwAD_MB		;incarcare adresa registru de presetare LSB
	MOVX A, @DPTR			;comanda de citire
	MOV CONST_MB, A			;salvare MB intern
	MOV DPTR, #rwAD_MSB		;incarcare adresa registru de presetare LSB
	MOVX A, @DPTR			;comanda de citire
	MOV CONST_MSB, A		;salvare MSB intern
	PRINT_CR
	MOV DPTR, #MSG_CONST_VAL
	LCALL PRINT_MSG
;AFISARE VALORI	REGISTRE DE PRESETARE
	MOV A, CONST_LSB
	LCALL PRINT_BYTE
	MOV A, CONST_MB
	LCALL PRINT_BYTE
	MOV A, CONST_MSB
	LCALL PRINT_BYTE
	RET

COMMAND_WORD:
	///////////////////////////////////////////////////
	//	RUTINA DE PROGRAMARE A CUVANTULUI DE COMANDA //
	///////////////////////////////////////////////////
	MOV A, #'P'
	LCALL RUT_TX
	MOV DPTR, #MSG_CW0
	LCALL PRINT_MSG
	MOV DPTR, #MSG_CW1
	LCALL PRINT_MSG
	LCALL READ_BYTE
	CJNE A,#QUIT, cw0		;verificare daca se doreste sarirea peste citire
	PRINT_CR
	SJMP cw1
cw0:
	LCALL ASCII_TO_HEX		;conversie din ascii in hexa
	MOV CW, A				;salvare cuvant de comanda intern
	MOV DPTR, #rwAD_CW_SW	;incarcare adresa de scriere cuvant de comanda
	MOVX @DPTR, A			;comanda de scriere
cw1:
	PRINT_CR
	PRINT_READY
	RET

READ_STATUS:
	///////////////////////////////////////////////
	//	RUTINA DE CITIRE A CUVANTULUI DE STARE   //
	///////////////////////////////////////////////
;	MOV A, #'U'
;	LCALL RUT_TX
;	MOV DPTR, #MSG_STAT
;	LCALL PRINT_MSG
;	PRINT_CR
;	LCALL READ_STATUS0
;	PRINT_CR
;	PRINT_READY
;	RET
READ_STATUS0:
	MOV DPTR, #MSG_STAT_VAL
	LCALL PRINT_MSG
	MOV DPTR, #rwAD_CW_SW	;incarcare adresa de citire cuvant de stare
	MOVX A, @DPTR			;comanda de citire
	MOV SW, A				;salvare cuvant de stare intern
	LCALL PRINT_BYTE
	MOV A, SW
	PRINT_CR
;VERIFICARE FIECARE BIT AL CUVANTULUI DE STARE
/////bit 0
	MOV DPTR, #MSG_STAT0
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.0, b0
	PRINT_0
	SJMP b1
b0:
	PRINT_1
b1:
	PRINT_CR
//////bit 1
	MOV DPTR, #MSG_STAT1
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.1, b2
	PRINT_0
	SJMP b3
b2:
	PRINT_1
b3:
	PRINT_CR
//////bit 2
	MOV DPTR, #MSG_STAT2
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.2, b4
	PRINT_0
	SJMP b5
b4:
	PRINT_1
b5:
	PRINT_CR
//////bit 3
	MOV DPTR, #MSG_STAT3
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.3, b6
	PRINT_0
	SJMP b7
b6:
	PRINT_1
b7:
	PRINT_CR
/////bit 4
	MOV DPTR, #MSG_STAT4
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.4, b8
	PRINT_0
	SJMP b9
b8:
	PRINT_1
b9:
	PRINT_CR
//////bit 5
	MOV DPTR, #MSG_STAT5
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.5, b10
	PRINT_0
	SJMP b11
b10:
	PRINT_1
b11:
	PRINT_CR
//////bit 6
	MOV DPTR, #MSG_STAT6
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.6, b12
	PRINT_0
	SJMP b13
b12:
	PRINT_1
b13:
	PRINT_CR
//////bit 7
	MOV DPTR, #MSG_STAT7
	LCALL PRINT_MSG
	MOV A, SW
	JB ACC.7, b14
	PRINT_0
	SJMP b15
b14:
	PRINT_1
b15:
	PRINT_CR
	RET

VIEW_STATUS:
	////////////////////////////////////////////
	//	RUTINA DE AFISARE A STARII MODULULUI  //
	////////////////////////////////////////////
	PUSH ACC
	MOV A, #'V'
	LCALL RUT_TX
	MOV DPTR, #MSG_VIEW
	LCALL PRINT_MSG
	PRINT_CR
	LCALL READ_STATUS0
	LCALL READ_CONST0
	LCALL READ_CNT0
	PRINT_CR
	PRINT_READY
	POP ACC
	RET

READ_IN0:
	///////////////////////////////////////////////////
	//	RUTINA DE CITIRE A LINIILOR DE INTRARE I0-7  //
	///////////////////////////////////////////////////
	MOV A, #'Z'
	LCALL RUT_TX
	MOV DPTR, #MSG_IN0
	LCALL PRINT_MSG
	LCALL READ_IN00
	PRINT_CR
	PRINT_READY
	RET
READ_IN00:
	MOV DPTR, #rAD_IN_LSB		;incarcare adresa de citire linii I0-7
	MOVX A, @DPTR				;comanda de citire
	MOV IO_LSB, A				;salvare valoare I0-7 intern
	PRINT_CR
	MOV DPTR, #MSG_IO_VAL
	LCALL PRINT_MSG
	MOV A, IO_LSB
	LCALL PRINT_BYTE
	RET
READ_IN1:
	////////////////////////////////////////////////////
	//	RUTINA DE CITIRE A LINIILOR DE INTRARE I8-15  //
	////////////////////////////////////////////////////
	MOV A, #'X'
	LCALL RUT_TX
	MOV DPTR, #MSG_IN1
	LCALL PRINT_MSG
	LCALL READ_IN10
	PRINT_CR
	PRINT_READY
	RET
READ_IN10:
	MOV DPTR, #rAD_IN_MSB		;incarcare adresa de citire linii I8-15
	MOVX A, @DPTR				;comanda de citire
	MOV IO_MSB, A				;salvare valoare I8-15 intern
	PRINT_CR
	MOV DPTR, #MSG_IO_VAL
	LCALL PRINT_MSG
	MOV A, IO_MSB
	LCALL PRINT_BYTE
	RET
READ_IN2:
	////////////////////////////////////////////////////
	//	RUTINA DE CITIRE A LINIILOR DE INTRARE I0-15  //
	////////////////////////////////////////////////////
	PUSH ACC
	MOV A, #'C'
	LCALL RUT_TX
	MOV DPTR, #MSG_IN2
	LCALL PRINT_MSG
	LCALL READ_IN00
	LCALL READ_IN10
	PRINT_CR
	PRINT_READY
	POP ACC
	RET
	
WRITE_OUT0:
	/////////////////////////////////////////////////////
	//	RUTINA DE SCRIERE A LINIILOR DE IESIRE OUT0-7  //
	/////////////////////////////////////////////////////
	MOV A, #'B'
	LCALL RUT_TX
	MOV DPTR, #MSG_OUT0
	LCALL PRINT_MSG
	LCALL WRITE_OUT00
	PRINT_CR
	PRINT_READY
	RET
WRITE_OUT00:
	MOV DPTR, #wAD_OUT_LSB		;incarcare adresa de scriere linii	OUT0-7
	MOV A, IO_LSB				;incarcare din memoria interna a valorii pt OUT0-7
	MOVX @DPTR, A				;comanda de scriere
	PRINT_CR
	MOV DPTR, #MSG_IO_VAL
	LCALL PRINT_MSG
	MOV A, IO_LSB
	LCALL PRINT_BYTE
	RET
	
WRITE_OUT1:
	//////////////////////////////////////////////////////
	//	RUTINA DE SCRIERE A LINIILOR DE IESIRE OUT8-15  //
	//////////////////////////////////////////////////////
	MOV A, #'N'
	LCALL RUT_TX
	MOV DPTR, #MSG_OUT1
	LCALL PRINT_MSG
	LCALL WRITE_OUT10
	PRINT_CR
	PRINT_READY
	RET
WRITE_OUT10:
	MOV DPTR, #wAD_OUT_MSB		;incarcare adresa de scriere linii	OUT8-15
	MOV A, IO_MSB				;incarcare din memoria interna a valorii pt OUT8-15
	MOVX @DPTR, A				;comanda de scriere
	PRINT_CR
	MOV DPTR, #MSG_IO_VAL
	LCALL PRINT_MSG
	MOV A, IO_MSB
	LCALL PRINT_BYTE
	RET
	
WRITE_OUT2:
	//////////////////////////////////////////////////////
	//	RUTINA DE SCRIERE A LINIILOR DE IESIRE OUT0-15  //
	//////////////////////////////////////////////////////
	PUSH ACC
	MOV A, #'M'
	LCALL RUT_TX
	MOV DPTR, #MSG_OUT2
	LCALL PRINT_MSG
	LCALL WRITE_OUT00
	LCALL WRITE_OUT10
	PRINT_CR
	PRINT_READY
	POP ACC
	RET
PRINT_MSG:
	//////////////////////////////////////
	//	RUTINA DE AFISARE A UNUI MESAJ  //
	//////////////////////////////////////
	PUSH ACC	
	MOV R0, #00h
print0:
	MOV A, R0
	MOVC A, @A+DPTR
	CJNE A, #00h, print1
	POP ACC
	RET
print1:
	LCALL RUT_TX
	INC R0
	SJMP print0

TO_UPR:
	///////////////////////////////////////
	//	RUTINA DE CONVERSIE IN MAJUSCULA //
	///////////////////////////////////////
	CJNE A, #'a', upr0
upr0: 
	JC upr1
	SUBB A, #20h
upr1:
	RET

ASCII_TO_HEX:
	/////////////////////////////////////////////
	//	RUTINA DE CONVERSIE DIN ASCII IN HEXA  //
	/////////////////////////////////////////////
	DEC R0
	DEC R0
	MOV A, @R0
	LCALL CONV_ASCII
	SWAP A
	MOV R1, A
	INC R0
	MOV A, @R0
	LCALL CONV_ASCII
	ADD A, R1
	RET

CONV_ASCII:
	CJNE A, #3Ah, conv0
conv0:
	JC conv1
	SUBB A, #37h
	RET
conv1:
	CLR CY
	SUBB A, #30h
	RET
	
HEX_TO_ASCII:
	////////////////////////////////////////////
	//	RUTINA DE CONVERSIE DIN HEXA IN ASCII //
	////////////////////////////////////////////
	ANL A, #0Fh
	CJNE A, #0Ah, hex0
hex0:
	JC hex1
	ADD A, #37h
	RET
hex1:
	ADD A, #30h
	RET
	
READ_BYTE:
	/////////////////////////////////////////
	//	RUTINA DE CITIRE A CATE UNUI OCTET //
	/////////////////////////////////////////
	MOV R0, #BUFFER
rd0:
	JNB SCON.0, $
	CLR SCON.0
	MOV A, SBUF
	LCALL TO_UPR
	CJNE A, #Quit, rd1
	CLR SCON.0
	RET
rd1:
	LCALL RUT_TX
	MOV @R0, A
	CJNE A, #0Dh, rd2
	RET
rd2:
	CLR SCON.0
	INC R0
	CJNE R0, #0Fh, rd0
	SJMP READ_BYTE

PRINT_BYTE:
	//////////////////////////////////////////
	//	RUTINA DE AFISARE A CATE UNUI OCTET //
	//////////////////////////////////////////
	PUSH ACC
	SWAP A
	LCALL HEX_TO_ASCII
	LCALL RUT_TX
	POP ACC
	LCALL HEX_TO_ASCII
	LCALL RUT_TX
	RET
	
	ORG 6000h
	//////////////////////////////////////////////
	//	MESAJE FOLOSITE IN CADRUL TERMINALULUI  //
	//////////////////////////////////////////////
MSG_WLCM: DB			"PROIECT SISTEME INCORPORATE", 0Dh, 00h
MSG_READY: DB			"READY", 0Dh, 3Eh, 00h
MSG_INT0: DB			0Dh, "Intrerupere generata hard", 0Dh, 00h
MSG_START: DB 			0Dh, "Comanda de start", 0Dh, 00h
MSG_STOP: DB 			0Dh, "Comanda de stop", 0Dh, 00h
MSG_INITIALIZE:	DB		0Dh, "Incarcare constante de numarare", 0Dh, 00h
MSG_LOAD_CNT_LSB: DB	"1. Introduceti valoare LSB (hexa):", 00h
MSG_LOAD_CNT_MB: DB		"2. Introduceti valoare MB (hexa):", 00h
MSG_LOAD_CNT_MSB: DB	"3. Introduceti valoare MSB (hexa):", 00h
;MSG_READ_CNT: DB      	0Dh, "Comanda citire contor", 0Dh, 00h
MSG_CNT_VAL: DB			"Valoare contor:", 00h
MSG_RESET: DB			0Dh,"Comanda Reset", 0Dh, 00h
;MSG_READ_CONST:	DB		0Dh, "Comanda citire constante de incarcare", 0Dh, 00h
MSG_CONST_VAL:   DB		"Valoare presetata:", 00h 	
MSG_CW0: DB				0Dh, "Programare valoarea CC", 00h
MSG_CW1: DB				0Dh, "Introduceti CC (hexa):", 00h
;MSG_STAT: DB			0Dh, "Comanda de citire cuvant de stare",0Dh,00h
MSG_STAT_VAL: DB		"Stare Contor: ", 00h
MSG_STAT0: DB			"Status.0 - Stare Contor:", 00h
MSG_STAT1: DB			"Status.1 - Rezolutie:", 00h
MSG_STAT2: DB			"Status.2 - Sens Numarare:", 00h
MSG_STAT3: DB			"Status.3 - Directie Numarare:", 00h
MSG_STAT4: DB			"Status.4 - Autoincarcare:", 00h
MSG_STAT5: DB			"Status.5 - Fanion /INT0:", 00h
MSG_STAT6: DB			"Status.6 - Strobare grup 1:", 00h
MSG_STAT7: DB			"Status.7 - Strobare grup 2:", 00h
MSG_VIEW: DB			0Dh, "Comanda Vizualizare:", 0Dh, 00h
MSG_IN0: DB				0Dh, "Citire valori linii de intrare I0-7:", 00h
MSG_IN1: DB				0Dh, "Citire valori linii de intrare I8-15:", 00h
MSG_IN2: DB				0Dh, "Citire valori linii de intrare I0-15:", 00h
;MSG_IN0_VAL: DB			"Valoare I0-7:", 00h
;MSG_IN1_VAL: DB			"Valoare I8-15:", 00h
MSG_OUT0: DB			0Dh, "Scriere valori linii de iesire OUT0-7:", 00h
MSG_OUT1: DB			0Dh, "Scriere valori linii de iesire OUT8-15:", 00h
MSG_OUT2: DB			0Dh, "Scriere valori linii de iesire OUT0-15:", 00h
;MSG_OUT0_VAL: DB		"Valoare scrisa la OUT0-7:", 00h
;MSG_OUT1_VAL: DB		"Valoare scrisa la OUT8-15:", 00h
MSG_IO_VAL: DB			"Valoare:", 00h
END