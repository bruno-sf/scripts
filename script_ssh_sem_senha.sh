#!/usr/bin/env bash
#---------------------------------------------------------------------------#
#               Script Envia Chaves SSH - Ver: 0.5                          #
#---------------------------------------------------------------------------#
#       Data de criacao: 10/10/2016 - Ultima versao: 15/04/2021             #
#                   Author: https://github.com/brunof-sf                    #
#---------------------------------------------------------------------------#
# Desc.[PT-BR]: Envio de chaves RSA do usuario para o(s) servidor(es)       #
# remoto(s) habilitando o processo de login e operacoes automatizadas       #
# via SSH.                                                                  #
# Send RSA user keys to remote host(s) enabling automated tasks and         #
# promptless logins via SSH.                                                #
#---------------------------------------------------------------------------#
#Usage: ./script <IP/HOSTNAME>                                              #
#Usage: ./script <SRVFILE> (Um ip/hostname por linha)                       #
#---------------------------------------------------------------------------#

#---------------CONFIG---------------------------#
SSH_DIR="$HOME/.ssh"
SRVS_FILE=""
SSH_AUTH_FILE="$SSH_DIR/authorized_keys"
SSH_PUB_KEY_RSA="$SSH_DIR/id_rsa.pub"
SSH_KEY_RSA="$SSH_DIR/id_rsa"
SSH_PORT=22
PROGS=( "ssh" "ssh-keygen" "ssh-copy-id" ) #REQS
#------------------------------------------------#

#---Inicio das Funcoes---#

fn_banner(){
    cat << "EOF"
 _____ _____ _   _   _____                _   _   __               
/  ___/  ___| | | | /  ___|              | | | | / /               
\ `--.\ `--.| |_| | \ `--.  ___ _ __   __| | | |/ /  ___ _   _ ___ 
 `--. \`--. \  _  |  `--. \/ _ \ '_ \ / _` | |    \ / _ \ | | / __|
/\__/ /\__/ / | | | /\__/ /  __/ | | | (_| | | |\  \  __/ |_| \__ \
\____/\____/\_| |_/ \____/ \___|_| |_|\__,_| \_| \_/\___|\__, |___/
                                                          __/ |    
                                                         |___/     
by: Bruno Ferreira - 0.5 - Apr 2021

Usage:
    ./script /home/user/servers1byline.txt
    ./script a.remotehost.net
EOF
}

fn_echo_color () {
    COLOR=$(echo "$2" | tr '[:lower:]' '[:upper:]')
    case $COLOR in
    "RED") echo -e "\e[31;1m$1\e[m" ;;
    "GREEN") echo -e "\e[32;1m$1\e[m" ;;
    "YELLOW") echo -e "\e[33;1m$1\e[m" ;;
    "BLUE") echo -e "\e[34;1m$1\e[m" ;;
    *) echo -e "\e[33;1m$1\e[m" ;;
    esac
}

fn_print_hdr() {
    HDR=$( printf "%`tput cols`s" | tr ' ' '#' )
    fn_echo_color $HDR "BLUE"
}

fn_ssh-copy () {
        let I++
        if ssh-copy-id -p "$_PORT" "$_USER"@"$SERVER_SSH"; then
            fn_echo_color "Chave copiada com sucesso! Servidor: $SERVER_SSH ($I/$_TOTAL)" "GREEN"
        else
            fn_echo_color "Falha ao copiar a chave para o Servidor: $SERVER_SSH ($I/$_TOTAL)"
        fi

        fn_print_hdr
}

fn_invalid_entry () {
    #Check if an entry is not alphnumeric
    _ENTRY="$1"
    _VAL=$(echo "$_ENTRY" | sed -n '/^[[:alnum:]]/p')
    echo $_VAL
    
    if [ -z "$_VAL" ]; then
        return 0 #Invalid entry
    else
        return 1 #Alphanum valid entry
    fi
}

fn_envia_chaves_prompt () {
    #Faz o envio de chaves confirmando cada envio com prompt de usuario e porta.
    I=0
    _TOTAL=$(sed -n '/^[[:alnum:]]/p' $SRVS_FILE | wc -l)
    #for SERVER_SSH in `cat $SRVS_FILE`;
    while read SERVER_SSH; 
    do	
        fn_echo_color "Utilizando chave pública já existente." "YELLOW"
        fn_echo_color "Servidor: $SERVER_SSH" "YELLOW"
        fn_echo_color "Digite o usuário remoto:[$USER]" "YELLOW"
        read _USER
        [ -z $_USER ] && _USER="$USER"

        fn_echo_color "Digite a porta:[$SSH_PORT]" "YELLOW"
        read _PORT
        [ -z $_PORT ] && _PORT=$SSH_PORT
        
        if fn_invalid_entry $SERVER_SSH; then
            #If entry is invalid dont process
            continue 
        fi

        fn_ssh-copy
    done < <(cat $SRVS_FILE)
}

fn_envia_chaves_bulk () {
    #Faz o envio de chaves sem confirmacoes.
    I=0
    _TOTAL=$(sed -n '/^[[:alnum:]]/p' $SRVS_FILE | wc -l)

    fn_echo_color "[Bulk-mode]Confirme o Usuario/Porta para TODOS os servidores de uma vez." "YELLOW"
    fn_echo_color "Digite o usuário remoto:[$USER]" "YELLOW"
    read _USER
    [ -z $_USER ] && _USER="$USER"

    fn_echo_color "Confirme a porta SSH:[$SSH_PORT]" "YELLOW"
    read _PORT
    [ -z $_PORT ] && _PORT=$SSH_PORT
    
    fn_echo_color "Utilizando chave pública já existente: $(ssh-add -l)"

    #for SERVER_SSH in `cat $SRVS_FILE`;
    while read SERVER_SSH; 
    do	
        if fn_invalid_entry $SERVER_SSH; then
            #If entry is invalid dont process
            continue 
        fi

        fn_ssh-copy
    done < <(cat $SRVS_FILE)
}

fn_chk_lkeys () {
    if [ -e "$SSH_PUB_KEY_RSA" -a -e "$SSH_KEY_RSA" ]; then
        fn_echo_color "Atenção: Você já possui uma chave!"
        fn_print_hdr
        ssh-add -l
        fn_print_hdr
        fn_echo_color "Deseja utilizá-la? [S/n]"
        read _OPT
        [ -z $_OPT ] && _OPT="S"

        case $_OPT in
            "n" | "N") fn_mk_keys ;;
            *) return 0 ;;
        esac
    else
        fn_mk_keys
        return 0   
    fi
}

fn_bkp_ids () {
    # Func. Aux. Chamada pela mk_keys - Realiza o backup de chaves existentes
    cp -a $SSH_PUB_KEY_RSA $SSH_PUB_KEY_RSA.bkp || return 1
    cp -a $SSH_KEY_RSA $SSH_KEY_RSA.bkp || return 1
    return 0
}

fn_mk_keys () {
    #(Re)Cria as chaves RSA
    [ -e "$SSH_PUB_KEY_RSA" -a -e "$SSH_KEY_RSA" ] && fn_bkp_ids && fn_echo_color "Backup das chaves existentes realizado." "YELLOW"
    fn_echo_color "### Criando par de chaves RSA ###" "BLUE"
    ssh-keygen -t rsa && return 0
    fn_echo_color "[ERRO]: Nao foi possivel criar as chaves!" "RED"; 
    exit 7;
}

fn_prompt_enviar () {
    #Faz o envio de acordo com a opcao desejada

    fn_echo_color "Deseja usar o modo bulk [S/n] (Sem confirmacoes a cada servidor)" "YELLOW"
    read OPT
    [ -z $OPT ] && OPT="S"

    case $OPT in
        "S" | "s") fn_envia_chaves_bulk ;;
        "N" | "n") fn_envia_chaves_prompt ;;
        *) fn_echo_color "Opcao invalida" "RED" ;;
    esac
}

fn_envia_single_prompt () {
    #Faz o envio de chaves com confirmacoes.
    fn_echo_color "Digite o usuário remoto:[$USER]" "YELLOW"
    read _USER
    [ -z $_USER ] && _USER="$USER"

    fn_echo_color "Confirme a porta SSH:[$SSH_PORT]" "YELLOW"
    read _PORT
    [ -z $_PORT ] && _PORT=$SSH_PORT
    fn_ssh-copy
}

fn_enviar_single () {
    #Faz o envio da chave apenas para um host

    SERVER_SSH="$1"
    _USER="$USER"
    _PORT="22"
    #Faz o envio de acordo com a opcao desejada

    fn_echo_color "Deseja usar o usuario $_USER e a porta $_PORT? [S/n]" "BLUE"
    read OPT
    [ -z $OPT ] && OPT="S"

    case $OPT in
        "N" | "n") fn_envia_single_prompt ;;
        *) fn_ssh-copy ;;
    esac

    return 0
}

fn_chk_cmd () {
    #Checa se um commando existe dentro do array REQS!
    local total=$
    for PROG in "${PROGS[@]}"
    do
        which -a "$PROG" > /dev/null 2>&1 || { fn_echo_color "[ERRO]: o programa $PROG nao foi encontrado no sistema!"; exit 3; }
    done
    return 0
}
#---Fim das Funcoes---#

#Inicio
clear
fn_banner

#Checks
fn_chk_cmd "$REQS"
[ "$1" ] && ARG1="$1" || { fn_echo_color "Favor passar o IP/HOSTNAME ou um arquivo de servidores como argumento. Crie um arquivo com 1 ip/hostname por linha." "RED"; exit 2; }
[ -e "$ARG1"  ] && SRVS_FILE="$ARG1" || HOST="$ARG1"
fn_chk_lkeys

if [ "$HOST" ]; then
    [ "$HOST" ] && fn_enviar_single "$HOST" || { fn_echo_color "[ERRO]: Nao foi possivel enviar a chave!" "RED"; }

elif [ "$SRVS_FILE" ]; then
    [ "$SRVS_FILE" ] && fn_prompt_enviar "$SRVS_FILE" || { fn_echo_color "[ERRO] :Nao foi possivel enviar a chave!" "RED"; }

else
    fn_echo_color "[ERRO]: Nao foi possivel determinar o IP/Arquivo fornecido!"
    exit 8
fi