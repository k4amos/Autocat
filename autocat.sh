#!/bin/bash

##################################################
############## VARIABLES DEFINITION ##############
##################################################


mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"

unset -v hashes_type
unset -v hashes_location
unset -v methods_list

###################################
############## INFO ###############
###################################

info(){
  printf "Welcome to Autocat!\n"
}

usage() {
  printf "Usage: ./autocat.sh -m <hashes_type> -l <hashes_location> -f <methods_list>"
}

while getopts 'hm:l:f:' flag; do
  case "${flag}" in
    m) hashes_type=${OPTARG} ;;
    l) hashes_location=${OPTARG} ;;
    f) methods_list=${OPTARG} ;;
    h) info
       usage
       exit 1 ;;
    *) usage
       exit 1 ;;
  esac
done

if [ -z "$hashes_type" ] || [ -z "$hashes_location" ]; then
        echo 'Incorrect arguments were passed.' >&2
        usage
        exit 1
fi

####################################
############## SCRIPT ##############
####################################

cat $methods_list | while read line
do
    if [[ $line == *"brute_force"* ]] 
    then
        #echo "brute force" 
        nb_digits=$(echo "$line" | grep -o '[0-9]')
        mask="${mask_total:0:($nb_digits)*2}"
        #echo "$mask"

        #echo "$nb_digits"
        hashcat -m $hashes_type -a 3 -1 ?l?d?u -2 ?l?d -3 $mask 3_default.hcchr $hashes_location 
    else
        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        if [ -f "/dico/$wordlist"]
        then
            hashcat -m $hashes_type $hashes_location /dico/$wordlist -r /dico/rules/$rule 
        else
            hashcat -m $hashes_type $hashes_location concat_all_ntds wordlists/$wordlist -r /dico/rules/$rule 
        fi
    fi
done
