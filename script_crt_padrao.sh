#!/usr/bin/env bash
set -u
set -e
set -o pipefail
#-----------------------------------------------------------#
#       Script XXXX  Certificado Padrao                     #
#-----------------------------------------------------------#
#       Author: Bruno Ferreira - Apr / 2020	                #
#       More at: https://git.XXXXXX.br/seguranca            #
#-----------------------------------------------------------#
# 		Reqs: openssl (apt-get install openssl)				#
# 		Usage: ./script or ./script IP/HOSTNAME             #
#       Desc: Script criado de forma emergencial durante    #
#       a quarentena da COVID19 para gerar certs            #
#       autoassinados padronizados.                         #
#-----------------------------------------------------------#

#---SETUP---#
VER="1.3"
NOME_SCRIPT="XXXX Certificado Padrao - $VER"
_HOST="${1:-vazio}" #IP/HOSTNAME
_CSR=""             #CSR Filename
_PRIV=""            #Private Key Filename
_CRT=""             #Cert. Filename
_PWDKEY=""          #Pass key file
_DAYS=365           #Days cert validity

#---Inicio Funcoes---#
fn_echo() {
    # Description: Funcao que padroniza as saidas de texto do programa.
    local MSG="${1:-vazio}"
    local TMSG="${2:-vazio}"

    #Se ocorrer um segundo parametro eh pq a msg eh especial(alerta, erro,ok)
    case "$TMSG" in
    ok | okay) echo -e "\e[32;1m###--- $NOME_SCRIPT: $MSG ---### \e[m" ;;     #Green
    alerta | warn) echo -e "\e[33;1m###--- $NOME_SCRIPT: $MSG ---### \e[m" ;; #Yellow
    erro | err) echo -e "\e[31;1m###--- $NOME_SCRIPT: $MSG ---### \e[m" ;;    #Red
    *) echo "###--- $NOME_SCRIPT: $MSG ---###" ;;                             #Neutral echo
    esac
}

fn_sair() {
    # Description: Funcao que executa checagem, limpeza, e outros antes de sair.
    CODIGO="$1"
    case $CODIGO in
    0) fn_echo "Saindo tudo ok..." ;;
    1) fn_echo "Erro, saindo..." "erro" ;;
    2) fn_echo "Cancelado pelo usuario: $2" "erro" ;;
    3) fn_echo "Erro: $2" "erro" ;;
    *) fn_echo "Erro das trevas, fuja para as montanhas!" "erro" ;;
    esac
    exit "$CODIGO"
}

# begin aux/parsing funcs
fn_is_ipv4() {
    # Description: Checa se eh IPV4 valido
    local INPUT="$1"
    local -r ipv4_rgx='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    [[ $INPUT =~ $ipv4_rgx ]]
    return $?
}

fn_is_fqdn() {
    # Description: Checa se segue o formato de FQDN
    local INPUT="$1"
    echo "$INPUT" | grep -Pq '(?=^.{4,255}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}\.?$)'
    return $?
}

fn_parse() {
    # Description: Funcao aux. para checar se o ip/hostname eh valido.
    INPUT=$1
    [ -z "$INPUT" ] && return 1
    fn_is_ipv4 "$INPUT" && return 0 #Eh ipv4
    fn_is_fqdn "$INPUT" && return 0 #Eh fqdn
    return 1
}
# end aux funcs

fn_prompt_setup() {
    # Description: Prompt para confirmar os dados do cert. - stp 0
    if [ "$_HOST" == "vazio" ]; then
        fn_echo "Digite o IP/FQDN para o certificado:"
        read -r _HOST
    fi

    if fn_parse "$_HOST" -eq 0; then
        fn_echo "Confirma o seguinte IP/FQDN: $_HOST [S/n]:"
        read -r OPT
        [ -z "$OPT" ] && OPT="S"
        case "$OPT" in
        n | N) fn_sair 2 " Saindo..." ;;
        s | S | y | Y) fn_gen_privkey "$_HOST" ;;
        *) fn_sair 171 ;;
        esac
    else
        fn_echo "[ALERTA]:IP/HOST fornecido parece incorreto! Continuar? [N/s]" "alerta"
        read -r OPT
        [ -z "$OPT" ] && OPT="N"
        case "$OPT" in
        n | N) fn_sair 2 " Saindo..." ;;
        s | S | y | Y) fn_gen_privkey "$_HOST" ;;
        *) fn_sair 172 ;;
        esac
    fi
}

fn_gen_privkey() {
    #Descricao: Gera chave privada. - stp 1

    _PRIV="$_HOST.key"
    _PWDKEY="$_HOST.pass.key"

    fn_echo "Deseja remover a senha da chave privada apos cria-la? [S/n]:"
    read -r OPT
    [ -z "$OPT" ] && OPT="S"
    case "$OPT" in
    n | N)
        fn_echo "Ok, guarde essa senha com seguranca para uso futuro!" "alerta"
        openssl genrsa -des3 -out "$_PRIV" 4096 || fn_sair 3 "Falha ao gerar a chave privada!"
        #openssl genrsa -des3 -out $_PWDKEY 4096 || fn_sair 3 "Falha ao gerar  arquivo de senha dachave privada!"
        #openssl rsa -in $_PWDKEY -out $_PRIV || fn_sair 3 "Falha ao gerar chave privada!"
        ;;
    s | S | y | Y)
        fn_echo "Ok, armazene a chave privada de forma segura!" "alerta"
        openssl genrsa -des3 -passout pass:756e6972696f -out "$_PWDKEY" 4096 || fn_sair 3 "Falha ao gerar arquivo de senha da chave privada!"
        openssl rsa -passin pass:756e6972696f -in "$_PWDKEY" -out "$_PRIV" || fn_sair 3 "Falha ao gerar chave privada!"
        rm "$_PWDKEY" || return 1
        ;;
    *) fn_sair 171 ;;
    esac

    fn_gen_csr || fn_sair 3 "Erro ao gerar o CSR!"
    return 0
}

fn_gen_csr() {
    #Descricao: CSR (Cert. sign req.) padronizado, usando a chave privada. stp2
    _CSR="$_HOST.csr"

    openssl req -new -key "$_PRIV" -out "$_CSR" -subj "/C=BR/ST=RJ/L=Rio/O=XXXXXX/OU=XXXX/CN=$_HOST" && fn_echo "Chave privada e CSR gerados com sucesso!" || return 1
    fn_gen_crt || fn_sair 3 "Erro ao gerar o certificado!"
}

fn_gen_crt() {
    #Descricao: Gera certificado padrao XXXX -stp 3
    _CRT="$_HOST.crt"

    fn_echo "Gerando certificado padrao XXXX 2020 para o host: $_HOST ..."
    openssl x509 -req -sha256 -days "$_DAYS" -in "$_CSR" -signkey "$_PRIV" -out "$_CRT"
    fn_relatorio || fn_sair 3 "Falha ao gerar relatorio"
}

fn_relatorio() {
    #Descricao: Auxilia o operador reportando os arquivos gerados. stp 4
    fn_echo "[Certificado]: $PWD/$_CRT" "ok" || return 1
    fn_echo "[Arquivo CSR]: $PWD/$_CSR" "ok" || return 1
    fn_echo "[Chave Privada]: $PWD/$_PRIV" "ok" || return 1
    fn_sair 0
}

fn_root() {
    #Descricao: Verifica se e root
    [ "$(id -u)" == "0" ] || return 1
}
#---Termino das funcoes---#

clear
fn_root || fn_sair 2 "Execute como root!"
command -v openssl &>/dev/null || fn_sair 2 "Openssl nao encontrado!"
fn_prompt_setup
fn_sair 1
