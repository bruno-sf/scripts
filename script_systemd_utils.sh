#!/usr/bin/env bash
#-------------------------------------------------------#
#               Script Systemd Utils                    #
#               Criado em: 22/06/2020                   #
#-------------------------------------------------------#
# Descricao: Script escrito para agrupar os cmds mais   #
# comuns do systemd.                                    #
# Description: Script written to group some of the most #
# used commands from systemd.                           #
#-------------------------------------------------------#
# Reqs:bash, systemd                                    #
#########################################################

fn_banner() {
    cat << "EOF"

:'######::'##:::'##::'######::'########:'########:'##::::'##:'########::
'##... ##:. ##:'##::'##... ##:... ##..:: ##.....:: ###::'###: ##.... ##:
 ##:::..:::. ####::: ##:::..::::: ##:::: ##::::::: ####'####: ##:::: ##:
. ######::::. ##::::. ######::::: ##:::: ######::: ## ### ##: ##:::: ##:
:..... ##:::: ##:::::..... ##:::: ##:::: ##...:::: ##. #: ##: ##:::: ##:
'##::: ##:::: ##::::'##::: ##:::: ##:::: ##::::::: ##:.:: ##: ##:::: ##:
. ######::::: ##::::. ######::::: ##:::: ########: ##:::: ##: ########::
:......::::::..::::::......::::::..:::::........::..:::::..::........:::
'##::::'##:'########:'####:'##::::::::'######::                         
 ##:::: ##:... ##..::. ##:: ##:::::::'##... ##:                         
 ##:::: ##:::: ##::::: ##:: ##::::::: ##:::..::                         
 ##:::: ##:::: ##::::: ##:: ##:::::::. ######::                         
 ##:::: ##:::: ##::::: ##:: ##::::::::..... ##:                         
 ##:::: ##:::: ##::::: ##:: ##:::::::'##::: ##:                         
. #######::::: ##::::'####: ########:. ######::                         
:.......::::::..:::::....::........:::......:::                                       
            Version 1 - Author Bruno Ferreira 
EOF
}

fn_echo_color () {
    COLOR=$(echo "$2" | tr '[:lower:]' '[:upper:]')
    case $COLOR in
    "RED") echo -e "\e[31;1m $1 \e[m" ;;
    "GREEN") echo -e "\e[32;1m $1 \e[m" ;;
    "BLUE") echo -e "\e[34;1m$1 \e[m" ;;
    *) echo -e "\e[33;1m $1 \e[m" ;;
    esac
}

fn_menu () {   
    fn_echo_color "###---Choose your destiny:---###" "BLUE"
    echo "1)List all unit files"
    echo "2)List specific unit files"
    echo "3)List all units"
    echo "4)List specific units"
    echo "5)Start a service"
    echo "6)Stop a service"
    echo "7)Restart a service"
    echo "8)Enable a service at boot"
    echo "9)Disable a service at boot"
    echo "10)Check if a service is already boot enabled"
    echo "11)Show host system info"
    echo "12)Show datetime system info"
    echo "13)Show today only logs"
    echo "14)Show logs since yesterday"
    echo "15)Check each service time consumption at startup"
    echo "16)Check system boot time"
    echo "17)Show system status"
    echo "18)Kill all processes associated with a service"
    fn_echo_color "0)Exit" "BLUE"
    echo "Type the number of option:"
    read OPT

    #Verifica se é válido 
    if [ -z $OPT ]
    then
        echo "Invalid option..."
    else

        case $OPT in
        1) fn_lst_unit_files ;;
        2) fn_lst_unit_files_grep ;;
        3) fn_lst_units ;;
        4) fn_lst_units_grep ;;
        5) fn_start_svc ;;
        6) fn_stop_svc ;;
        7) fn_rst_svc ;;
        8) fn_en_boot ;;
        9) fn_dis_boot ;;
        10) fn_chk_boot ;;
        11) fn_host_info ;;
        12) fn_timedate ;;
        13) fn_tod_logs ;;
        14) fn_yest_logs ;;
        15) fn_chk_svc_time ;;
        16) fn_chk_boot_time ;;
        17) fn_sys_status ;;
        18) fn_kill_procs_svc ;;
        
        0) { echo "See you!"; exit 0; } ;;
        *) echo "Invalid option!" ;;
        esac
    fi
}

fn_lst_unit_files () {
    # [1] A unit file is a plain text ini-style file that encodes information about a service, a socket, a device, a mount point, an automount point, a swap file or partition, a start-up target, a watched file system path, a timer controlled and supervised by systemd, a resource management slice, or a group of externally created processes.
    systemctl list-unit-files || return 1    
}

fn_lst_unit_files_grep () {
    # [2] Same as fn_lst_unit_files but with grep duh.
    echo "Type the name of the service:"
    read SVC_NAME
    systemctl list-unit-files | grep -i "$SVC_NAME"
}

fn_lst_units () {
    #[3] Listing active units displays a lot of useful information about your loaded and active services.
    systemctl list-units || return 1
    return 0
}

fn_lst_units_grep () {
    # [4] Same as fn_lst_units but with grep duh.
    echo "Type the name of the service:"
    read SVC_NAME
    systemctl list-units | grep -i "$SVC_NAME"
}

fn_start_svc () {
    # [5] starting, stopping, or restarting a service. and  check the status of a service.
    echo "Type the name of the service you wish to START:"
    read SVC_NAME
    systemctl start $SVC_NAME && systemctl status "$SVC_NAME"
    
}

fn_stop_svc () {
    # [6] starting, stopping, or restarting a service. and  check the status of a service.
    echo "Type the name of the service you wish to STOP:"
    read SVC_NAME
    systemctl stop $SVC_NAME && systemctl status $SVC_NAME
}

fn_rst_svc () {
    # [7] starting, stopping, or restarting a service. and  check the status of a service.
    echo "Type the name of the service you wish to RESTART:"
    read SVC_NAME
    systemctl restart $SVC_NAME && systemctl status $SVC_NAME
}

fn_en_boot () {
    # [8] Enabling a service to run at boot time
    echo "Type the name of the service you wish to ENABLE at boot:"
    read SVC_NAME
    systemctl enable $SVC_NAME || { fn_echo_color "Fail to enable at boot $SVC_NAME service!" "RED"; return 1; }
    return 0
}

fn_dis_boot () {
    # [9] Disabling a service to run at boot time
    echo "Type the name of the service you wish to DISABLE at boot:"
    read SVC_NAME
    systemctl disable $SVC_NAME || { fn_echo_color "Fail to disable at boot $SVC_NAME service!" "RED"; return 1; }
        fn_echo_color "Service $SVC_NAME successfully boot enabled!" "GREEN"
        return 0
}

fn_chk_boot () {
    # [10] Check if a service is already boot enabled
    echo "Type the name of the service you wish to CHECK at boot:"
    read SVC_NAME
    systemctl is-enabled $SVC_NAME || { fn_echo_color "Service $SVC_NAME IS NOT boot enabled!" "RED"; return 1; }
    fn_echo_color "Service $SVC_NAME IS ALREADY boot enabled!" "GREEN"
    return 0
}

fn_host_info () {
    # [11] Show host info
    hostnamectl
}

fn_timedate () {
    # [12] Show datetime system info
    timedatectl
}

fn_tod_logs () {
    # [13] Show today logs
    journalctl --since="today"
}

fn_yest_logs () {
    # [14] Show yesterday logs
    journalctl --since="yesterday"
}

fn_chk_svc_time () {
    # [15] Check each service time consumption at startup
    systemd-analyze blame
}

fn_chk_boot () {
    # [16] Check system boot time
    systemd-analyze
}

fn_sys_status () {
    # [17] Show system status
    systemctl status
}

fn_kill_procs_svc () {
    # [18] Kill all processes associated with a service
    echo "Type the name of the service you wish to KILL all processes associated with:"
    read SVC_NAME
    systemctl kill "$SVC_NAME"
}

clear
fn_banner
while true
do
    fn_menu
done
