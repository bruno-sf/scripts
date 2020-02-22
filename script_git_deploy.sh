#!/bin/bash
#---------------------------------------------------#
#   Data de criacao: 02/08/2019                     #
#   Ultima Edicao: 21/02/2020                       #
#---------------------------------------------------#
#   Versao: 03                                      #
#   Bugs: brunosilvaferreira@protonmail.com         #
#---------------------------------------------------#
#   Descricao: Script para deploy e sync do meu     #
#   servidor GIT pessoal.                           #
#---------------------------------------------------#

# [CONFS]
NOME_SCRIPT="Script GIT Deploy e Sync"
TOKEN_WEB="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
PROTO="https"
PORT="3000"
HOST="XXXXXXXXXXXXXXXXXXXXXXXXXXXx" # [Git Gogs Rasp2 Meier]
GIT_USER="XXXXXXXXXXXXXX"
CA_CRT_PATH="/etc/ssl/certs/ca-certificates.crt"
CRT="-----BEGIN CERTIFICATE-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
PUT THE CONTENT OF YOUR GIT SRV CERTIFICATE HERE ;)
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-----END CERTIFICATE-----"

# [REPOS]
DIR_LOCAL_REPO="$HOME/git_pessoal/"

GIT_SCRIPTS_REPO="scripts"
GIT_CONFS_REPO="confs"
GIT_PYTHON_REPO="python"
GIT_DOCKER_REPO="docker_apps"
GIT_QUBES_REPO="qubes"
GIT_AWS_REPO="aws"

REPOS="$GIT_AWS_REPO $GIT_CONFS_REPO $GIT_DOCKER_REPO $GIT_PYTHON_REPO $GIT_QUBES_REPO $GIT_SCRIPTS_REPO"

# [FUNCTIONS]
    #Por questao de seguranca prefiro verificar o cert TLS do meu server o cert hardcoded no script.
    #For security measure never disable ssl on git and please make sure every time the TLS cert is the one you trust.
fn_chk_crt () {
    #Extract and Check if the remote TLS Cert matches with the hard coded one in this script ;)
    REMOTE_CRT=$(echo -n | openssl s_client -showcerts -connect $HOST:$PORT \
          2>/dev/null  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p')
    [ -z "$REMOTE_CRT" ] && { echo "Can't extract TLS certificate from host...
        Aborting the security checks..."; return; }

    [ "$REMOTE_CRT" != "$CRT" ] && { echo "[Security alert]: The certificate from host don't look correct. If you change it recently, please update CRT var on this script, or you can be suffering a phishing attack and should not continue!"; exit 1; }
    [ -f "$CA_CRT_PATH" ] && { echo -n "$CRT" | sed '/-----/d' | grep -qxwf "$CA_CRT_PATH" && return; } #Cert already "installed"
    echo "Can't find the content of the host cert on your local CA file ("$CA_CRT_PATH")."
    read -p "Do you wish to install it (y/n)?" choice
    case "$choice" in
    y|Y ) fn_install_crt;;
    n|N ) echo "Ok, I will NOT install the cert as you wish...";;
    * ) echo "Invalid answer, doing nothing..."; return;;
    esac
}
fn_install_crt () {
    #Install the cert appending it on CA File
    [ -w "$CA_CRT_PATH" ] && echo "$CRT" >> $CA_CRT_PATH && echo "[OK]: Cert successfully installed!" && return 0
    echo "[FAIL]: Sorry, the user ["$USER"] don't have permission to write on ["$CA_CRT_PATH"] and so do I.Ok, last shot...Trying with sudo..."
    echo "$CRT" | sudo tee -a $CA_CRT_PATH && echo "[OK]: Cert successfully installed!" && return 0
}

fn_clone_repo () {
    # Call this func only if $DIR_LOCAL_REPO don't exist!
    while [ $# -gt 0 ] ; do
        [ -z "$1" ]  && break;
        CURRENT_REPO="$1"
        git -C "$DIR_LOCAL_REPO" clone "$PROTO"://"$TOKEN_WEB"@"$HOST":"$PORT"/"$GIT_USER"/"$CURRENT_REPO.git" \
            || { echo "[ERROR]: Can't clone repository $CURRENT_REPO"; exit 1; }
        shift
    done
}


fn_pull_repo () {
    while [ $# -gt 0 ] ; do
        [ -z "$1" ]  && break;
        CURRENT_REPO=$DIR_LOCAL_REPO$1

        [ -d "$CURRENT_REPO" ] \
            || { echo "[ERROR]: Directory don't exist, please review it: $CURRENT_REPO "; exit 1; }

        git -C "$CURRENT_REPO" status \
            || { echo "[ERROR]: Not a regular git repository, please review it: $CURRENT_REPO"; exit 1; }

        git -C "$CURRENT_REPO" pull \
            || { echo "[ERROR]: Can't pull this repository: $CURRENT_REPO"; exit 1; }
        shift
    done
}

# [BEGIN]
# Check local REPO
if [ -d  "$DIR_LOCAL_REPO" ]; then
    fn_pull_repo $REPOS
else
    mkdir -p "$DIR_LOCAL_REPO" || { echo "[ERROR]: Can't create dir: $DIR_LOCAL_REPO"; exit 1; }
    fn_chk_crt && fn_clone_repo $REPOS
fi
