#!/bin/bash
#-----------------------------------------------------------#
#           Script Deploy Dialog - Version: 1               #
#-----------------------------------------------------------#
#       Author: Bruno Ferreira - September / 2019           #
#       More at: https://github.com/bruno-sf                #
#-----------------------------------------------------------#
# Purpose: Deploy MY favorite programs with a decent interf.#
# Reqs: dialog                                              #
# Misc: You can easily convert to other SO not debian like, #
# just change the vars accordly: PKG_MGR,PKG_MGR_CMD,PKG_LST#
#-----------------------------------------------------------#

# [ Constantes ]
SCRIPT_NAME="Deploy Dialog"
VERSION="1.0"
PKG_MGR="apt-get"
PKG_MGR_CMD="install -yf"
PKG_LST="programas.txt"
DIALOG="dialog"
TMP_MENU=$(mktemp ".deploy.XXX")
TMP_SUBMENU=$(mktemp ".deploy.XXX")

# [ Funcs - BEGIN ]
fn_path () {
    #Internal function to validate the PATH of a program.
    PROGRAM="$1"    
    while [ $# -gt 0 ] ; do
        [ -z "$1" ]  && break;
        which -a "$PROGRAM" > /dev/null 2>&1 || return 1
        shift
    done
    return 0
}

fn_clean () {
    #Clean the mess before exit
    [ -e "$TMP_MENU" ] && rm -f "$TMP_MENU"
    [ -e "$TMP_SUBMENU" ] && rm -f "$TMP_SUBMENU"
    return 0
}

fn_make_menu () {
    #Aux func called before showmenu. The main menu will be mounted dinamically! Wow!
    #This func parses the $PKG_LST for group names inside brackets []
    #The PKG_LST must contain after the Group name, the program name 1 per line.
    #An empty line must precede the next group name.
    PROG_GROUP_NAMES=$(sed -n '/\[/p' $PKG_LST)

    [ -z "$PROG_GROUP_NAMES" ] && return 1
    #echo "Resultado:$PROG_GROUP_NAMES"
    TOTAL_GROUPS=$(echo "$PROG_GROUP_NAMES" | wc -l)
    #Too big, problem ahead
    [ $TOTAL_GROUPS -gt 98 ] && return 1
    #Too small, problem ahead too =P
    [ $TOTAL_GROUPS -lt 2 ] && return 1
    #Make the temp file for scratch the menu
    for LINHA in $PROG_GROUP_NAMES
    do
        echo "$LINHA" >> $TMP_MENU;
    done
    #Now an indexed menu
    MENU=$(cat -b "$TMP_MENU")
    [ -z $MENU ] && return 1
    return 0
}

fn_show_main_menu () {
    #Parse the VAR $PROG_GROUP_NAMES to make the menu
    #Show the main menu based on fn_make_menu
    while : ; do
        resposta=$($DIALOG --stdout --backtitle "Program: $SCRIPT_NAME - Version: $VERSION - Author: Bruno Ferreira" --title "[$SCRIPT_NAME]:Menu"\
        --menu "$USER, choose your destiny:" 0 0 0 $MENU 99 "Help" 0 "Exit") 

        # Apertou CANCELAR ou ESC, entao vamos sair...
        [ $? -ne 0 ] && break

        # Parse the response 
        if [[ $resposta -ge 1 && $resposta -le $TOTAL_GROUPS ]]
        then
            # call a generic function to make the apropiate submenu
            fn_make_submenu $resposta || fn_failexit "Can't make the submenu"
            fn_show_submenu || fn_failexit "Can't show the submenu"
        else
            case "$resposta" in
                99) fn_help ;;
                0) fn_exit ;;
                *) echo "Invalid option!" ;;
            esac
        fi   
    done
    # echo "Canceled..."
    fn_exit
}

fn_escape_for_sed () {
    # Aux func to make sed working. Thats it, I choose name that sed can't read if not escaped.
    # So if the input is: [DEV] the output of this function must be: \[DEV\]
    # Yeah I will use sed to suply sed with a proper format.Ugly but works.
    SED_INPUT="$1"
    SED_ESCAPED=$(sed 's/\[/\\[/;s/\]/\\]/g' <<<"$SED_INPUT")
    [ -z "$SED_ESCAPED" ] && return 1

    # Extract the content of programs between [GROUPNAME] and the last blank line
    sed -n "/$SED_ESCAPED/,/^ *$/p" "$PKG_LST" > "$TMP_SUBMENU"
    
    # Erase the first(Group name) and last line (blank line), 
    # and append " on" for dialogchecklist
    sed -i '1d;$d; s/$/ on/' "$TMP_SUBMENU"
}

fn_make_submenu () {
    # Aux func called before showsubmenu. The submenu will be mounted dinamically! Wow!
    # Parse the VAR $resposta to make the submenu for checklist dialog type.
    ID_MENU=$1
    PROG_GROUP_NAME=$(sh -c 'sed -n '${1}p' $@' "$ID_MENU" "$TMP_MENU")
    [ -z "$PROG_GROUP_NAME" ] && return 1
    
    # call fn_escape_for_sed to call sed like this: 
    # sed -n "/\[FUN\]/,/^ *$/p" "$PKG_LST" > "$TMP_SUBMENU"
    fn_escape_for_sed "$PROG_GROUP_NAME"
    
    [ -f "$TMP_SUBMENU" ] || return 1
    SUBMENU=$(cat -b "$TMP_SUBMENU" | xargs echo)
    return 0
}

fn_show_submenu () {
    # Show the sub menu based on fn_make_submenu.
    # Make the inner menu with checkboxes with the program name list.
    [ -z "$SUBMENU" ] && return 1
    CHOSEN_PKGS_TAGS=$($DIALOG --stdout --checklist "Section selected: $PROG_GROUP_NAME \n$USER, choose the programs you wish to install:" 0 0 0 $SUBMENU)
    [ -z "$CHOSEN_PKGS_TAGS" ] || fn_parse_chosen_pkg "$CHOSEN_PKGS_TAGS"
    [ -z "$PARSED_PKGS" ] || fn_confirm_install "$PARSED_PKGS"
    return 0
}

fn_parse_chosen_pkg () {
    # Because dialog return the item TAG and not the item we have to map again.
    # Example: TAGS will come like: 1 2 3 4 and will be converted to: 1p;2p;3p;4p;
    TAGS=$(echo $CHOSEN_PKGS_TAGS | sed 's/[[:space:]]/&p;/g; s/$/ p;/')
    PARSED_PKGS=$(sed -n "$TAGS" "$TMP_SUBMENU" | cut -d" " -f1 | xargs)
}

fn_confirm_install() {
    # Aux func called by fn_show_submenu
    $DIALOG --yesno "Please, confirm if you will install: \n\n$PARSED_PKGS" \
    0 0 && fn_install "$PARSED_PKGS"
}

fn_install () {
    # Make the package manager install the chosen pkgs.
    [ $(id -u) != "0" ] && sudo "$PKG_MGR" $(echo "$PKG_MGR_CMD" | tr -d "'") $(echo "$PARSED_PKGS" | tr -d "'") && return 0
    [ $(id -u) != "0" ] || "$PKG_MGR" $(echo "$PKG_MGR_CMD" | tr -d "'") $(echo "$PARSED_PKGS" | tr -d "'") && return 0
    return 1
    
}

fn_help () {
    $DIALOG --title "[$SCRIPT_NAME]: Help" --msgbox \
    "
    -------------------------------------------------------------------------------------
    Make sure the VARS \"PKG_MGR\" \"PKG_LST\" and \"PKG_MGR_CMD\" are proper configured.
    -------------------------------------------------------------------------------------

    I used to maintan a file called \"programas.txt\" with my favorite programs,
    to install them programattically on my machines. But the file became too
    big and not suitable for every machine. Well why would I need my security 
    tools on my Dev machine and my Dev tools on my Pentest machine...
       
    So this program was written to provide a simplified but better looking, 
    and organized interface to install my favorite programs via CLI. It's built
    for interactive install, but can easily be converted to automated deploy.

                    Author: Bruno Ferreira - September / 2019           
                        More at: https://github.com/bruno-sf 

    -------------------------------------------------------------------------------------
    " 0 0
}

fn_exit () {
    $DIALOG --title "[$SCRIPT_NAME]:" --infobox "Bye, thanks for using it." 3 30
    fn_clean && sleep 1 && exit 0 
}

fn_failexit () {
    MSG="$1"
    $DIALOG --title "[$SCRIPT_NAME - FAIL]:" --msgbox "[ERROR]: $MSG" 0 0
    fn_clean && sleep 1 && exit 2
}

fn_install_dialog () {
    # Try to install $DIALOG package
    read -p "Can I try to install the $DIALOG package for you? [Y/n]" RESP
    case "$RESP" in 
        Y|y) echo "Okay, using $PKG_MGR to install $DIALOG..."; \
            [ $(id -u) != "0" ] && sudo "$PKG_MGR" $(echo "$PKG_MGR_CMD" | tr -d "'") "$DIALOG"; \
            [ $(id -u) != "0" ] || "$PKG_MGR" $(echo "$PKG_MGR_CMD" | tr -d "'") "$DIALOG" ;;
        N|n) echo "Okay, maybe later...See you."; fn_clean; exit ;;
        *)   echo "Invalid option..."; fn_clean; exit ;;
    esac
}

# [ Funcs - END ]

# [ Essential checks ]
[ -r "$PKG_LST" ] || { echo "$SCRIPT_NAME - [ERROR]: Please, provide a Package List, cant find: $PKG_LST" ; exit 1; }
fn_path "$PKG_MGR" || { echo "$SCRIPT_NAME - [ERROR]: Can't find the Package Manager: $PKG_MGR ." ; exit 1; }
fn_path "$DIALOG" || { echo "$SCRIPT_NAME - [ERROR]: Please, install $DIALOG before runnning me." ; fn_install_dialog ; }

# [ Start ]
fn_make_menu || fn_failexit "Can't make the menu dinamically."
fn_show_main_menu || fn_failexit "Can't show the main menu."

# [ Trap for clean exit ]
trap fn_clean EXIT HUP STOP TERM
fn_exit