#!/bin/sh
#-------------------------------------------------------#
#			Script Meu IP Publico  						#
#-------------------------------------------------------#
#		Data de criacao:08/10/2018						#
#		Ultima Edicao:xx/yy/2018						#
#-------------------------------------------------------#
#Versao:01                                           	#
#Bugs e Correcoes:brunosilvaferreira@protonmail.com 	#
#-------------------------------------------------------#
#Descricao:Retorna o IP pub. Use com cautela ;)        	#
#-------------------------------------------------------#
#Requisitos:curl dig				    				#
#########################################################

#---INICIO Constantes---#
NOME_SCRIPT="Script Meu IP Publico"
PROGS="curl dig"
SITE="http://ip.42.pl/raw"
DNS="+short myip.opendns.com @resolver1.opendns.com"
IP=""
#---FIM Constantes---#

#---INICIO-Funcao echo---#
#Descricao:Funcao que padroniza as saidas de texto do programa.
fnecho () {
	echo "###--- $NOME_SCRIPT: $1 ---###"
        return 0
}
#---FIM Funcao de echo---#

#---INICIO-Funcao meuip---#
#Descricao:Tenta pegar pelo metodo 1 caso nao consiga tenta o metodo 2.
fnmeuip () {
	#Metodo 1 - SITE
	IP=$(curl -s $SITE)
	IP_LEN=${#IP}
	[ $IP_LEN -ne 0 ] && return 0
#	IP=${IP:="erro"}
#	[ $IP != "erro" ] && return 0

	#Metodo 2 - DNS
	IP=$(dig $DNS)
	IP_LEN=${#IP}
	[ $IP_LEN -ne 0 ] && return 0

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
fnmeuip || exit 1
echo $IP && exit 0
