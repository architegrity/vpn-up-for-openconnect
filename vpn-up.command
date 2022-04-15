#!/bin/bash

# Author: Sorin-Doru Ipate
# Edited by: Mohammad Amin Dadgar
# Copyright (c) Sorin-Doru Ipate

PROGRAM_NAME=$(basename $0)

PID_FILE_PATH="${PWD}/${PROGRAM_NAME}.pid"
LOG_FILE_PATH="${PWD}/${PROGRAM_NAME}.log"

# OPTIONS
BACKGROUND=TRUE
    # TRUE          Runs in background after startup
    # FALSE         Runs in foreground after startup

QUIET=TRUE
    # TRUE          Less output
    # FALSE         Detailed output

SUDO=FALSE
    # TRUE          
    # FALSE         
SUDO_PASSWORD=""

PRIMARY="\x1b[36;1m"
SUCCESS="\x1b[32;1m"
WARNING="\x1b[35;1m"
DANGER="\x1b[31;1m"
RESET="\x1b[0m"
  
# VPN PROFILE 1
export VPN1_NAME="VPN PROFILE 1"
export VPN1_PROTOCOL=<protocol>
    # anyconnect       Compatible with Cisco AnyConnect SSL VPN, as well as ocserv (default)
    # nc               Compatible with Juniper Network Connect
    # gp               Compatible with Palo Alto Networks (PAN) GlobalProtect SSL VPN
    # pulse            Compatible with Pulse Connect Secure SSL VPN
export VPN1_HOST=<vpn.url>
export VPN1_AUTHGROUP=<group>
export VPN1_USER=<username>
export VPN1_PASSWD="<password>"
export VPN1_DUO2FAMETHOD="<2famethod>"  # Duo 2FA Method
    # passcode         Log in using a passcode, either generated with Duo Mobile, sent via SMS, generated by your hardware token, or provided by an administrator. E.g. to use the passcode “123456," type 123456
    # push             Push a login request to your registered phone (if you have Duo Mobile installed and activated on your iOS, or Windows phone device). Just review the request and select Approve to log in.
    # phone            Authenticate via callback to your registered phone.
    # sms              Sends an SMS message with a new batch of passcodes to your registered device. Your initial login attempt will fail. Login again with one of the new passcodes.
export VPN1_SERVER_CERTIFICATE=""  # SHA1

# VPN PROFILE 2
export VPN2_NAME="VPN PROFILE 2"
export VPN2_PROTOCOL=<protocol>
    # anyconnect       Compatible with Cisco AnyConnect SSL VPN, as well as ocserv (default)
    # nc               Compatible with Juniper Network Connect
    # gp               Compatible with Palo Alto Networks (PAN) GlobalProtect SSL VPN
    # pulse            Compatible with Pulse Connect Secure SSL VPN
export VPN2_HOST=<vpn.url>
export VPN2_AUTHGROUP=<group>
export VPN2_USER=<username>
export VPN2_PASSWD="<password>"
export VPN2_DUO2FAMETHOD="<2famethod>"  # Duo 2FA Method
    # passcode         Log in using a passcode, either generated with Duo Mobile, sent via SMS, generated by your hardware token, or provided by an administrator. E.g. to use the passcode “123456," type 123456
    # push             Push a login request to your registered phone (if you have Duo Mobile installed and activated on your iOS, or Windows phone device). Just review the request and select Approve to log in.
    # phone            Authenticate via callback to your registered phone.
    # sms              Sends an SMS message with a new batch of passcodes to your registered device. Your initial login attempt will fail. Login again with one of the new passcodes.
export VPN2_SERVER_CERTIFICATE=""  # SHA1

function start(){

    if ! is_network_available
        then 
            printf "$DANGER"
            printf "Please check your internet connection or try again later!\n"
            printf "$RESET"
            exit 1
    fi

    if is_vpn_running
        then
            printf "$WARNING"
            printf "Already connected to a VPN!\n"
            printf "$RESET"
            exit 1
    fi

    if [ "$SUDO" = TRUE ]
        then
            if [[ -z $SUDO_PASSWORD ]]
                then
                    printf "$DANGER"
                    printf "Variable 'SUDO_PASSWORD' is not declared! Update the variable 'SUDO_PASSWORD' declaration in OPTIONS ..."
                    printf "$RESET"
                    return
                else
                    echo sudo -S <<< $SUDO_PASSWORD
                    printf "$WARNING"
                    printf "Running as root ...\n"
                    printf "$RESET"
            fi
        else
            printf "$WARNING"
            printf "Running as normal user! OpenConnect requires to be executed with root privileges; please enter the root password when prompted...\n"
            printf "$RESET"

    fi

    printf "$PRIMARY"
    printf "Starting $PROGRAM_NAME ...\n"
    printf "$RESET"
    
    printf "$WARNING"
    printf "Process ID (PID) stored in $PID_FILE_PATH ...\n"
    printf "$RESET"

    printf "$WARNING"
    printf "Logs file (LOG) stored in $LOG_FILE_PATH ...\n"
    printf "$RESET"

    printf "$PRIMARY"
    printf "Which VPN do you want to connect to?\n"
    options=("$VPN1_NAME" "$VPN2_NAME" "Quit")
    printf "$RESET"
    select option in "${options[@]}";
        do
            case $option in
                "$VPN1_NAME")
                    export VPN_NAME=$VPN1_NAME
                    export VPN_HOST=$VPN1_HOST
                    export VPN_GROUP=$VPN1_AUTHGROUP
                    export VPN_USER=$VPN1_USER
                    export VPN_PASSWD=$VPN1_PASSWD
                    export VPN_DUO2FAMETHOD=$VPN1_DUO2FAMETHOD
                    export SERVER_CERTIFICATE=$VPN1_SERVER_CERTIFICATE
                    export PROTOCOL=$VPN1_PROTOCOL
                    connect
                    break
                    ;;
                "$VPN2_NAME")
                    export VPN_NAME=$VPN2_NAME
                    export VPN_HOST=$VPN2_HOST
                    export VPN_GROUP=$VPN2_AUTHGROUP
                    export VPN_USER=$VPN2_USER
                    export VPN_PASSWD=$VPN2_PASSWD
                    export VPN_DUO2FAMETHOD=$VPN2_DUO2FAMETHOD
                    export SERVER_CERTIFICATE=$VPN2_SERVER_CERTIFICATE
                    export PROTOCOL=$VPN2_PROTOCOL
                    connect
                    break
                    ;;
                "Quit")
                    printf "$WARNING"
                    printf "You chose to close the app!\n"
                    printf "$RESET"
                    exit
                    ;;
                *)
                
                printf "$DANGER"
                printf "Invalid option! Please choose one of the options above...\n"
                printf "$RESET"
                printf "$REPLY";;
            esac
        done
    if is_vpn_running
                then 
                    printf "$SUCCESS"
                    printf "Connected to $VPN_NAME\n"
                    print_current_ip_address
                    printf "$RESET"
                else
                    printf "$DANGER"
                    printf "Failed to connect!\n"
                    printf "$RESET"
            fi
}

function connect(){
    if [[ -z $VPN_HOST ]]
        then
            printf "$DANGER"
            printf "Variable 'VPN_HOST' is not declared! Update the variable 'VPN_HOST' declaration in VPN PROFILES ...\n"
            printf "$RESET"
            return
    fi
    if [[ -z $PROTOCOL ]]
        then
            printf "$DANGER"
            printf "Variable 'PROTOCOL' is not declared! Update the variable 'PROTOCOL' declaration in VPN PROFILES ..."
            printf "$RESET"
            return
    fi

    case $PROTOCOL in
        "anyconnect")
            export PROTOCOL_DESCRIPTION="Cisco AnyConnect SSL VPN"
            ;;
        "nc")
            export PROTOCOL_DESCRIPTION="Juniper Network Connect"
            ;;
        "gp")
            export PROTOCOL_DESCRIPTION="Palo Alto Networks (PAN) GlobalProtect SSL VPN"
            ;;
        "pulse")
            export PROTOCOL_DESCRIPTION="Pulse Connect Secure SSL VPN"
            ;;
        *)
            printf "$DANGER"
            printf "Unsupported protocol! Update the variable 'PROTOCOL' declaration in VPN PROFILES ..."
            printf "$RESET"
            return
            ;;
    esac

    case $VPN_DUO2FAMETHOD in
        "push")
            export VPN_DUO2FAMETHOD_DESCRIPTION="PUSH"
            ;;
        "phone")
            export VPN_DUO2FAMETHOD_DESCRIPTION="PHONE"
            ;;
        "sms")
            export VPN_DUO2FAMETHOD_DESCRIPTION="SMS"
            ;;
        "")
            export VPN_DUO2FAMETHOD_DESCRIPTION="NONE"
            ;;
        *)
            if [[ "$VPN_DUO2FAMETHOD" =~ ^[0-9]{6}$ ]]
                then
                    export VPN_DUO2FAMETHOD_DESCRIPTION="PASSCODE"
                else
                    printf "$DANGER"
                    printf "Unsupported PASSCODE format! Update the variable 'VPN_DUO2FAMETHOD' declaration in VPN PROFILES ..."
                    printf "$RESET"
                    return
            fi
            ;;
    esac
        
    printf "$PRIMARY"
    printf "Starting the $VPN_NAME on $VPN_HOST using $PROTOCOL_DESCRIPTION ...\n"
    printf "$RESET"

    if [ "$VPN_DUO2FAMETHOD" = "" ]
        then
            printf "$WARNING"
            printf "Connecting without 2FA ($VPN_DUO2FAMETHOD_DESCRIPTION) ...\n"
            printf "$RESET"
            if [ "$SERVER_CERTIFICATE" = "" ]
                then
                    printf "$WARNING"
                    printf "Connecting without server certificate ...\n"
                    printf "$RESET"
                    if [ "$BACKGROUND" = TRUE ]
                        then
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME in background ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL --background -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL --background $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        else
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        fi
                else
                    printf "$PRIMARY"
                    printf "Connecting with certificate ...\n"
                    printf "$RESET"
                    if [ "$BACKGROUND" = TRUE ]
                        then
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME in background ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL --background -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL --background $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        else
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                echo $VPN_PASSWD | sudo openconnect --protocol=$PROTOCOL $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        fi
                fi

        else
            printf "$PRIMARY"
            printf "Connecting with Two-Factor Authentication (2FA) from Duo ($VPN_DUO2FAMETHOD_DESCRIPTION) ...\n"
            printf "$RESET"
            if [ "$SERVER_CERTIFICATE" = "" ]
                then
                    printf "$WARNING"
                    printf "Connecting without server certificate ...\n"
                    printf "$RESET"
                    if [ "$BACKGROUND" = TRUE ]
                        then
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME in background ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL --background -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL --background $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        else
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        fi
                else
                    printf "$PRIMARY"
                    printf "Connecting with certificate ...\n"
                    printf "$RESET"
                    if [ "$BACKGROUND" = TRUE ]
                        then
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME in background ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL --background -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL --background $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        else
                            printf "$PRIMARY"
                            printf "Running the $VPN_NAME ...\n"
                            printf "$RESET"
                            if [ "$QUIET" = TRUE ]
                            then
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with less output (quiet) ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL -q $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            else
                                printf "$PRIMARY"
                                printf "Running the $VPN_NAME with detailed output ...\n"
                                printf "$RESET"
                                { echo $VPN_PASSWD; sleep 1; echo $VPN_DUO2FAMETHOD; } | sudo openconnect --protocol=$PROTOCOL $VPN_HOST --user=$VPN_USER --authgroup=$VPN_GROUP --passwd-on-stdin --servercert=$SERVER_CERTIFICATE --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
                            fi
                        fi
                fi
        fi
    #status
}

function status() {
    if is_vpn_running
        then
            printf "$SUCCESS"
            printf "Connected ...\n"
        else
            printf "$PRIMARY"
            printf "Not connected ...\n"      
    fi
    print_current_ip_address
    printf "$RESET"
}

function stop() {
    
    if is_vpn_running
        then
            printf "$WARNING"
            printf "Connected ...\nRemoving $PID_FILE_PATH ...\n"
            printf "$RESET"
            local pid=$(cat $PID_FILE_PATH)
            kill -9 $pid > /dev/null 2>&1
            rm -f $PID_FILE_PATH > /dev/null 2>&1
            printf "$SUCCESS"
            printf "Disconnected ...\n"
        else
            printf "$PRIMARY"
            printf "Disconnected ...\n"
    fi
    
    print_current_ip_address
    printf "$RESET"
}

function print_info() {
    
    printf "$WARNING"
    printf "Usage: $(basename "$0") (start|stop|status|restart)\n"
    printf "$RESET"

}

function is_network_available() {
    ping -q -c 1 -W 1 8.8.8.8 > /dev/null 2>&1;
}

function is_vpn_running() {
    test -f $PID_FILE_PATH && return 0
}

function print_current_ip_address() {
    local ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
    printf "Your IP address is $ip ...\n"
}

case "$1" in

	start)
	
		start
		;;
	
	stop)
	
		stop
		;;
	
	status)
	
		status
		;;
	
	restart)
	
		$0 stop
		$0 start
		;;
	
	*)
	
		print_info
		exit 0
		;;
esac