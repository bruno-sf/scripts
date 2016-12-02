#!/bin/bash
#Resumo:Script para envio de chave pública do usuário local para servidores remotos.Devido problemas com o OpenBSD que gera erros ao decriptografar chaves RSA, optei por criar os 2 tipos (DSA e RSA), e manter a compatibilidade sem ficar questionando qual é o sistema alvo.
#Como utilizar:Dar permissão ao script (ex.chmod +x ssh_sem_senha.sh).Criar um arquivo servidores.txt no diretório do script contendo os IPs dos servidores alvo(um ip por linha)ex:(./servidores.txt) ou então utilizar UM ip como parâmetro(ex.:./script_ssh_sem_senha.sh 192.168.1.1).
#Pré-requisitos:ssh.
#Histórico:Primeira edição 29/03/2012
#Última edição:02/04/2012
#Última edição:25/08/2015
#Autor:Bruno Ferreira
#Email:brunof@tic.ufrj.br
#------------------------------------------------#
#CONSTANTES
SSH_DIR="$HOME/.ssh/"
SERVERS="./servidores.txt"
SSH_AUTH_FILE="$HOME/.ssh/authorized_keys"
SSH_PUB_KEY_RSA="$HOME/.ssh/id_rsa.pub"
SSH_PUB_KEY_DSA="$HOME/.ssh/id_dsa.pub"
L_USER=$USER
SSH_PORT=22
#CHAVES
CHAVE_AUTH_FILE=0
CHAVE_PUB_KEY_RSA=0
CHAVE_PUB_KEY_DSA=0
#------------------------------------------------#
clear

#Verifica se o arquivo servidores.txt existe
if test ! -e $SERVERS ; then 
	if [ $1 ] ; then #Verifica se existe parametro...
		echo "$1" > /tmp/servidores.txt
		SERVERS=/tmp/servidores.txt
	else
		echo "###---Atenção!---###" 
		echo "###---Favor criar o arquivo:$SERVERS com os ips, ou inserir UM ip como parâmetro ex: ./script 192.168.1.1---###"
		exit

	fi
else
	if [ $1 ]; then
		echo "$1" > /tmp/servidores.txt
		SERVERS=/tmp/servidores.txt
	fi
fi

#Verifica se a chave pública RSA local já existe.
if test -e $SSH_PUB_KEY_RSA ; then 
	CHAVE_PUB_KEY_RSA=1
fi
#Verifica se a chave pública DSA local já existe.
if test -e $SSH_PUB_KEY_DSA ; then 
	CHAVE_PUB_KEY_DSA=1
fi

if [ $CHAVE_PUB_KEY_RSA -eq 1 -a $CHAVE_PUB_KEY_DSA -eq 1 ]; then 
	echo "###---Atenção!---###" 
	echo "###---Você já possui chaves públicas RSA e DSA!---###" 
	echo "Deseja utilizá-las? [S/n]"	
	read OPT

#Verifica se é nulo 
if [ -z $OPT ]; then
	OPT="S"
fi

case $OPT in

#Caso a Resposta seja Sim
"S")
for SERVER_SSH in `cat $SERVERS`;
do	
	echo "###---Utilizando chave pública já existente.---###"
	cd $SSH_DIR
	echo "Servidor: $SERVER_SSH"
	echo "Digite o usuário remoto:[$L_USER]"
	read USER

	#Verifica se é nulo	
	if [ -z $USER ]; then
		USER="$L_USER"
	fi

	echo "Digite a porta:[$SSH_PORT]"
	read PORT

	#Verifica se é nulo	
	if [ -z $PORT ]; then
		PORT=$SSH_PORT
	fi

	#Teste se existe arquivo autorized_keys
	echo "###---Verificando se existe arquivo de autorizacao de chaves.---###"
	ssh -l $USER -p $PORT $SERVER_SSH "touch $SSH_AUTH_FILE" || CHAVE_AUTH_FILE=1;
	
	if [ $CHAVE_AUTH_FILE -eq 0 ];
	then
	cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        echo "###--- Chave pública copiada para o Servidor: $SERVER_SSH ---###";
	else
	cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        echo "###--- Chave pública copiada para o Servidor: $SERVER_SSH ---###";
	fi
done
;;

#Caso a  Resposta seja Não
"n")
for SERVER_SSH in `cat $SERVERS`;
do	
	echo "###Criando BKP das chaves locais RSA e DSA em: $SSH_DIR ###"
	mv $SSH_PUB_KEY_RSA $SSH_PUB_KEY_RSA.bkp
	mv $SSH_PUB_KEY_DSA $SSH_PUB_KEY_DSA.bkp

	echo "###Criando chaves locais###"
	#cria chave RSA
	ssh-keygen -t rsa
	cd $SSH_DIR
	cat $SSH_PUB_KEY_RSA > $SSH_AUTH_FILE
	chmod 600 $SSH_AUTH_FILE

	#cria chave DSA
	ssh-keygen -t dsa
	cd $SSH_DIR
	cat $SSH_PUB_KEY_DSA > $SSH_AUTH_FILE
	chmod 600 $SSH_AUTH_FILE

	echo "Servidor: $SERVER_SSH"
	echo "Digite o usuário remoto:["$L_USER"]"
	read USER

	#Verifica se é nulo	
	if [ -z $USER ]; then
		USER="$L_USER"
	fi

	echo "Digite a porta:[$SSH_PORT]"
	read PORT
	#Verifica se é nulo	
	if [ -z $PORT ]; then
		PORT=$SSH_PORT
	fi

	#Teste se existe arquivo autorized_keys
        echo "###--Verificando se existe arquivo de autorizacao de chaves..."
        ssh -l $USER -p $PORT $SERVER_SSH "touch $SSH_AUTH_FILE" || CHAVE_AUTH_FILE=1;

        if [ $CHAVE_AUTH_FILE -eq 0 ];
        then
        cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        echo "Chave pública copiada para o Servidor: $SERVER_SSH";
        else
        cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        echo "Chave pública copiada para o Servidor: $SERVER_SSH";
        fi
	echo "Caso você receba a msg:Agent admitted failure to sign using the key. Execute o comando ssh-add"
done
;;

*)
echo "Opção inválida!"
;;

esac 

#Caso não exista a chave pública no home do usuário corrente...
else
	for SERVER_SSH in `cat $SERVERS`;
	do	
	echo "###Chaves públicas não encontradas###"	
	echo "###Criando chaves locais###"
	#cria chave RSA
	ssh-keygen -t rsa
	cd $SSH_DIR
	cat $SSH_PUB_KEY_RSA > $SSH_AUTH_FILE
	chmod 600 $SSH_AUTH_FILE

	#cria chave DSA
	ssh-keygen -t dsa
	cd $SSH_DIR
	cat $SSH_PUB_KEY_DSA > $SSH_AUTH_FILE
	chmod 600 $SSH_AUTH_FILE

	echo "Servidor: $SERVER_SSH"
	echo "Digite o usuário remoto:["$L_USER"]"
	read USER
	#Verifica se é nulo	
	if [ -z $USER ]; then
		USER="$L_USER"
	fi

	echo "Digite a porta:[$SSH_PORT]"
	read PORT
	#Verifica se é nulo	
	if [ -z $PORT ]; then
		PORT=$SSH_PORT
	fi

	#Teste se existe arquivo autorized_keys
        echo "###--Verificando se existe arquivo de autorizacao de chaves..."
        ssh -l $USER -p $PORT $SERVER_SSH "touch $SSH_AUTH_FILE" || CHAVE_AUTH_FILE=1;

        if [ $CHAVE_AUTH_FILE -eq 0 ];
        then
        cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'cd .ssh; cat >> authorized_keys; chmod 600 authorized_keys'
        echo "Chave pública copiada para o Servidor: $SERVER_SSH";
        else
        cat id_rsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        cat id_dsa.pub | ssh -l $USER -p $PORT $SERVER_SSH 'mkdir .ssh; cd .ssh; cat > authorized_keys; chmod 600 authorized_keys'
        echo "Chave pública copiada para o Servidor: $SERVER_SSH";
        fi
	echo "Caso você receba a msg:Agent admitted failure to sign using the key. Execute o comando ssh-add"
	done

fi
exit 0
