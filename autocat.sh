#!/bin/bash

##################################################
############## VARIABLES DEFINITION ##############
##################################################


methods_list=("fr-top20000 OneRuleToRuleThemAll.rule.log" "fr-top1000000 OneRuleToRuleThemAll.rule.log" "fr-top20000 rules.smart.log" "twitter clem9669_medium.rule.log" "fr-top1000000 rules.smart.log" "entreprise_fr OneRuleToRuleThemAll.rule.log" "pseudo OneRuleToRuleThemAll.rule.log" "fr-top1000000 rules.medium.log" "various_leak1 OneRuleToRuleThemAll.rule.log" "various_leak3 OneRuleToRuleThemAll.rule.log" "various_leak4 OneRuleToRuleThemAll.rule.log" "entreprise_fr rules.smart.log" "various_leak2 OneRuleToRuleThemAll.rule.log" "dictionnaire_fr rules.smart.log" "lastfm clem9669_medium.rule.log" "fr-top20000 clem9669_large.rule.log" "various_leak5 OneRuleToRuleThemAll.rule.log" "prenoms_fr rules.smart.log" "various_leak7 OneRuleToRuleThemAll.rule.log" "dictionnaire_en clem9669_large.rule.log" "entreprise_fr clem9669_medium.rule.log" "wikipedia_fr clem9669_medium.rule.log" "top_prenoms_combo OneRuleToRuleThemAll.rule.log" "breachcompilation.sorted clem9669_small.rule.log" "geo_wordlist_france rules.medium.log" "pseudo rules.smart.log" "wikifr clem9669_small.rule.log" "instagram rules.smart.log" "various_leak8 rules.medium.log" "sciences clem9669_large.rule.log" "brute_force_8.log" "villes_fr clem9669_large.rule.log" "keyboard_walk_fr OneRuleToRuleThemAll.rule.log" "various_leak1 rules.medium.log" "various_leak4 rules.smart.log" "domain_tld_FR OneRuleToRuleThemAll.rule.log" "news clem9669_large.rule.log" "compilation_prenoms clem9669_small.rule.log" "crackstation-human-only.txt OneRuleToRuleThemAll.rule.log" "fr-top1000000 clem9669_medium.rule.log" "expression clem9669_large.rule.log" "various_leak7 rules.smart.log" "wifi-ssid rules.medium.log" "various_leak5 rules.smart.log" "various_leak3 rules.smart.log" "pseudo rules.medium.log" "FB_FirstLast OneRuleToRuleThemAll.rule.log" "breachcompilation.sorted OneRuleToRuleThemAll.rule.log" "entreprise_fr clem9669_large.rule.log" "various_leak1 clem9669_medium.rule.log" "wikipedia_fr rules.smart.log" "date_ddmmyy_dot rules.medium.log" "various_leak7 rules.medium.log" "top_prenoms_combo rules.smart.log" "various_leak4 rules.medium.log" "various_leak5 clem9669_medium.rule.log" "twitter rules.medium.log" "various_leak2 rules.smart.log" "various_leak6 rules.small.log" "pseudo clem9669_medium.rule.log" "music rules.small.log" "keyboard_walk_us rules.small.log" "keyboard_walk_fr rules.smart.log" "dictionnaire_de rules.medium.log" "date_ddmmyyyy_slash rules.small.log" "date_ddmmyyyy_dot OneRuleToRuleThemAll.rule.log" "date_ddmmyy_dot clem9669_medium.rule.log" "adresses_fr clem9669_medium.rule.log" "wifi-ssid clem9669_large.rule.log" "various_leak3 clem9669_medium.rule.log" "various_leak5 rules.medium.log" "various_leak4 clem9669_medium.rule.log" "lastfm clem9669_large.rule.log" "various_leak2 rules.medium.log" "machine_names clem9669_large.rule.log" "wikifr OneRuleToRuleThemAll.rule.log" "noms_famille_fr rules.medium.log" "news rules.medium.log" "brands rules.smart.log" "various_leak2 clem9669_medium.rule.log" "wikipedia_fr clem9669_large.rule.log")
mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"
wordlists=("rockyou.txt")

unset -v hashes_type
unset -v hashes_location

###################################
############## USAGE ##############
###################################

usage() {
  printf "Usage: ./autocat.sh -m <hashes_type> -l <hashes_location>"
}

while getopts 'hm:l:' flag; do
  case "${flag}" in
    m) hashes_type=${OPTARG} ;;
    l) hashes_location=${OPTARG} ;;
    h) usage
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

for i in "${methods_list[@]}"
do
    if [[ $i == *"brute_force"* ]] 
    then
        #echo "brute force" 
        nb_digits=$(echo "$i" | grep -o '[0-9]')
        mask="${mask_total:0:($nb_digits)*2}"
        #echo "$mask"

        #echo "$nb_digits"
        timeout --foreground 3600 hashcat -m $hashes_type -a 3 -1 ?l?d?u -2 ?l?d -3 $mask 3_default.hcchr $hashes_location 
    else
        wordlist=$(echo "$i" | cut -d " " -f 1)
        rule_temp=$(echo "$i" | cut -d " " -f 2)
        rule="${rule_temp::-4}" # changer ça # il faudrait enlever tous les .log de methods_list

        if [ -f "/dico/$wordlist" ]
        then
            timeout --foreground 3600 hashcat -m $hashes_type $hashes_location /dico/$wordlist -r /dico/rules/$rule
        else
            timeout --foreground 3600 hashcat -m $hashes_type $hashes_location concat_all_ntds wordlists/$wordlist -r /dico/rules/$rule 
        fi
    fi
done
