#!/bin/bash
##################################################
############## VARIABLES DEFINITION ##############
##################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'
LIGHT_MAGENTA="\033[1;95m"
LIGHT_CYAN="\033[1;96m"


emoji_check="\u2714"
emoji_cat="\U1F431"
emoji_cross="\u274C"

printf "${LIGHT_CYAN}Welcome to Autocat${RESET} $emoji_cat\n"

mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"

config_file="config.json"

cracking_sequence_path=$(jq -r '.cracking_sequence_path' "$config_file")

clem9669_wordlists_path=$(jq -r '.clem9669_wordlists_path' "$config_file")
clem9669_rules_path=$(jq -r '.clem9669_rules_path' "$config_file")
Hob0Rules_path=$(jq -r '.Hob0Rules_path' "$config_file")
OneRuleToRuleThemAll_rules_path=$(jq -r '.OneRuleToRuleThemAll_rules_path' "$config_file") #OneRuleToRuleThemAll

cracking_sequence="cracking_sequence.txt"

script_args="$@"


find_path() {
  local rule="$1"  # Premier argument
  
  if [ -f "$clem9669_rules_path/$rule" ]; then
    echo "$clem9669_rules_path/$rule"
  elif [ -f "$Hob0Rules_path/$rule" ]; then
    echo "$Hob0Rules_path/$rule"
  elif [ -f "$OneRuleToRuleThemAll_rules_path/$rule" ]; then
    echo "$OneRuleToRuleThemAll_rules_path/$rule"
  elif [ -f "/usr/share/hashcat/rules/$rule" ]; then
    echo "/usr/share/hashcat/rules/$rule"
  else 
    printf "${RED}$rule still missing :(...${RESET}\n"
    exit 1
  fi
}

run_hashcat() {

    potfile_number=1;

    readarray -t lines < $cracking_sequence

    for line in "${lines[@]}"; do

      if [[ $line == *"brute-force"* ]]; then
        nb_digits=$(echo "$line" | grep -oE '(0|1?[0-9]|20)')
        
        mask="${mask_total:0:($nb_digits)*2}"
        
        printf "${LIGHT_MAGENTA}hashcat $script_args -a 3 -1 ?l?d?u -2 ?l?d -3 tool/3_default.hcchr $mask -O -w 3 ${RESET}\n"
        hashcat $script_args -a 3 -1 ?l?d?u -2 ?l?d -3 tool/3_default.hcchr $mask -O -w 3 #--status --status-timer 1 --machine-readable | tee "report_autocat/brute-force $nb_digits"
      
      elif [[ $line == *"potfile"* ]]; then

        rule=$(echo "$line" | cut -d " " -f 2)
        rule_path=$(find_path $rule)
        
        cat ~/.local/share/hashcat/hashcat.potfile | rev | cut -d':' -f1 | rev > ~/autocat_potfile
        rule=$(echo "$line" | cut -d " " -f 2)

        printf "${LIGHT_MAGENTA}hashcat $script_args ~/autocat_potfile -r $rule_path -O -w 3${RESET}\n"
        hashcat $script_args ~/autocat_potfile -r $rule_path -O -w 3 #--status --status-timer 1 --machine-readable | tee "report_autocat/potfile$potfile_number $rule"
        potfile_number=$((potfile_number+1))
        rm ~/autocat_potfile
      
      else

        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        rule_path=$(find_path $rule)

        printf "${LIGHT_MAGENTA}hashcat $script_args $clem9669_wordlists_path/$wordlist -r $rule_path -O -w 3${RESET}\n"
        hashcat $script_args $clem9669_wordlists_path/$wordlist -r $rule_path -O -w 3 #--status --status-timer 1 --machine-readable | tee "report_autocat/$wordlist $rule"
      
      fi
    done
}

download() {
  
  if [ ! -d "$clem9669_wordlists_path" ]; then
    printf "${YELLOW}Downloading wordlists from Clem9669...${RESET}\n"
    sudo git clone https://github.com/clem9669/wordlists.git $clem9669_wordlists_path
    printf "${GREEN}$emoji_check Download wordlists from Clem9669${RESET}\n"
    for file in $clem9669_wordlists_path/*.7z; do
      sudo 7z x "$file" -o$clem9669_wordlists_path
    done
  fi
  
  
  if [ ! -d "$clem9669_rules_path" ]; then
    printf "${YELLOW}Downloading rules from Clem9669...${RESET}\n"
    sudo git clone https://github.com/clem9669/hashcat-rule.git $clem9669_rules_path
    printf "${GREEN}$emoji_check Download rules from Clem9669${RESET}\n"
  fi

  if [ ! -d "$Hob0Rules_path" ]; then
    printf "${YELLOW}Downloading Hob0Rules rules...${RESET}\n"
    sudo git clone https://github.com/praetorian-inc/Hob0Rules.git $Hob0Rules_path
    printf "${GREEN}$emoji_check Download Hob0Rules rules${RESET}\n"
  fi

  if [ ! -d "$OneRuleToRuleThemAll_rules_path" ]; then
    printf "${YELLOW}Downloading OneRuleToRuleThemAll rules...${RESET}\n"
    sudo git clone https://github.com/NotSoSecure/password_cracking_rules.git $OneRuleToRuleThemAll_rules_path
    printf "${GREEN}$emoji_check Download OneRuleToRuleThemAll rules${RESET}\n"
  fi
}


ask_for_downloading() {
    printf "${LIGHT_MAGENTA}Do you want to download the required wordlists+rules manually or automatically?${RESET}\n"
    echo ""
    options=("Automatically (recommended)" "Manually = Quit")

    select choice in "${options[@]}"; do
        case $REPLY in
            1)
                if [ ! -e "$(dirname "$clem9669_wordlists_path")" ]; then
                  mkdir $(dirname "$clem9669_wordlists_path") 
                  chmod 777 $(dirname "$clem9669_wordlists_path") 
                fi
                download
                run_hashcat
                ;;
            2)
                echo "bye :)"
                exit 1
                ;;
            *)  
                printf "${RED}Invalid choice, please select 1 or 2.${RESET}\n"
                ;;
        esac
    done
}

check_for_wordlist() {

  if [ ! -d "$clem9669_wordlists_path" ]; then
    printf "${RED}$emoji_cross Clem9669 wordlists not present${RESET}\n"
    ask_for_downloading

  fi

  if [ ! -d "$clem9669_rules_path" ]; then
    printf "${RED}$emoji_cross Clem9669 rules not present${RESET}\n"
    ask_for_downloading
  fi

  if [ ! -d "$Hob0Rules_path" ]; then
    printf "${RED}$emoji_cross Hob0Rules rules not present${RESET}\n"
    ask_for_downloading
  fi

  if [ ! -d "$OneRuleToRuleThemAll_rules_path" ]; then
    printf "${RED}$emoji_cross OneRuleToRuleThemAll rules not present${RESET}\n"
    ask_for_downloading
  fi

  if boolean_ask_for_downloading=false; then
    #cat $cracking_sequence | while read line || [ -n "$line" ]; do
    readarray -t lines < $cracking_sequence

    for line in "${lines[@]}"; do

      if [[ $line != *"brute-force"* && $line != *"potfile"* ]]; then

        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        if [ ! -f "$clem9669_wordlists_path/$wordlist" ] || ([ ! -f "$clem9669_rules_path/$rule" ] && [ ! -f "/usr/share/hashcat/rules/$rule" ] && [ ! -f "$Hob0Rules_path/$rule" ] && [ ! -f "$OneRuleToRuleThemAll_rules_path/$rule" ]); then
          printf "${RED}$emoji_cross $line not found${RESET}\n"
          boolean_ask_for_downloading=true
          break
        fi
      fi
    done

    if $boolean_ask_for_downloading; then
      ask_for_downloading
    fi
  fi
}

check_for_wordlist
run_hashcat





