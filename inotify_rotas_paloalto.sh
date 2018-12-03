#!/bin/bash
#-------------------------------------------------------#
#          Script inotify Rotas PaloAlto                #
#-------------------------------------------------------#
#       	Data de criacao: 27/11/2018		#
#		Ultima Edicao: 03/12/2018	        #
#-------------------------------------------------------#
#Versao: 02 (versao rota paloalto)                      #
#Bugs e Correcoes: brunosilvaferreira@protonmail.com	#
#-------------------------------------------------------#
#Descricao: Script especifico para o monitoramento de   #
# mudancas de rota no Paloalto, derivado do script      #
#inotify (generico). Testado como servico system.d      #
#systemctl start rotas-paloalto-monitor.service         #
#-------------------------------------------------------#
#Requisitos:bash,inotifywait (pkg: inotify-tools)	#
#-------------------------------------------------------#
#Carrega funcoes genericas
BIBLIOTECA="/home/brunof/scripts/biblioteca_generica.sh"
source $BIBLIOTECA > /dev/null 2>&1 || { echo "Erro ao carregar $BIBLIOTECA."; exit 101; }
########################################
#---INICIO Constantes e Vars Globais---#
########################################
NOME_SCRIPT="Script iNotify Rotas Paloalto"
[ "$1" ] && LOG_FILE="$1"|| fnsair 1 "Usage: script.sh <LOGFILE>"
PADRAO="Route restored\|Route removed"
EVENT="modify" #access attrib close_write close_nowrite close open... (see man)
PARSER="python /home/brunof/scripts/python_parse_csv_paloalto.py"
SEND_MAIL="bash /home/brunof/scripts/script_envia_email.sh"
TELEGRAM="python /home/brunof/scripts/notify_telegram.py -c /home/brunof/scripts/notify_telegram.cfg -t ALT2 "
PROGS="inotifywait grep"
########################################
#---FIM Constantes e Vars Globais---#
########################################

###############################
#---INICIO Funcao monitorar---#
###############################
#Descricao:O inotifywait trabalha com varios tipos de eventos (ver man)
#Esta funcao executa checagem do arquivo em eventos do tipo modify sendo mais
#adequado de acordo com a documentacao para o proposito inicial. O incrontab
#nao se mostoru eficaz com uso mais complexo de argumentos e checagens.

fnmonitora_compadrao () {
    while inotifywait -qq -e $EVENT $LOG_FILE; do
        local ultimalinha=""
        ultimalinha=`tail -n1 $LOG_FILE | grep "${PADRAO}"`
        #Parseou, Passou!
        if [ -n "$ultimalinha" ]; then
            PARSEADO=`echo $ultimalinha | $PARSER`
            $SEND_MAIL "$PARSEADO" "Mudanca de Rota no firewall" "alertas-redes-seg" &
            $TELEGRAM "$PARSEADO" &
        fi
	done
}
###############################
#---INICIO Funcao monitorar---#
###############################
#Checks
clear
fnroot || fnsair 1 "Apenas root!"
fnpath $PROGS || fnsair 1 "Um dos programas ($PROGS) nao foi encontrado!"
[ -f $LOG_FILE ] || fnsair 1 "Arquivo de log nao foi encontrado: $LOG_FILE"
fnmonitora_compadrao
