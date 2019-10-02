#!/bin/bash
#---------------------------------------------------#
#	Data de criacao: 02/08/2019	                    #
#	Ultima Edicao: 02/10/2019	                    #
#---------------------------------------------------#
#   Versao: 02                                     	#
#   Bugs: brunosilvaferreira@protonmail.com         #
#---------------------------------------------------#
#   Descricao: Script para deploy do GIT pessoal.   #
#	Caso ja exista o repositorio, dara um pull.		#
#---------------------------------------------------#

# [CONFS]
NOME_SCRIPT="Script GIT Deploy e Sync"
TOKEN_WEB="XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
PROTO="https"
PORT="YYYY"
HOST="XXXXXX" # [Git Gogs Rasp2 Meier]
GIT_USER="brunof"

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
#Check local REPO
git config --global http.sslverify false
if [ -d  "$DIR_LOCAL_REPO" ]; then
    fn_pull_repo $REPOS
else
    mkdir -p "$DIR_LOCAL_REPO" || { echo "[ERROR]: Can't create dir: $DIR_LOCAL_REPO"; exit 1; }
    fn_clone_repo $REPOS
fi
git config --global http.sslverify true
