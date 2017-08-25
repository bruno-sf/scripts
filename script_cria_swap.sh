#!/bin/sh
#-------------------------------------------------------#
#			Script xxxxxx	 		#
#-------------------------------------------------------#
#		Data de criacao:24/08/2017		#
#		Ultima Edicao:xx/yy/xxxx		#
#-------------------------------------------------------#
#Versao:02                                           	#
#Desenvolvido por:Bruno Ferreira 			#
#-------------------------------------------------------#
#Descricao:Cria swap de acordo com parametro passado.  	#
#Pode ser instalado na inicializacao rc.local		#
#ex. PAR1=PATH PAR2=Tamanho em GB			#
#Ex: Criando um arquivo SWAP de 8Gb			#
#./script_cria_swap /tmp/MEUSWP.bin 8			#
#-------------------------------------------------------#
#Requisitos:swapon mkswap chmod dd		    	#
#########################################################
#-------------------------------------------------------#
#########################################################

#########################
#---INICIO Constantes---#
#########################
NOME_SCRIPT="Script Cria Swap"
PROGS="swapon mkswap chmod dd"
ARQUIVOSWP=$1
TAMANHO=$2
######################
#---FIM Constantes---#
######################

#########################
#---INICIO das Chaves---#
#########################
#CHAVES (0-OK / 1- Erro)
CHAVE_EXCESSAO=0
CHAVE_ERRO=0
######################
#---FIM das Chaves---#
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
#---INICIO-Funcao logger---#
#####################################
#Descricao:Funcao que padroniza as saidas de log do programa.
fnlog () {
        logger -p daemon.info "###--- $NOME_SCRIPT: $1 ---###"
        return 0
}
#########################
#---FIM Funcao logger---#
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
		#rm -f arquivostemporarios
	;;
	1)
		fnecho "Erro, saindo..."
	;;
	*)
		fnecho "Erro das trevas, fuja para as montanhas!"
	;;
	esac
	
	exit $CODIGO;
        return 0
}
#########################
#---FIM Funcao sair---#
#########################

#####################################
#---INICIO-Funcao root---#
#####################################
#Descricao:Em alguns casos vale a pena limitar o uso de scripts somente para o usuario root.Se este for o caso chame esta funcao no inicio do programa.
fnroot () {
	#Verifica se e root
	if [ $(id -u) != "0" ];
        then
        	fnecho "Apenas root!" >&2
        	return 1
	fi
return 0
}
#########################
#---FIM Funcao root---#
#########################

#####################################
#---INICIO-Funcao nohup---#
#####################################
#Descricao:Chama alguma tarefa que pode cair em condicao de hangup e perder o terminal
fnnohup () {
	PROGRAMA=$*
	nohup $PROGRAMA > nohup.out 2> nohup.err < /dev/null &
	NOHUP_PID=$!

return 0
}
#########################
#---FIM Funcao nohup---#
#########################

#################################
#---Termino sessao de funcoes---#
#################################


##########################
#---INICIO do programa---#
##########################

#Se precisar ser root, descomente a linha abaixo ;)
fnroot || fnsair 1
fnpath $PROGS || fnsair 1

#######################
#---Codigo AQUI---#
#######################
#Checa parametros
if [ -e "$ARQUIVOSWP" ]; then fnecho 'Arquivo ja existe'; fnsair 1; fi
if [ $TAMANHO -ge 1 -a $TAMANHO -le 32 ]; then TAMANHO=$(($TAMANHO*1024)); else fnecho 'Entre com tamanho de swap entre 1 e 32 (Gigabytes)'; fnsair 1; fi

#Define cmd de swap e chama funcao para criar arquivo.
fnecho "Aguarde, criando arquivo de swap..."
dd if=/dev/zero of=$ARQUIVOSWP bs=1024k count=$TAMANHO || fnsair 1
wait
#fnnohup $SWPCMD || fnsair 1

if [ -f "$ARQUIVOSWP" ]; then chmod 0600 $ARQUIVOSWP; mkswap $ARQUIVOSWP; swapon $ARQUIVOSWP; fnecho 'Swap criado com sucesso.'; fi
cat /proc/swaps && fnsair 0
#Saindo...
fnsair 1
#######################
#---FIM do programa---#
#######################

