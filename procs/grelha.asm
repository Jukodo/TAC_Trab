.8086
.model small
.stack 2048

dseg	segment para public 'data'
	;|||||||||||||||||||| (start) Cursor |||||||||||||||||||| 
	string	db	"Teste pr�tico de T.I",0
	Car		db	32	; Guarda um caracter do Ecran 
	Cor		db	7	; Guarda os atributos de cor do caracter
	Car2		db	32	; Guarda um caracter do Ecran 
	Cor2		db	7	; Guarda os atributos de cor do caracter
	POSy		db	8	; a linha pode ir de [1 .. 25] (val: posi��o inicial)
	POSx		db	30	; POSx pode ir [1..80] (val: posi��o inicial)
	POSya		db	8	; Posi��o anterior de y
	POSxa		db	30	; Posi��o anterior de x
	;|||||||||||||||||||| (end) Cursor |||||||||||||||||||| 
	;|||||||||||||||||||| (start) CriarFich ||||||||||||||||||||
	fname	db	'grelha.txt',0
	fhandle dw	0
	buffer	db 114 dup(0)
	msgErrorCreate	db	"Ocorreu um erro na criacao do ficheiro!$"
	msgErrorWrite	db	"Ocorreu um erro na escrita para ficheiro!$"
	msgErrorClose	db	"Ocorreu um erro no fecho do ficheiro!$"
	;|||||||||||||||||||| (end) CriarFich |||||||||||||||||||| 
	;|||||||||||||||||||| (start) LerFich |||||||||||||||||||| 
	msgErrorOpen       db      'Erro ao tentar abrir o ficheiro$'
	msgErrorRead    db      'Erro ao tentar ler do ficheiro$'
	fname_ler         	db      'grelha.TXT',0
	car_fich        db      ?
	;|||||||||||||||||||| (end) LerFich |||||||||||||||||||| 
	;|||||||||||||||||||| (start) Tabuleiro |||||||||||||||||||| 
	ultimo_num_aleat dw 0
	str_num db 5 dup(?),'$'
	linha		db	0	; Define o n�mero da linha que est� a ser desenhada
	nlinhas		db	0
	tab_cor		db 	0
	tab_car		db	' '	
	
	max_linhas		db 6
	max_colunas 	db 9
	
	;|||||||||||||||||||| (end) Tabuleiro |||||||||||||||||||| 
dseg	ends

cseg	segment para public 'code'
assume		cs:cseg, ds:dseg


;|||||||||||||||||||| (start) Cursor |||||||||||||||||||| 
;########################################################################
goto_xy	macro		POSx,POSy
		mov		ah,02h
		mov		bh,0		; numero da p�gina
		mov		dl,POSx
		mov		dh,POSy
		int		10h
endm

;########################################################################
;ROTINA PARA APAGAR ECRAN

func_limpaEcran	proc
		xor		bx,bx
		mov		cx,25*80
		
apaga:			
		mov	byte ptr es:[bx],' '
		mov		byte ptr es:[bx+1],7
		inc		bx
		inc 		bx
		loop		apaga
		ret
func_limpaEcran	endp


;########################################################################
; LE UMA TECLA	

func_leTecla	PROC

		mov		ah,08h
		int		21h
		mov		ah,0
		cmp		al,0
		jne		SAI_TECLA
		mov		ah, 08h
		int		21h
		mov		ah,1
SAI_TECLA:	RET
func_leTecla	endp
;########################################################################


;----------------------------------------(start) func_colorsToBuffer ----------------------------------------
;Params	: 	buffer, max_colunas, max_linhas
;Func	:	Percorre todas as c�lulas da grelha e escreve, em formato de grelha(9x6), as cores no buffer para escrever no ficheiro

;AL 	: 	Cor da c�lula
;AH		: 	Cor da c�lula convertida ou \n. Argumento para escrever no buffer
;BX 	:	Endere�os da mem. video
;CH 	: 	Contador de c�lulas percorridas
;CH 	: 	Contador de linhas percorridas

func_colorsToBuffer proc

	xor ax, ax
	xor bx, bx 
	xor cx, cx
	xor si, si

	mov bx, 1340
	
	cycle:
	
		mov	al, es:[bx+1]
		mov byte ptr es:[bx+2], '1'
		call func_makeDelay

		;swtich(ah):
		;	case 00064: ah = 2 (red)
		;	case 00080: ah = 3 (pink)
		;	case 00048: ah = 4 (lblue)
		;	case 00032: ah = 5 (green)
		;	case 00096: ah = 6 (orange)
		;	case 00112: ah = 7 (white)
		;	default : (00016) ah = 8 (blue)
			
			
		convert_color:
		
			cmp al, 00064  ; AL � red?
			jne pink
		
			red:
				mov ah, 2
				jmp addTobuffer
				
			pink:
				cmp al, 00080 
				jne lblue
				mov ah, 3
				jmp addTobuffer
				
			lblue:
				cmp al, 00048 
				jne green
				mov ah, 4
				jmp addTobuffer
			
			green:
				cmp al, 00032 
				jne orange
				mov ah, 5
				jmp addTobuffer
			
			orange:
				cmp al, 00096 
				jne white
				mov ah, 6
				jmp addTobuffer
			
			white:
				cmp al, 00112 
				jne blue
				mov ah, 7
				jmp addTobuffer
				
			blue: ;00016
				mov ah, 8
				jmp addTobuffer
			
		
		addTobuffer:;Adiciona uma cor e um espa�o nas respetivas posicoes no buffer
	
			add ah, '0';Converte numero para string
			MOV buffer[si], ah
			
			mov ah, 32; space
			mov buffer[si+1], ah;Entre cada cor escreve um espa�o
			
			add si, 2;Ap�s escrever o espa�o vai para pr�xima posi��o para escrever a pr�xima cor
			
			jmp next_cell
		
		

		next_cell:;Le a celula seguinte
		
		add bx, 4 ;Anda para a celula da direita
		inc ch; N� de c�lulas percorridas
		cmp ch, max_colunas
		jge next_line; Se j� leu o tamanho m�ximo de celulas que pode ler muda de linha
		jmp cycle; Se n�o le a pr�xima celula
		
		next_line:;Salta para a 1� celula de linha seguinte
		
		mov ah, 13; carriage return
		mov buffer[si-2], ah; carriage return no fim da linha
		mov ah, 10; new line
		mov buffer[si-1], ah; entre cada linha vai haver um \n
		
		inc cl; N� de linhas percorridas
		cmp cl, max_linhas
		jge fim; Se j� leu o tamanho m�ximo de linhas que pode ler, termina
		add bx, 160; Muda de linha, mas fica na ultima coluna
		sub bx, 36; Vai para a 1� coluna da nova linha
		mov ch, 0; Renicia a contagem das c�lulas pois estamos numa nova linha
		jmp cycle; Vai ler a pr�xima c�lula (1� celula da linha nova)
		
		fim:
			ret
		
func_colorsToBuffer endp

;----------------------------------------(end) func_colorsToBuffer ----------------------------------------

func_moveCursor  proc
		;;PROG STARTS HERE
		mov		ax, dseg
		mov		ds,ax
		;;||||||||||||||||
		
		mov		ax,0B800h
		mov		es,ax
	
		call func_limpaEcran
		call func_readFile
		call func_drawTabuleiro
		
		goto_xy		POSx,POSy	; Vai para nova possi��o
		mov 		ah, 08h	; Guarda o Caracter que est� na posi��o do Cursor
		mov		bh,0		; numero da p�gina
		int		10h			
		mov		Car, al	; Guarda o Caracter que est� na posi��o do Cursor
		mov		Cor, ah	; Guarda a cor que est� na posi��o do Cursor	
		
		inc		POSx
		goto_xy		POSx,POSy	; Vai para nova possi��o2
		mov 		ah, 08h		; Guarda o Caracter que est� na posi��o do Cursor
		mov		bh,0		; numero da p�gina
		int		10h			
		mov		Car2, al	; Guarda o Caracter que est� na posi��o do Cursor
		mov		Cor2, ah	; Guarda a cor que est� na posi��o do Cursor	
		dec		POSx
	

CICLO:		goto_xy	POSxa,POSya	; Vai para a posi��o anterior do cursor
		mov		ah, 02h
		mov		dl, Car	; Repoe Caracter guardado 
		int		21H	

		inc		POSxa
		goto_xy		POSxa,POSya	
		mov		ah, 02h
		mov		dl, Car2	; Repoe Caracter2 guardado 
		int		21H	
		dec 		POSxa
		
		goto_xy	POSx,POSy	; Vai para nova possi��o
		mov 		ah, 08h
		mov		bh,0		; numero da p�gina
		int		10h		
		mov		Car, al	; Guarda o Caracter que est� na posi��o do Cursor
		mov		Cor, ah	; Guarda a cor que est� na posi��o do Cursor
		
		inc		POSx
		goto_xy		POSx,POSy	; Vai para nova possi��o
		mov 		ah, 08h
		mov		bh,0		; numero da p�gina
		int		10h		
		mov		Car2, al	; Guarda o Caracter2 que est� na posi��o do Cursor2
		mov		Cor2, ah	; Guarda a cor que est� na posi��o do Cursor2
		dec		POSx
		
		
		goto_xy		77,0		; Mostra o caractr que estava na posi��o do AVATAR
		mov		ah, 02h		; IMPRIME caracter da posi��o no canto
		mov		dl, Car	
		int		21H			
		
		goto_xy		78,0		; Mostra o caractr2 que estava na posi��o do AVATAR
		mov		ah, 02h		; IMPRIME caracter2 da posi��o no canto
		mov		dl, Car2	
		int		21H			
		
	
		goto_xy		POSx,POSy	; Vai para posi��o do cursor
IMPRIME:	mov		ah, 02h
		mov		dl, '('	; Coloca AVATAR1
		int		21H
		
		inc		POSx
		goto_xy		POSx,POSy		
		mov		ah, 02h
		mov		dl, ')'	; Coloca AVATAR2
		int		21H	
		dec		POSx
		
		goto_xy		POSx,POSy	; Vai para posi��o do cursor
		
		mov		al, POSx	; Guarda a posi��o do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posi��o do cursor
		mov 		POSya, al
		
LER_SETA:	call 		func_leTecla
		cmp		ah, 1
		je		ESTEND
		cmp 		al, 27	; ESCAPE
		je		fim
		;cmp 		al, 13	; ENTER
		;je		func_explode
		jmp		LER_SETA
		
ESTEND:		
		cmp 		al,48h
		jne		BAIXO
		;if (POSy <= 9){ break; }
			cmp 	POSy, 8
			jle 		CICLO
		dec		POSy		;cima
		jmp		CICLO

BAIXO:		cmp		al,50h
		jne		ESQUERDA
		;if (POSy >= 14){ break; }
			cmp 	POSy, 13
			jge 		CICLO
		inc 	POSy		;Baixo
		jmp		CICLO

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		;if (POSx <= 31){ break; }
			cmp 	POSx, 30
			jle 		CICLO
		dec		POSx		;Esquerda
		dec		POSx		;Esquerda

		jmp		CICLO

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA 
		;if (POSx >= 48){ break; }
			cmp 	POSx, 46
			jge 		CICLO
		inc		POSx		;Direita
		inc		POSx		;Direita
		
		jmp		CICLO

fim:
		call func_colorsToBuffer
		call func_makeFile
		call func_limpaEcran
		mov		ah,4CH
		INT		21H
func_moveCursor	endp
;|||||||||||||||||||| (end) Cursor |||||||||||||||||||| 
;|||||||||||||||||||| (start) CriarFich ||||||||||||||||||||
func_makeFile proc
		;MOV		AX, DADOS
		;MOV		DS, AX
	
		mov		ah, 3ch				; Abrir o ficheiro para escrita
		mov		cx, 00H				; Define o tipo de ficheiro ??
		lea		dx, fname			; DX aponta para o nome do ficheiro 
		int		21h					; Abre efectivamente o ficheiro (AX fica com o Handle do ficheiro)
		jnc		escreve				; Se n�o existir erro escreve no ficheiro
	
		mov		ah, 09h
		lea		dx, msgErrorCreate
		int		21h
	
		jmp		return_MF

escreve:
		mov		bx, ax				; Coloca em BX o Handle
    	mov		ah, 40h				; indica que � para escrever
    	
		lea		dx, buffer			; DX aponta para a infroma��o a escrever
    	mov		cx, 116				; CX fica com o numero de bytes a escrever
		int		21h					; Chama a rotina de escrita
		jnc		close				; Se n�o existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, msgErrorWrite
		int		21h
close:
		mov		ah,3eh				; fecha o ficheiro
		int		21h
		jnc		return_MF
	
		mov		ah, 09h
		lea		dx, msgErrorClose
		int		21h
return_MF:
		RET
		;MOV		AH,4CH
		;INT		21H
func_makeFile	endp
;|||||||||||||||||||| (end) CriarFich ||||||||||||||||||||
;|||||||||||||||||||| (start) LerFich |||||||||||||||||||| 
func_printTextFile	PROC

;abre ficheiro

        mov     ah,3dh			; vamos abrir ficheiro para leitura 
        mov     al,0			; tipo de ficheiro	
        lea     dx,fname_ler			; nome do ficheiro
        int     21h			; abre para leitura 
        jc      erro_abrir		; pode aconter erro a abrir o ficheiro 
        mov     fhandle,ax		; ax devolve o Handle para o ficheiro 
        jmp     ler_ciclo		; depois de abero vamos ler o ficheiro 

erro_abrir:
        mov     ah,09h
        lea     dx,msgErrorOpen
        int     21h
        jmp     sai

ler_ciclo:
        mov     ah,3fh			; indica que vai ser lido um ficheiro 
        mov     bx,fhandle		; bx deve conter o Handle do ficheiro previamente aberto 
        mov     cx,1			; numero de bytes a ler 
        lea     dx,car_fich		; vai ler para o local de memoria apontado por dx (car_fich)
        int     21h				; faz efectivamente a leitura
	jc	    erro_ler		; se carry � porque aconteceu um erro
	cmp	    ax,0			;EOF?	verifica se j� estamos no fim do ficheiro 
	je	    fecha_ficheiro	; se EOF fecha o ficheiro 
        mov     ah,02h			; coloca o caracter no ecran
	  mov	    dl,car_fich		; este � o caracter a enviar para o ecran
	  int	    21h				; imprime no ecran
	  jmp	    ler_ciclo		; continua a ler o ficheiro

erro_ler:
        mov     ah,09h
        lea     dx,msgErrorRead
        int     21h

fecha_ficheiro:					; vamos fechar o ficheiro 
        mov     ah,3eh
        mov     bx,fhandle
        int     21h
        jnc     sai

        mov     ah,09h			; o ficheiro pode n�o fechar correctamente
        lea     dx,msgErrorClose
        Int     21h
sai:	  RET
func_printTextFile	endp


;########################################################################

func_readFile  proc
	call	func_limpaEcran
	goto_xy	1,1
	call	func_printTextFile

		goto_xy	2,22
		;mov	ah,4CH
		;INT	21H
		ret
func_readFile	endp
;|||||||||||||||||||| (end) LerFich |||||||||||||||||||| 
;|||||||||||||||||||| (start) Tabuleiro ||||||||||||||||||||

func_drawTabuleiro PROC
	;MOV	AX, DADOS
	;MOV	DS, AX
	
	;mov		ax, dseg
	;mov		ds,ax
	
	xor si, si
	mov	cx,10		; Faz o ciclo 10 vezes
ciclo4:
		call	func_getRandom
		pop	ax 		; vai bustab_car 'a pilha o n�mero aleat�rio

		mov	dl,cl	
		mov	dh,70
		push	dx		; Passagem de par�metros a func_printNum (posi��o do ecran)
		push	ax		; Passagem de par�metros a func_printNum (n�mero a imprimir)
		call	func_printNum		; imprime 10 aleat�rios na parte direita do ecran
		loop	ciclo4		; Ciclo de impress�o dos n�meros aleat�rios
		
		mov   	ax, 0b800h	; Segmento de mem�ria de v�deo onde vai ser desenhado o tabuleiro
		mov   	es, ax	
		mov	linha, 	8	; O Tabuleiro vai come�ar a ser desenhado na linha 8 
		mov	nlinhas, 6	; O Tabuleiro vai ter 6 linhas
		
ciclo2:		mov	al, 160		
		mov	ah, linha
		mul	ah
		add	ax, 60
		mov 	bx, ax		; Determina Endere�o onde come�a a "linha". bx = 160*linha + 60

		mov	cx, 9		; S�o 9 colunas 
ciclo1:  	
		mov 	dh,	tab_car	; vai imprimir o tab_caracter "SAPCE"
		mov	es:[bx],dh	;
	
novatab_cor:	
		call	func_getRandom	; Calcula pr�ximo aleat�rio que � colocado na pinha 
		pop	ax ; 		; Vai bustab_car 'a pilha o n�mero aleat�rio
		and 	al,01110000b	; posi��o do ecran com tab_cor de fundo aleat�rio e tab_caracter a preto
		cmp	al, 0		; Se o fundo de ecran � preto
		je	novatab_cor		; vai bustab_car outra tab_cor

		mov 	dh,	   tab_car	; Repete mais uma vez porque cada pe�a do tabuleiro ocupa dois tab_carecteres de ecran
		mov	es:[bx],   dh
		mov	es:[bx+1], al	; Coloca as tab_caracter�sticas de tab_cor da posi��o atual
		push bx

		pop bx
		
		inc	bx		
		inc	bx		; pr�xima posi��o e ecran dois bytes � frente 

		mov 	dh,	   tab_car	; Repete mais uma vez porque cada pe�a do tabuleiro ocupa dois tab_carecteres de ecran
		mov	es:[bx],   dh
		mov	es:[bx+1], al
		inc	bx
		inc	bx
		
	
		
		mov	di,1 ;func_makeDelay de 1 centesimo de segundo
		;;call	func_makeDelay
		loop	ciclo1		; continua at� fazer as 9 colunas que tab_correspondem a uma liha completa
		
		inc	linha		; Vai desenhar a pr�xima linha
		dec	nlinhas		; contador de linhas
		mov	al, nlinhas
		cmp	al, 0		; verifica se j� desenhou todas as linhas
		jne	ciclo2		; se ainda h� linhas a desenhar continua 
return_PROC:

	ret
func_drawTabuleiro ENDP

;------------------------------------------------------
;func_getRandom - calcula um numero aleatorio de 16 bits
;Parametros passados pela pilha
;entrada:
;n�o tem parametros de entrada
;saida:
;param1 - 16 bits - numero aleatorio calculado
;notas adicionais:
; deve estar definida uma variavel => ultimo_num_aleat dw 0
; assume-se que DS esta a apontar para o segmento onde esta armazenada ultimo_num_aleat
func_getRandom proc near

	sub	sp,2		; 
	push	bp
	mov	bp,sp
	push	ax
	push	cx
	push	dx	
	mov	ax,[bp+4]
	mov	[bp+2],ax

	mov	ah,00h
	int	1ah

	add	dx,ultimo_num_aleat	; vai bustab_car o aleat�rio anterior
	add	cx,dx	
	mov	ax,65521
	push	dx
	mul	cx			
	pop	dx			 
	xchg	dl,dh
	add	dx,32749
	add	dx,ax

	mov	ultimo_num_aleat,dx	; guarda o novo numero aleat�rio  

	mov	[BP+4],dx		; o aleat�rio � passado por pilha

	pop	dx
	pop	cx
	pop	ax
	pop	bp
	ret
func_getRandom endp

;------------------------------------------------------
;func_printNum - imprime um numero de 16 bits na posicao x,y
;Parametros passados pela pilha
;entrada:
;param1 -  8 bits - posicao x
;param2 -  8 bits - posicao y
;param3 - 16 bits - numero a imprimir
;saida:
;n�o tem parametros de sa�da
;notas adicionais:
; deve estar definida uma variavel => str_num db 5 dup(?),'$'
; assume-se que DS esta a apontar para o segmento onde esta armazenada str_num
; sao eliminados da pilha os parametros de entrada
func_printNum proc near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	mov	ax,[bp+4] ;param3
	lea	di,[str_num+5]
	mov	cx,5
prox_dig:
	xor	dx,dx
	mov	bx,10
	div	bx
	add	dl,'0' ; dh e' sempre 0
	dec	di
	mov	[di],dl
	loop	prox_dig

	mov	ah,02h
	mov	bh,00h
	mov	dl,[bp+7] ;param1
	mov	dh,[bp+6] ;param2
	int	10h
	mov	dx,di
	mov	ah,09h
	int	21h
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	4 ;limpa parametros (4 bytes) colocados na pilha
func_printNum endp






;recebe em di o n�mero de milisegundos a esperar
func_makeDelay proc
	pushf
	push	ax
	push	cx
	push	dx
	push	si
	
	mov	ah,2Ch
	int	21h
	mov	al,100
	mul	dh
	xor	dh,dh
	add	ax,dx
	mov	si,ax


ciclo99:	mov	ah,2Ch
	int	21h
	mov	al,100
	mul	dh
	xor	dh,dh
	add	ax,dx

	cmp	ax,si 
	jnb	naoajusta
	add	ax,6000 ; 60 segundos
naoajusta:
	sub	ax,si
	cmp	ax,di
	jb	ciclo99

	pop	si
	pop	dx
	pop	cx
	pop	ax
	popf
	ret
func_makeDelay endp
;|||||||||||||||||||| (end) Tabuleiro |||||||||||||||||||| 
Cseg	ends
end	func_moveCursor