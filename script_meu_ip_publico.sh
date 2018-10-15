#!/bin/sh
#-------------------------------------------------------#
#		Script Meu IP Publico	  		#
#-------------------------------------------------------#
#		Data de criacao:08/10/2018		#
#-------------------------------------------------------#
#Versao: 02                                           	#
#Bugs e Correcoes: brunosilvaferreira@protonmail.com 	#
#-------------------------------------------------------#
#Descricao: Retorna o IP pub. Use com cautela ;)       	#
#-------------------------------------------------------#
#Requisitos: curl dig	    				#
#########################################################

#---INICIO Constantes---#
NOME_SCRIPT="Script Meu IP Publico"
PROGS="curl dig"
SITE="http://ip.42.pl/raw"
DNS="+short myip.opendns.com @resolver1.opendns.com"
IP=""
#---FIM Constantes---#

#---INICIO-Funcao meuip---#
#Descricao:Tenta pegar pelo metodo 1 caso nao consiga tenta o metodo 2.
fnmeuip () {
	#Metodo 1 - DNS
	IP="$(dig $DNS)" #| sed -e 's/[^[:alnum:]]//g')"
	IP_LEN=${#IP}
	[ $IP_LEN -ne 0 -a $IP_LEN -lt 16 ] && { echo $IP ; return 0; }

	return 1
}
fnmeuip2 () {
	#Metodo 2 - WWW
	IP="$(curl -s $SITE)" #| sed -e 's/[^[:alnum:]]//g')"
	IP_LEN=${#IP}
	[ $IP_LEN -ne 0 -a $IP_LEN -lt 16 ] && { echo $IP ; return 0; }

	return 1
}	

#---INICIO-Funcao path---#
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
#---FIM Funcao path---#

clear
fnpath $PROGS || exit 1
fnmeuip || fnmeuip2 || exit 1
exit 0
