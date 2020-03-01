#!/bin/bash

readarray -t names < <(awk -F "," '{print $1}' contacts.txt)
readarray -t ips < <(awk -F "," '{print $2}' contacts.txt)

l=()

for ((i=0;i<${#names[@]};++i)); do
	l+=("${ips[i]}" "${names[i]}")
done

ip_to_call=$(whiptail --notags --title "Shkype" --menu "Choose a contact" 16 78 10 "${l[@]}" 3>&1 1>&2 2>&3)

echo $ip_to_call
