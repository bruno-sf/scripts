#!/bin/bash -p
#-----------------------------------------------------------#
#			Script Apache Log Parser - Versao:1             #
#-----------------------------------------------------------#
#		Data de criacao:09/07/2019-Ultima Edicao:09/07/2019 #
#       Bugs e Correcoes:brunosilvaferreira@protonmail.com  #
#       More at: https://github.com/bruno-sf 	            #
#-----------------------------------------------------------#
#Script based on example from Mr. Dave Taylor - Linux Journal
#Reqs: dialog (apt-get install dialog / yum install dialog)
#Usage ./script or ./script LOGFILE 

SCRIPT_NAME="Apache2 Logs Parser"
DIALOG="dialog"
[ "$1" ] && LOGPATH="$1" || LOGPATH="/var/log/apache2/access.log"

fnchk () {
    # Desc: Aux. Func for checking if essential requirements are met. 
    if which -a $DIALOG > /dev/null ; then
        [ -f $LOGPATH ] || \
        { echo "[$SCRIPT_NAME]:Usage ./script LOGFILE - Can't find \"$LOGPATH\""; exit 1; }
        [ -s $LOGPATH ] || \
        { echo "[$SCRIPT_NAME]: \"$LOGPATH\" is empty! Exiting..."; exit 1; }        
    else
        echo "[$SCRIPT_NAME]:Can't find program dialog, please install it first."
        echo "Hint:(apt-get install dialog / yum install dialog)"
        exit 1;
    fi
}

fnval_input () {
    #Desc: Aux. Func to validate script expected input format like DATE, CODE...
    #usage ex:fnval_input 20 "URL"
    INPUT="$1"
    TYPE=$(echo "$2" | tr 'a-z' 'A-Z')
    if [ "$TYPE" == "CODE" -o "$TYPE" == "URL" ];then 
        echo "$INPUT" | egrep ^"[A-Za-z]+://" > /dev/null && return 0 #URL begin pattern detected!
        echo "$INPUT" | egrep "^[0-9][0-9][0-9]$" > /dev/null && return 0
        return 1 
    else
        return 1
    fi    
}
    
fnparse_basic () {
    # Desc :Func for showing basic report parsing info like DATE, IP, RETCODE and URL.
    REPORT=$(mktemp "/tmp/basic_report.XXX")
    TOTAL=$(wc -l $LOGPATH | cut -d" " -f1)
    LINE=1

    (
    while read logentry
    do
        f1=$(echo "$logentry" | cut -d\" -f1) #IP And Full Date
        IP=$(echo "$f1" | cut -f1 -d\ ) #Extract IP
        DATE=$(echo "$f1" |cut -f4 -d\ | grep -i "[0-9,:,a-z,\/]" | tr -d "[")
        f3=$(echo "$logentry" | cut -d\" -f3) #Extract retcode and bytes
        RETCODE=$(echo "$f3" | cut -f2 -d\ ) #Extract retcode
        URL=$(echo "$logentry" | cut -d\" -f4) #Extract URL
        
        LINE=$LINE+1
        PERCENT=$((LINE*100/TOTAL))
        echo $PERCENT

        fnval_input $RETCODE "CODE" || continue #if not valid, discard logentry.
        fnval_input $URL "URL" || continue
        echo "[DATE]:$DATE [IP]:$IP [CODE]:$RETCODE [URL]:$URL" >> $REPORT
    done < $LOGPATH
    echo 100
    ) | $DIALOG --title "[$SCRIPT_NAME]:" --gauge "Please wait..." 0 0
    
    if [ -s $REPORT ]; then
        $DIALOG --title "[$SCRIPT_NAME]: Basic report" --textbox "$REPORT" 0 0
    else
        $DIALOG --title "[$SCRIPT_NAME]: Basic report" --msgbox "The Report is empty!No messages founded." 0 0
    fi
    rm -f $REPORT
}

fnparse_custom () {
    # Desc :Func for showing results not 200.
    $DIALOG --title "[$SCRIPT_NAME]: Not done yet" --msgbox "\nSorry, time is short, not done yet..." 0 0
    return

    while read logentry

    do
       echo "f1 = $(echo "$logentry" | cut -d\" -f1)" #IP - DATA
       echo "f2 = $(echo "$logentry" | cut -d\" -f2)" #METODO - URL

       f3=$(echo "$logentry" | cut -d\" -f3) #RET CODE - BYTES
       returncode="$(echo $f3 | cut -f1 -d\  )" 
       bytes="$(echo $f3 | cut -f2 -d\  )"
       #echo "f3 = $(echo "$logentry" | cut -d\" -f3)"
       echo "f3 ret code: $returncode"
       echo "f3 bytes: $bytes"

       echo "f4 = $(echo "$logentry" | cut -d\" -f4)" # FULL URL
       echo "f5 = $(echo "$logentry" | cut -d\" -f5)" # VAZIO
       echo "f6 = $(echo "$logentry" | cut -d\" -f6)" # UserAgent
    done < $LOGPATH
}

fnparse_notok () {
    # Desc :Func for showing summarized results not 200.
    REPORT=$(mktemp "/tmp/notok_report.XXX")
    REPORT_SUM=$(mktemp "/tmp/notok_report.XXXX")
    TOTAL=$(wc -l $LOGPATH | cut -d" " -f1)
    LINE=1
    FDATE=$(head -1 $LOGPATH | cut -d\" -f1 |cut -f4 -d\ | grep -i "[0-9,:,a-z,\/]" | tr -d "[")
    LDATE=$(tail -1 $LOGPATH | cut -d\" -f1 |cut -f4 -d\ | grep -i "[0-9,:,a-z,\/]" | tr -d "[")
    (
    while read logentry
    do
        f3=$(echo "$logentry" | cut -d\" -f3) #Ret Code and Bytes
        RETCODE="$(echo $f3 | cut -f1 -d\  )"
        if [ ! $RETCODE -eq 200 ]; then            
            f1=$(echo "$logentry" | cut -d\" -f1) #IP And Full Date
            IP=$(echo "$f1" | cut -f1 -d\ ) #Extract only IP
            f2=$(echo "$logentry" | cut -d\" -f2) #Method and URL
            METHOD=$(echo $f2 | cut -f1 -d\  ) #Extract Method only
            UAGENT=$(echo "$logentry" | cut -d\" -f6)
            echo "hits - [From]:$IP - [Method]:$METHOD - [UAgent]:$UAGENT" >> $REPORT #Extract only IP
        fi

        LINE=$LINE+1
        PERCENT=$((LINE*100/TOTAL))
        echo $PERCENT

    done < $LOGPATH
    echo 100
    ) | $DIALOG --title "[$SCRIPT_NAME]:" --gauge "Please wait..." 0 0

    if [ -s $REPORT ]; then
        uniq -c $REPORT $REPORT_SUM
        echo "    [First entry]: $FDATE - [Last entry]: $LDATE" >> $REPORT_SUM
        $DIALOG --title "[$SCRIPT_NAME]: Not OK report" --textbox "$REPORT_SUM" 0 0
    else
        $DIALOG --title "[$SCRIPT_NAME]: Not OK report" --msgbox "The Report is empty!No messages founded." 0 0
    fi
    rm -f $REPORT $REPORT_SUM
}

fnparse_ok () {
    # Desc :Func for showing results summarized with code 200.
    REPORT=$(mktemp "/tmp/ok_report.XXX")
    REPORT_SUM=$(mktemp "/tmp/ok_report.XXXX")
    TOTAL=$(wc -l $LOGPATH | cut -d" " -f1)
    LINE=1
    FDATE=$(head -1 $LOGPATH | cut -d\" -f1 |cut -f4 -d\ | grep -i "[0-9,:,a-z,\/]" | tr -d "[")
    LDATE=$(tail -1 $LOGPATH | cut -d\" -f1 |cut -f4 -d\ | grep -i "[0-9,:,a-z,\/]" | tr -d "[")
    (
    while read logentry
    do
        f3=$(echo "$logentry" | cut -d\" -f3) #Ret Code and Bytes
        RETCODE="$(echo $f3 | cut -f1 -d\  )"
        if [ $RETCODE -eq 200 ]; then            
            f1=$(echo "$logentry" | cut -d\" -f1) #IP And Full Date
            IP=$(echo "$f1" | cut -f1 -d\ ) #Extract only IP
            f2=$(echo "$logentry" | cut -d\" -f2) #Method and URL
            METHOD=$(echo $f2 | cut -f1 -d\  ) #Extract Method only
            UAGENT=$(echo "$logentry" | cut -d\" -f6)
            echo "hits - [From]:$IP - [Method]:$METHOD - [UAgent]:$UAGENT" >> $REPORT #Extract only IP
        fi

        LINE=$LINE+1
        PERCENT=$((LINE*100/TOTAL))
        echo $PERCENT

    done < $LOGPATH
    echo 100
    ) | $DIALOG --title "[$SCRIPT_NAME]:" --gauge "Please wait..." 0 0

    if [ -s $REPORT ]; then
        uniq -c $REPORT $REPORT_SUM
        echo "    [First entry]: $FDATE - [Last entry]: $LDATE" >> $REPORT_SUM
        $DIALOG --title "[$SCRIPT_NAME]: OK report" --textbox "$REPORT_SUM" 0 0
    else
        $DIALOG --title "[$SCRIPT_NAME]: OK report" --msgbox "The Report is empty!No messages founded." 0 0
    fi
    rm -f $REPORT $REPORT_SUM
}

fnexit () {
    $DIALOG --title "[$SCRIPT_NAME]:" --infobox "Bye, thanks for using it." 0 0
    sleep 1
    exit 0 
}

fnhelp () {
    $DIALOG --title "[$SCRIPT_NAME]: Help" --msgbox \
    "
    This script is suited for Apache2 logs format only. 
    It's just a viewer tool for eyes relief =)
    -------------------------------------------------------------------
    1)Basic report - Show the basic info  from logfile.
    2)OK (code 200) entries - Show all entries which return code is 200 (Summary).
    3)Show not OK entries - Show all entries which return code is not 200 (Summary).
    4)Custom report - NOT DONE YET. Choose what field you want to extract from log
    (Choose POST entries - Show only entries with POST method (Summary),
    GET entries - Show only entries with GET method (Summary).
    " 0 0
}

fnmenu () {
# Desc: Funcao que carrega o menu principal.
    while : ; do
        resposta=$($DIALOG --stdout --title "[$SCRIPT_NAME]:Menu"\
        --menu "$USER, choose your destiny:"\
        0 0 0\
        1 "Basic report"\
        2 "OK entries (HTTP 200)"\
        3 "Not OK entries"\
        4 "Custom report"\
        5 "Help"\
        0 "Quit")

        # Apertou CANCELAR ou ESC, entao vamos sair...
        [ $? -ne 0 ] && break

        # De acordo com a opção escolhida, dispara programas/funcoes
        case "$resposta" in
        1) fnparse_basic ;;
        2) fnparse_ok ;;
        3) fnparse_notok ;;
        4) fnparse_custom ;;
        5) fnhelp ;;
        0) fnexit ;;
        *) echo "Invalid option!" ;;
        esac
    done

    echo "Canceled..."
    exit 0
}

clear
trap "exit 2" 1 2 3 15
fnchk
fnmenu
exit 0