#!/bin/bash
#-------------------------------------------------------------------#
#                   Script Meu IP Publico                           #
#-------------------------------------------------------------------#
#       Data de criacao:08/10/2018 - Ultima Edicao: 11/06/2021      #
#-------------------------------------------------------------------#
# Versao: 2 - Autor: brunosilvaferreira@protonmail.com              #
#-------------------------------------------------------------------#
# Descricao: Retorna o IP pub. Perfeito em combinacao com bash      #
# aliases exemplo: @net_meu_ip='script_meu_ip_pub.sh'               #
# Chama a funcao em 3 servicos diferentes, aleatoriamente, dentro   #
# do array, comparando se os ips sao iguais em pelo menos 2 results #
#-------------------------------------------------------------------#

ARRAY_SITES=("http://whatismyip.akamai.com/" 
            "https://checkip.amazonaws.com" 
            "www.icanhazip.com" "ipinfo.io/ip" 
            "http://ip.42.pl/raw" 
            "ifconfig.me/ip" 
            "https://api.ipify.org/")

fn_array_meu_ip () {
	ARRAY_LEN=${#ARRAY_SITES[@]}
	RANDOM_INT=$(( (RANDOM % ${ARRAY_LEN}) ))
	RANDOM_SITE=( "${ARRAY_SITES[${RANDOM_INT}]}" )
	curl -s -m 10 ${RANDOM_SITE}
}

IP1=$( fn_array_meu_ip )
IP2=$( fn_array_meu_ip )
IP3=$( fn_array_meu_ip )
[ "$IP1" == "$IP2" ] && echo $IP1 && exit 0
[ "$IP1" == "$IP3" ] && echo $IP1 && exit 0
[ "$IP2" == "$IP3" ] && echo $IP2 && exit 0
echo "Fail" && exit 1
