#!/bin/bash

TITLE=Shkype
CONTACTS_FILE=/tmp/contacts.txt

if [ -f ${PORT_STATUS} ]
then
    PORT_STATUS=8123
fi
if [ -f ${PORT_VIDEO} ]
then
    PORT_VIDEO=8124
fi

selected_contact=""
sender=/tmp/sender
rm -f $sender

interface=$(ip route|awk '/default/{print $5;exit}')
ip_addr=$(ip addr show $interface|awk '/inet/{split($2, a, "/");print a[1];exit}')

function log() {
    echo "$1" >> /tmp/log
}

log "--------------------------"


function contacts() {
    # get whiptail output
    # https://stackoverflow.com/questions/1970180/whiptail-how-to-redirect-output-to-environment-variable
    readarray -t contacts < ${CONTACTS_FILE}
    selected_address=$(
        whiptail \
            --title "$TITLE" \
            --menu "Choose a contact to call" 30 50 16 \
            ${contacts[@]} \
            3>&1 1>&2 2>&3
    )
    if (( $? == 0 ))
    then
        # FIXME - global variable hack for contacts subshell
        touch $sender
        nc -N ${selected_address} $PORT_STATUS <<< $ip_addr
        log "sent my address ${ip_addr} to ${selected_address}"
    fi
}

while true
do
    log "displaying contacts"
    contacts &

    # accept/request
    log "waiting request"
    incoming_call=$(nc -l -p $PORT_STATUS)

    log "pending_request: ${incoming_call}"

    # kill contacts subshell
    killall whiptail

    if [ -f $sender ]
    then
        # we're the sender.  send video and give them our address
        log "selected_contact"

        nc -l -p $PORT_VIDEO &
        (mpv /dev/video0 --fps=15 --vo=tct 2>/dev/null| nc $incoming_call $PORT_VIDEO) &

        # nc -N $incoming_call $PORT_STATUS <<< $ip_addr

        # FIXME - max 2 minute call
        sleep 120
        killall nc
        killall mpv

    else
        # we're the receiver
        log "incoming call"
        whiptail --title "$TITLE" --yesno "Incoming call from $incoming_call. Accept?" 8 78
        # FIXME
        if true
        then
            nc -N $incoming_call $PORT_STATUS <<< $ip_addr
            nc -l -p $PORT_VIDEO &
            (mpv /dev/video0 --fps=15 --vo=tct 2>/dev/null | nc $incoming_call $PORT_VIDEO) &

            # FIXME - max 2 minute call
            sleep 120
            killall nc
            killall mpv
        else
            echo foop
        fi

        log "accepted/rejected call"
    fi

done

reset
