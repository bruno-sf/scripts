#!/bin/bash -p
set -u
set -e
set -o pipefail
#-----------------------------------------------------------#
#       Script XXX  Certificado Padrao                      #
#-----------------------------------------------------------#
#       Author: Bruno Ferreira - Apr / 2020	                #
#       More at: https://git.XXX.br/seguranca               #
#-----------------------------------------------------------#
# 		Reqs: openssl (apt-get install openssl)				#
# 		Usage: ./script or ./script IP/HOSTNAME             #
#       Desc: Script criado de forma emergencial durante    #
#       a quarentena da COVID19 para gerar certs            #
#       autoassinados padronizados.                         #
#-----------------------------------------------------------#

#---SETUP---#
VER="1.2"
NOME_SCRIPT="XXX Certificado Padrao - $VER"
_HOST="${1:-vazio}" #IP/HOSTNAME
_CSR=""             #CSR Filename
_PRIV=""            #Private Key Filename
_CRT=""             #Cert. Filename
_PWDKEY=""          #Pass key file
_DAYS=365           #Days cert validity

#---Inicio Funcoes---#
fn_echo () {
    # Description: Funcao que padroniza as saidas de texto do programa.
	echo "###--- $NOME_SCRIPT: $1 ---###" && return 0
}

fn_sair () {
    # Description:Funcao que executa checagem, limpeza, e outros antes de sair.
	CODIGO="$1"
	case $CODIGO in
	0) fn_echo "Saindo tudo ok..." ;;
	1) fn_echo "Erro, saindo..."	;;
    2) fn_echo "Erro: $2" ;;
	*) fn_echo "Erro das trevas, fuja para as montanhas!" ;;
	esac
	exit $CODIGO
}

fn_prompt_setup () {
    # Description: Prompt para confirmar os dados do cert. - stp 0
    if [ "$_HOST" == "vazio" ]; then
        echo "Digite o IP do HOST ou nome cadastrado no DNS:"
        read _HOST
        fn_aux_parse "$_HOST" || fn_sair 2 "HOST/IP invalido!"
        echo "Confirma o seguinte HOST/IP: $_HOST [S/n]:"
        read OPT
        [ $OPT -z ] && OPT="S"
        [ $OPT = "n" ] && fn_sair 2 "Ok, saindo..."
    fi
    fn_gen_privkey $_HOST
}

fn_aux_parse () {
    # Description: Funcao aux. para checar se o ip/hostname eh valido.
    INPUT="$1"
    [ -z $INPUT ] && return 1
    #IPV4=$(echo "$INPUT" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}') #IPV4
    return 0
}

fn_gen_privkey () {
    #Descricao: Gera chave privada. - stp 1
    
    _PRIV="$_HOST.key"
    _PWDKEY="$_HOST.pass.key"

    echo "Deseja remover a senha da chave privada apos cria-la? [S/n]:"
    read OPT
    [ $OPT -z ] && OPT="S"
    if [ $OPT == "n" ]; then
        echo "Ok, guarde a senha com seguranca!"
        openssl genrsa -des3 -out $_PWDKEY 4096 || fn_sair 2 "Falha ao gerar chave privada!"
        openssl rsa -in $_PWDKEY -out $_PRIV || fn_sair 2 "Falha ao gerar chave privada!"
    else
        echo "Ok, guarde a chave privada de forma segura!"
        openssl genrsa -des3 -passout pass:XXX -out $_PWDKEY 4096 || fn_sair 2 "Falha ao gerar chave privada!"
        openssl rsa -passin pass:XXX -in $_PWDKEY -out $_PRIV && rm $_PWDKEY || fn_sair 2 "Falha ao gerar chave privada!"
    fi
    fn_gen_csr || fn_sair 2 "Erro ao gerar o CSR!"
}

fn_gen_csr () {
    #Descricao: CSR (Cert. sign req.) padronizado, usando a chave privada. stp2

    _CSR="$_HOST.csr"

    openssl req -new -key $_PRIV -out $_CSR -subj "/C=BR/ST=RJ/L=Rio/O=XXX/OU=XXX/CN=$_HOST" && fn_echo "Chave privada e CSR gerados com sucesso!" || return 1
    fn_gen_crt || fn_sair 2 "Erro ao gerar o certificado!"
}

fn_gen_crt () {
    #Descricao: Gera certificado padrao XXX -stp 3
    _CRT="$_HOST.crt"
    
    fn_echo "Gerando certificado padrao XXX 2020 para o host: $_HOST ..."
    openssl x509 -req -sha256 -days "$_DAYS" -in "$_CSR" -signkey "$_PRIV" -out "$_CRT"
    fn_relatorio
}

fn_relatorio () {
    #Descricao: Auxilia o operador reportando os arquivos gerados. stp 4
    fn_echo "[Certificado]: $PWD/$_CRT"
    fn_echo "[Arquivo CSR]: $PWD/$_CSR"
    fn_echo "[Chave Privada]: $PWD/$_PRIV"
    fn_sair 0
}

fn_root () {
    #Descricao: Verifica se e root
    [ $(id -u) == "0" ] || return 1
}
#---Termino das funcoes---#

clear
fn_root || fn_sair 2 "Execute como root!"
command -v openssl &> /dev/null || fn_sair 2 "Openssl nao encontrado!"
fn_prompt_setup
fn_sair 1
