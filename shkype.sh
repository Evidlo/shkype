#!/bin/bash

TITLE=Shkype
PORT_STATUS=8000
PORT_VIDEO=8001

selected_contact=""
pending_request=/tmp/pending_request

interface=$(ip route|awk '/default/{print $5;exit}')
ip_addr=$(ip addr show $interface|awk '/inet/{split($2, a, "/");print a[1];exit}')

function foo() {
    echo "$1" >> /tmp/log
}

foo "--------------------------"


function contacts() {
    # get whiptail output
    # https://stackoverflow.com/questions/1970180/whiptail-how-to-redirect-output-to-environment-variable
    selected_contact=$(
        whiptail \
            --title "$TITLE" \
            --menu "Choose a contact to call" 30 50 16 \
            "Bobby" "" \
            "Hank" "" \
            "Peggy" "" \
            "Luanne" "" \
            "Dale" "" 3>&1 1>&2 2>&3
    )
    if (( $? == 0 ))
    then
        # FIXME - global variable hack for contacts subshell
        touch $pending_request
        foo "selected_contact: $selected_contact"
        # request
        nc 10.192.38.171 $PORT_STATUS <<< $ip_addr
    fi
}

foo "calling contacts"
contacts &

while true
do

    # accept/request
    foo "waiting request"
    incoming_call=$(nc -l $PORT_STATUS)

    foo "pending_request: $pending_request"

    # kill contacts subshell
    killall whiptail

    if [ -f $pending_request ]
    then # accept
        foo "selected_contact"

        (mpv /dev/video0 --fps=15 --vo=tct 2>/dev/null| nc $incoming_call $PORT_VIDEO) &

        nc -l -p $PORT_VIDEO &
        nc $incoming_call $PORT_STATUS <<< $ip_addr

        # FIXME
        sleep 120

    else # request (receiver)
        foo "incoming call"
        whiptail --title "$TITLE" --yesno "Incoming call from $incoming_call. Accept?" 8 78
        # FIXME
        if true
        then
            nc -l -p $PORT_VIDEO &
            (nc -l -p $PORT_STATUS; mpv /dev/video0 --fps=15 --vo=tct 2>/dev/null | nc $incoming_call $PORT_VIDEO) &
            nc $incoming_call $PORT_STATUS <<< $ip_addr

            # FIXME
            sleep 120
        else
            echo foop
        fi

        foo "accepted/rejected call"
    fi

done

reset
