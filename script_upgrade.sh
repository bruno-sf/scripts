#!/bin/sh
#Brunof - 2019

VER="1.0"
NOME_SCRIPT="Script Upgrade - $VER"
PROG="apt-get"
ARGS="clean auto-clean auto-remove update upgrade"

clear
if [ $(id -u) != "0" ]; then echo "Apenas root!" >&2; exit 1; fi
which -a $PROG > /dev/null || { echo "\"$PROG\" nao encontrado...Saindo..."; exit 1; }
for arg in $ARGS; do apt-get $arg -y -q > /dev/null || { echo "Erro no passo $arg"; exit 1; }; done
echo "###--- $NOME_SCRIPT - Sistema atualizado com sucesso!. ---###" && exit 0
