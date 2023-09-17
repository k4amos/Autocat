#!/bin/bash

#set -e


##################################################
############## VARIABLES DEFINITION ##############
##################################################


mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"
wordlists=("rockyou.txt")

config_file="config.json"
cracking_sequence_path=$(jq -r '.cracking_sequence_path' "$config_file")
wordlists_path=$(jq -r '.wordlists_path' "$config_file")
rules_path=$(jq -r '.rules_path' "$config_file")


cracking_sequence="cracking_sequence.txt"

# unset -v hashes_type
# unset -v hashes_location
# unset -v cracking_sequence

###################################
############## INFO ###############
###################################

info(){
  printf "Welcome to Autocat!\n"
}

# usage() {
#   printf "Usage: ./autocat.sh hashcat_arguments..."
# }

# while getopts 'h:m:l:f:w:' flag; do
#   case "${flag}" in
#     m) hashes_type=${OPTARG} ;;
#     l) hashes_location=${OPTARG} ;;
#     f) cracking_sequence=${OPTARG} ;;
#     w) wordlists_path=${OPTARG} ;;
#     h) info
#        usage
#        exit 1 ;;
#     # *) usage
#     #    exit 1 ;;
#   esac
# done

# if [ -z "$hashes_type" ] || [ -z "$hashes_location" ]; then
#         echo 'Incorrect arguments were passed.' >&2
#         usage
#         exit 1
# fi

# if [ -d "$wordlists_path" ]; then
#   echo 'Default location for the wordlists in /usr/share/wordlists/autocat' >&2
#   wordlists_path="/usr/share/wordlists/autocat"

#   if [ ! -d "/usr/share/wordlists" ]; then 
#     sudo mkdir "/usr/share/wordlists"
#     sudo chmod 777 "/urs/share/wordlists"
#   fi

# fi

wordlists_path=$(echo "$wordlists_path" | sed 's/\/$//') # remove potential "/" at the end


####################################
############## SCRIPT ##############
####################################

# test_download_location() {
#   download_location=$1

#   if [[ $download_location =~ ^[a-zA-Z0-9_./-]+$ ]]
#   then
#     if [ -d "$download_location" ]
#     then
#       echo "${download_location} found!"
#     else
#       echo "${download_location} NOT found! Using /tmp..."
#       download_location="/tmp"
#     fi
#   else
#       echo "${download_location} is not a valid directory path! Using /tmp..."
#       download_location="/tmp"
#   fi
# }

# download_wordlist() {
#   wget -P $download_location "${wordlists["${wordlist}"]}"
#   if [[ -f "${download_location}/${wordlist}.7z" ]] && [[ $(file "${download_location}/${wordlist}.7z") == *"zip"* ]]
#   then
#     echo "Unzipping ${download_location}/${wordlist}.7z..."
#     7za e "${download_location}/${wordlist}.7z"
#   fi
# }

# ask_for_downloading() {
#   read -p "required wordlists not found, do you want to download it? [yes/no] " download_choice
#   # if download required
#   if [[ "$download_choice" == "y" ] || [ "$download_choice" == "yes" ] || [ "$download_choice" == "Y" ] || [ "$download_choice" == "Yes" ]]
#   then
#     if [$wordlists_path != "/usr/share/wordlists/clem9669_wordists" ]; then
#       read -p "clem9669_wordlists not found, do you want to download it? [yes/no] "
#     fi
#     read -p "Where do you want to install it? [/tmp] " download_location
#     # test if suggested location for the installation exists
#     test_download_location
#     # download wordlist
#     download_wordlist
#   fi
#   # return 2 if 'a' choice
#   [[ "$download_choice" == "a" ]] && return 2
# }

download() {
  
  echo "121"
  echo "122 $wordlists_path"
  #sudo chmod 777 $wordlists_path
  if [ ! -d "$wordlists_path" ]; then
    echo "Downloading wordlists from Clem9669..."
    git clone https://github.com/clem9669/wordlists.git $wordlists_path
  fi
  


  # if [ ! -e "$wordlists_path/wordlists" ]; then
  #   mkdir "$wordlists_path/wordlists" 
  # fi
  # if [ ! -e "$wordlists_path/rules" ]; then
  #   mkdir "$wordlists_path/rules" 
  # fi

  for file in $wordlist_location/*.7z; do
    7z x "$file" 2>/dev/null #-o $wordlist_location/wordlists
  done
  rm $wordlist_location/*.7z

  # for file in wordlists/*.7z; do
  #   7z x "$file" #-o wordlists
  # done
  # rm wordlists/*.7z

  echo "Downloading rules from Clem9669..."
  if [ ! -d "$rules_path" ]; then
    echo "Downloading wordlists from Clem9669..."
    sudo git clone https://github.com/clem9669/hashcat-rule.git $rules_path
  fi
  #mv $wordlists_path/hashcat-rule $wordlists_path/rules
}

ask_for_downloading() {
    # echo "Do you want to download the required wordlists+rules manually or automatically"
    # echo "1. automatically (recommended)"
    # echo "2. manually = Quit"
    # read -p ">" download_method
    # if ["$download_method" = "2"];then
    #   echo "bye"
    #   exit 1
    # else
    #   mkdir $(dirname "$wordlists_path") 2>/dev/null
    #   mkdir "$wordlists_path" 2>/dev/null
    #   mkdir "$wordlists_path/wordlists" 2>/dev/null
    #   mkdir "$wordlists_path/rules" 2>/dev/null
    #   download
    # fi
    echo "Do you want to download the required wordlists+rules manually or automatically"
    echo ""
    options=("Automatically (recommended)" "Manually = Quit")

    select choice in "${options[@]}"; do
        case $REPLY in
            1)
                echo "automatic download..."

                if [ ! -e "$(dirname "$wordlists_path")" ]; then
                  mkdir $(dirname "$wordlists_path") 
                  chmod 777 $(dirname "$wordlists_path") 
                fi
                # if [ ! -e "$wordlists_path" ]; then
                #   mkdir "$wordlists_path" 
                # fi
                download
                ;;
            2)
                echo "bye :)"
                exit 1
                ;;
            *)
                echo "Invalid choice, please select 1 or 2."
                ;;
        esac
    done
}

check_for_wordlist() {

  if [ ! -d "$wordlists_path" ]; then
    echo "Clem9669 wordlists not present..."
    ask_for_downloading

  fi

  if [ ! -d "$rules_path" ]; then
    echo "Clem9669 rules not present..."
    ask_for_downloading
  fi

  if boolean_ask_for_downloading=false; then
    #cat $cracking_sequence | while read line || [ -n "$line" ]; do
    readarray -t lines < $cracking_sequence

    for line in "${lines[@]}"; do

      echo "$boolean_ask_for_downloading"

      if [[ ! $line = *"brute-force"* ]]; then

    
        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        if [  ! -f "$wordlists_path/$wordlist" ] || [  ! -f "$rules_path/$rule" ]; then
          echo "$line not found"
          boolean_ask_for_downloading=true
          echo "$boolean_ask_for_downloading"
          break
        fi
      fi
    done

    echo "$boolean_ask_for_downloading"
    if $boolean_ask_for_downloading; then
      ask_for_downloading
    fi
  fi
}
#source wordlists.sh

# for wordlist in ${!wordlists[@]}
# do
#   wordlist_location=$(locate $wordlist | head -n 1)
#   # test if the wordlist exists
#   if [[ $wordlist_location ]]
#   then
#     echo "${wordlist} found at ${wordlist_location}"
#   else
#     ask_for_downloading $wordlist
#     # break the loop if no wordlist is wanted to be downloaded
#     [[ $? == 2 ]] && break
#   fi
# done

check_for_wordlist

cat $cracking_sequence | while read line || [ -n "$line" ]
do  

    echo $line
    if [[ $line == *"brute-force"* ]] 
    then
        #echo "brute force" 
        nb_digits=$(echo "$line" | grep -o '[0-9]')
        mask="${mask_total:0:($nb_digits)*2}"
        #echo "$mask"

        #echo "$nb_digits"
        timeout --foreground 3600 hashcat "$@" -a 3 -1 ?l?d?u -2 ?l?d -3 3_default.hcchr $mask -O -w 3 
    else

        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        timeout --foreground 3600 hashcat "$@" /dico/$wordlist -r /dico/rules/$rule -O -w 3
        
    fi
done
