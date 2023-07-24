#!/bin/bash

##################################################
############## VARIABLES DEFINITION ##############
##################################################


mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"
wordlists=("rockyou.txt")

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

test_download_location() {
  download_location=$1

  if [[ $download_location =~ ^[a-zA-Z0-9_./-]+$ ]]
  then
    if [ -d "$download_location" ]
    then
      echo "${download_location} found!"
    else
      echo "${download_location} NOT found! Using /tmp..."
      download_location="/tmp"
    fi
  else
      echo "${download_location} is not a valid directory path! Using /tmp..."
      download_location="/tmp"
  fi
}

download_wordlist() {
  wget -P $download_location "${wordlists["${wordlist}"]}"
  if [[ -f "${download_location}/${wordlist}.7z" ]] && [[ $(file "${download_location}/${wordlist}.7z") == *"zip"* ]]
  then
    echo "Unzipping ${download_location}/${wordlist}.7z..."
    7za e "${download_location}/${wordlist}.7z"
  fi

}

ask_for_downloading() {
  read -p "${wordlist} not found, do you want to download it? [y(es)/N(o)/a(ll no)] " download_choice
  # if download required
  if [[ "$download_choice" == "y" ]]
  then
    read -p "Where do you want to install it? [/tmp] " download_location
    # test if suggested location for the installation exists
    test_download_location
    # download wordlist
    download_wordlist
  fi
  # return 2 if 'a' choice
  [[ "$download_choice" == "a" ]] && return 2
}

check_for_wordlist() {
  source wordlists.sh
  for wordlist in ${!wordlists[@]}
  do
    wordlist_location=$(locate $wordlist | head -n 1)
    # test if the wordlist exists
    if [[ $wordlist_location ]]
    then
      echo "${wordlist} found at ${wordlist_location}"
    else
      ask_for_downloading $wordlist
      # break the loop if no wordlist is wanted to be downloaded
      [[ $? == 2 ]] && break
    fi
  done
}

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

        if [ -f "/dico/$wordlist" ]
        then
            hashcat -m $hashes_type $hashes_location /dico/$wordlist -r /dico/rules/$rule 
        else
            hashcat -m $hashes_type $hashes_location concat_all_ntds wordlists/$wordlist -r /dico/rules/$rule 
        fi
    fi
done
