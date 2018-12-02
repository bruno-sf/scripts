#!/bin/bash
#-------------------------------------------------------#
#			Script Sync Timestamp 		                #
#-------------------------------------------------------#
#		Data de criacao:28/03/2018		                #
#		Ultima Edicao:01/12/2018		                #
#-------------------------------------------------------#
#Versao: 02                                           	#
#Desenvolvido por:Bruno Ferreira 			            #
#Bugs e Correcoes:brunosilvaferreiraf@protonmail.com	#
#-------------------------------------------------------#
# Descricao: Script para sincronizar os timestamp entre	#
# arquivos iguais, util para usar com FreeFileSync 	    #
# Ex.: ./script.sh <PATHORIGEM> <PATHDESTINO>		    #
# O script realizara uma busca no path origem arquivo   #
# arquivo por arquivo e pesquisara o mesmo arquivo no	#
# PATHDESTINO caso o arquivo exista, mudara o timestamp	#
# para o mesmo do arquivo em PATHORIGEM.		        #
#-------------------------------------------------------#
#########################################################
#-------------------------------------------------------#
#########################################################
#Carrega funcoes genericas
BIBLIOTECA="/home/brunof/scripts/biblioteca_generica.sh"
BIBLIOTECA="biblioteca_generica.sh"
source $BIBLIOTECA > /dev/null 2>&1 || { echo "Erro ao carregar $BIBLIOTECA."; exit 101; }
#########################
#---INICIO Constantes---#
#########################
NOME_SCRIPT="Script Sync TimeStamp"
PROGS="touch grep find md5sum paste"
QTD_PAR=$#
TMP_ORIGEM="/tmp/origem$$"
TMP_DESTINO="/tmp/destino$$"
TMP_FINAL="/tmp/final$$"
######################
#---FIM Constantes---#
######################

clear
fnpath $PROGS || fnsair 9

if [ $QTD_PAR -ne 2 ]; then fnsair 1 "Faltam argumentos!"; fi
PATH_ORIGEM="$1"
PATH_DESTINO="$2"

[ -d "$PATH_ORIGEM" ] || fnsair 1 "Caminho invalido! $PATH_ORIGEM"
[ -d "$PATH_DESTINO" ] || fnsair 1 "Caminho invalido! $PATH_DESTINO"

fnecho "ATENCAO!"
fnecho "Confirme se a Origem está correta: $PATH_ORIGEM"
fnecho "Confirme se o Destino está correto: $PATH_DESTINO"
read -p "Deseja continuar [S/n]" ESCOLHA
[ "$ESCOLHA" ] || ESCOLHA="S" #Se der ENTER vai que vai ;)

if [ $ESCOLHA = "S" ]; then 
	find "$PATH_ORIGEM" -type f | sort -o "$TMP_ORIGEM"; [ -f $TMP_ORIGEM ] || fnsair 7
	find "$PATH_DESTINO" -type f | sort -o "$TMP_DESTINO"; [ -f $TMP_DESTINO ] || fnsair 8
	
	QTD_ORIGEM=`wc -l $TMP_ORIGEM | cut -d " " -f1`
	QTD_DESTINO=`wc -l $TMP_DESTINO | cut -d " " -f1`

    if [ $QTD_ORIGEM -ne $QTD_DESTINO ]; then
        fnecho "Atencao: Os diretorios tem arquivos diferentes, recomenda-se nao continuar!"
        read -p "Se deseja continuar escreva SIM" ESCOLHA
        [ $ESCOLHA != "SIM" ] && fnsair 1
    fi
    fnecho "Quantidade de arquivos encontrados nos diretorios: $QTD_ORIGEM"
    paste -d";" $TMP_ORIGEM $TMP_DESTINO > $TMP_FINAL

	while read LINHA; 
    do 

        ARQ_ORIGEM=`printf "$LINHA" | cut -d";" -f1`;
        ARQ_DESTINO=`printf "$LINHA" | cut -d";" -f2`;
        HASH1=`md5sum "$ARQ_ORIGEM" | cut -d" " -f1`;
        HASH2=`md5sum "$ARQ_DESTINO" | cut -d" " -f1`;
        if [ "$HASH1" = "$HASH2" ]; then
            test "$ARQ_ORIGEM" -ot "$ARQ_DESTINO" && touch -r "$ARQ_ORIGEM" "$ARQ_DESTINO" && fnecho "Sync feito $ARQ_ORIGEM -> $ARQ_DESTINO" ;
        else
            fnecho "Ops...Par de arquivos diferentes, pulando..."
            break; 
        fi
    done < $TMP_FINAL 
else
	fnsair 1 "Opcao invalida."
fi
fnsair 0
