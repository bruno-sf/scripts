#!/bin/bash
#-------------------------------------------------------#
#			Script envia email 		                    #
#-------------------------------------------------------#
#		Data de criacao:04/01/2016		                #
#		Ultima Edicao:09/12/2016		                #
#		Ultima Edicao:08/11/2018		                #
#		Ultima Edicao:30/11/2018		                #
#-------------------------------------------------------#
#Versao: 04                                           	#
#Desenvolvido por: Bruno Ferreira 			            #
#Descricao: Script generico, para envio de emails, pode	#
# ser usado em conjunto com outros scripts.Trabalha com	#
#ate 7 parametros OPCIONAIS na ordem "inner/outter"		# 
#1-CONTEUDO 2-TITULO 3-MAILDESTINO 4-MAILORIGEM 5-EHLO	#
#6-SMTPSRV 7-SMTPPORTA									#
#Requisitos: nc					    					#
#########################################################

#########################
#---INICIO Constantes---#
#########################
#Se os valores nao forem passados, usa o padrao alternativo.
#Se so tiver 2 parametros, assumira como titulo e conteudo alternativo.
ALT_CONTEUDO="Na verdade o espertalhao nao passou parametros... =/" #1)ARG
ALT_TITULO="[BOT INFORMA]" #2)ARG
ALT_DESTINO="bruno.ferreira@XXX.br" #3)ARG
ALT_ORIGEM="botinforma@XXX.br" #4)ARG
ALT_EHLO="mail.seg.XXX.br" #5)ARG
ALT_SRV_SMTP="seg.XXX.br" #6)ARG
ALT_PORTA=25 #7)ARG
######################
#---FIM Constantes---#
######################

#Kind of a parsing time ;)
[ "$1" ] && CONTEUDO=$1 || CONTEUDO=$ALT_CONTEUDO
[ "$2" ] && TITULO=$2 || TITULO=$ALT_TITULO
[ "$3" ] && DESTINO=$3 || DESTINO=$ALT_DESTINO
[ "$4" ] && ORIGEM=$4 || ORIGEM=$ALT_ORIGEM
[ "$5" ] && EHLO=$5 || EHLO=$ALT_EHLO
[ "$6" ] && SRV_SMTP=$6 || SRV_SMTP=$ALT_SRV_SMTP
[ "$7" ] && PORTA=$7 || PORTA=$ALT_PORTA

#####################################
#---INICIO-Funcao enviamail---#
#####################################
#Descricao: Monta email no melhor estilo 0ldSchool ;)
fnmontaemail () {
	echo "ehlo $EHLO"
	echo "MAIL FROM: <$ORIGEM>"
	echo "RCPT TO: <$DESTINO>"
	echo "DATA"
	echo "From: <$ORIGEM>"
	echo "To: <$DESTINO>"
	echo "Date: $(date)"
	echo "Subject: $TITULO"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/plain; charset="UTF-8""
  	echo ""
  	echo ""

    if [ -f "$CONTEUDO" ]; then 
        cat $CONTEUDO;
	else 	
		echo "$CONTEUDO";
	fi
  	echo ""
  	echo ""
  	
	echo "."
	echo "QUIT"
}

function slowcat(){ while read; do sleep .05; echo "$REPLY"; done; }
#########################
#---FIM Funcao enviamail---#
#########################

fnmontaemail | slowcat | nc $SRV_SMTP $PORTA && { echo "###--- [OK] - Email enviado com sucesso! ---###"; exit 0; }

echo "###--- [FALHA] - Erro ao enviar email! ---###"; exit 1;
