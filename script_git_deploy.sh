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
TOKEN_WEB="beee5935c7023f7689e17fb436b2363d092ccbf4"
PROTO="https"
PORT="3000"
HOST="bsf.sytes.net" # [Git Gogs Rasp2 Meier]
GIT_USER="brunof"
CA_CRT_PATH="/etc/ssl/certs/ca-certificates.crt"
CRT="-----BEGIN CERTIFICATE-----
MIIEJjCCAw6gAwIBAgIJAOfcAwiT2J0nMA0GCSqGSIb3DQEBCwUAMIGnMQswCQYD
VQQGEwJCUjEXMBUGA1UECAwOUmlvIGRlIEphbmVpcm8xCzAJBgNVBAcMAlJKMRcw
FQYDVQQKDA5NeSBPd24gR2l0UmVwbzEPMA0GA1UECwwGQnJ1bm9mMRYwFAYDVQQD
DA1ic2Yuc3l0ZXMubmV0MTAwLgYJKoZIhvcNAQkBFiFicnVub3NpbHZhZmVycmVp
cmFAcHJvdG9ubWFpbC5jb20wHhcNMTkwODI4MTQwMjMwWhcNMjAwODI3MTQwMjMw
WjCBpzELMAkGA1UEBhMCQlIxFzAVBgNVBAgMDlJpbyBkZSBKYW5laXJvMQswCQYD
VQQHDAJSSjEXMBUGA1UECgwOTXkgT3duIEdpdFJlcG8xDzANBgNVBAsMBkJydW5v
ZjEWMBQGA1UEAwwNYnNmLnN5dGVzLm5ldDEwMC4GCSqGSIb3DQEJARYhYnJ1bm9z
aWx2YWZlcnJlaXJhQHByb3Rvbm1haWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOC
AQ8AMIIBCgKCAQEApbv0hcr5ulqwJGRs5S3qRr7tgFGbyPQwGW/Etzwepmc9hfON
kgomYzOtoADGPKDVTcEKvrgBMaCeex/+J1gUbUHyXqCTyzgiM0EwcGNCp6jjkJsp
W024EcJKDavH5YPYuVHfJ25GAgXmvUjpwc2cBgL4MGNLnzn5t0qvJ2VOPCcbgE+Y
WY2QD1PUDrtrugZKNAW1n4/YBBgV7nrRKDwBpD2ZYIAwD07ELjNXP+RCrE2aMpdS
BKiVAsYNgZU2r5rmOd7QZCjOHAUKQ9f9a507/BYaBrcytBhWnb39bPATcvBEhS+b
dRHD88cw8UHagywWwRopt07CoZbTSHFQrQpFgwIDAQABo1MwUTAdBgNVHQ4EFgQU
nj+vDZ6w+6jFvRRAhMaln1XVHngwHwYDVR0jBBgwFoAUnj+vDZ6w+6jFvRRAhMal
n1XVHngwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAhCxHGInX
J0CBdeejEYR1Hn6gvWDgSNS2xpJF6APtDfAImFxgF7CMgbl4e7d678k9yuPxpm7U
8NK2iQCsxBmNjCSTUMJAUl4gnhxPaiibpI2SVM9wKWJmCIfO2uffuXDhyDFyAIqY
KGCubHfa64Qfa42kQHN6szAVp/V7iueLqHjHsAWYlvDHrsKji7+t6SSVSfPjZ5i9
PMqLvVXyr4U9XOjTqDfyhDWNXY0L/cxEdVm0cM5SMWrFeZSPqbgGE9XO/PtECBiq
esFLvmlTZtEkfIyW0WDB6NrgblJeSlTR2cNNtrY5B0/tRuKoCuHASp6OBeLAeWff
XbWcEzl1ygMAHw==
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
    echo "[FAIL]: Can't find the the host cert on your local CA file: ["$CA_CRT_PATH"]."
    read -p "Do you wish to install it [Y/n]?" choice
    case "$choice" in
    y|Y ) fn_install_crt;;
    n|N ) echo "Ok, I will NOT install the cert as you wish...";;
    * ) echo "Invalid answer, doing nothing..."; return;;
    esac
}
fn_install_crt () {
    #Install the cert appending it on CA File
    [ -w "$CA_CRT_PATH" ] && echo "$CRT" >> $CA_CRT_PATH && echo "[OK]: Cert successfully installed!" && return 0
    echo "[FAIL]: Sorry, the user ["$USER"] don't have permission to write on ["$CA_CRT_PATH"] and so do I. Ok, trying with sudo..."
    echo "$CRT" | sudo tee -a $CA_CRT_PATH && echo "[OK]: Cert successfully installed!" && return 0
    echo "[FAIL]: Well, last shot...Maybe global configs isn't for you, but you can at least configure it just for your user."
    echo -n "$CRT" > "$HOME"/"$HOST".crt && git config --global http."https://$HOST:$PORT".sslCAInfo $HOME/$HOST.crt && echo "[OK]: Cert successfully installed!" && return 0
    return 1
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

# [BEGIN] - Check local REPO
if [ -d  "$DIR_LOCAL_REPO" ]; then
    fn_pull_repo $REPOS
else
    mkdir -p "$DIR_LOCAL_REPO" || { echo "[ERROR]: Can't create dir: $DIR_LOCAL_REPO"; exit 1; }
    fn_chk_crt && fn_clone_repo $REPOS
fi
