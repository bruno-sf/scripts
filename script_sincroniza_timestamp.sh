#!/bin/sh
#-------------------------------------------------------#
#			Script Sync Timestamp 		                #
#-------------------------------------------------------#
#		Data de criacao:28/03/2018		                #
#-------------------------------------------------------#
#Versao:01                                           	#
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

################################
#---Inicio sessao de Funcoes---#
################################

#####################################
#---INICIO-Funcao de echo---#
#####################################
#Descricao:Funcao que padroniza as saidas de texto do programa.
fnecho () {
	echo "###--- $NOME_SCRIPT: $1 ---###"
        return 0
}
#########################
#---FIM Funcao de echo---#
#########################

#####################################
#---INICIO-Funcao path---#
#####################################
#Descricao:Funcao que pega o path do programa.
fnpath () {
        while [ $# -gt 0 ] ; do
        [ -z $1 ]  && break;
                if [ which -a $1 > /dev/null ]; 
		then
	                shift
		else
			 fnecho "Um dos programas ($PROGS) nao foi encontrado!";
			 return 1;
		fi
	done
        return 0
}
#########################
#---FIM Funcao path---#
#########################

#####################################
#---INICIO-Funcao sair---#
#####################################
#Descricao:Funcao que executa checagem, limpeza, e outros antes de sair.
fnsair () {
	CODIGO="$1"
	case $CODIGO in
	0)
		fnecho "Saindo tudo ok..."
    	;;
	1)
		fnecho "Ok, saindo por decisao do usuario..."
    	;;
	2)
        fnecho "Erro, use apenas 2 parametros <PATHORIGEM> <PATHDESTINO>."
        ;;
	3)
        fnecho "Erro, diretorio invalido."
        ;;
	*)
		fnecho "Erro das trevas, fuja para as montanhas!"
    	;;
	esac

    [ -e $TMP_ORIGEM -a -e $TMP_DESTINO	] && rm -f $TMP_ORIGEM $TMP_DESTINO	$TMP_FINAL
	
    exit $CODIGO;
    return 0
}
#########################
#---FIM Funcao sair---#
#########################

#################################
#---Termino sessao de funcoes---#
#################################

##########################
#---INICIO do programa---#
##########################
clear
fnpath $PROGS || fnsair 9

if [ $QTD_PAR -ne 2 ]; then fnsair 2; fi
PATH_ORIGEM=$1
PATH_DESTINO=$2

[ -d "$PATH_ORIGEM" ] || fnsair 3
[ -d "$PATH_DESTINO" ] || fnsair 3

fnecho "Path Origem está correto? Origem: $PATH_ORIGEM"
fnecho "Path Destino está correto? Destino: $PATH_DESTINO"
read -p "Deseja continuar [S/n]" ESCOLHA
[ "$ESCOLHA" ] || ESCOLHA="S"

if [ $ESCOLHA = "S" ]; then 
	find "$PATH_ORIGEM" -type f | sort -o "$TMP_ORIGEM" || fnsair 4
	find "$PATH_DESTINO" -type f | sort -o "$TMP_DESTINO" || fnsair 5
	[ -f $TMP_ORIGEM ] || fnsair 7
	[ -f $TMP_DESTINO ] || fnsair 8

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
        [ "$HASH1" = "$HASH2" ] || break; 
        test "$ARQ_ORIGEM" -ot "$ARQ_DESTINO" && touch -r "$ARQ_ORIGEM" "$ARQ_DESTINO";

    done < $TMP_FINAL 
	
else

	fnsair 1

fi
fnsair 0
