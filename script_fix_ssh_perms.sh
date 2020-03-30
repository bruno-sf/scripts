#!/bin/bash -p
#-----------------------------------------------------------#
#       Script Fix SSH Perms - Version: 1	                #
#-----------------------------------------------------------#
#       Author: Bruno Ferreira - Mar / 2020	                #
#       More at: https://github.com/bruno-sf                #
#-----------------------------------------------------------#

#---INICIO Constantes---#
NOME_SCRIPT="Script Fix SSH Perms"
_SSH_DIR="$HOME/.ssh"
#---Inicio sessao de Funcoes---#
fnecho () {
#Descricao:Funcao que padroniza as saidas de texto do programa.
	echo "###--- $NOME_SCRIPT: $1 ---###" && return 0
}

clear
#Checks
[ -d $_SSH_DIR ] || { fnecho "[ERROR]:Sorry, can't find dir $_SSH_DIR"; exit 1; }
chown --recursive $USER:$USER $_SSH_DIR && chmod 755 $_SSH_DIR && fnecho "[OK]: SSH Dir - Done"
[ -e $_SSH_DIR/known_hosts ] && chmod 644 $_SSH_DIR/known_hosts && fnecho "[OK]: Known hosts file - Done"
[ -e $_SSH_DIR/authorized_keys ] && chmod 644 $_SSH_DIR/authorized_keys && fnecho "[OK]: Auth keys file - Done"
[ -e $_SSH_DIR/config ] && chmod 600 $_SSH_DIR/config && fnecho "[OK]: Config file - Done"
[ -e "$_SSH_DIR/id_*" ] && chmod 600 $_SSH_DIR/id_* && fnecho "[OK]: file id_* - Done"
[ -e $_SSH_DIR/*.pub ] && chmod 600 $_SSH_DIR/*.pub && fnecho "[OK]: file *.pub - Done"

fnecho "We need to service ssh restart after changing these values"
sudo service ssh restart

[ -d $HOME/.gnupg ] || { fnecho "[ERROR]:Sorry, can't find dir $HOME/.gnupg"; exit 1; }
chown --recursive $USER:$USER $HOME/.gnupg
chmod 700 $HOME/.gnupg && chmod 600 $HOME/.gnupg/*

exit 0