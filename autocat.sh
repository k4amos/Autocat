#!/bin/bash

#set -e


##################################################
############## VARIABLES DEFINITION ##############
##################################################


mask_total="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"

wordlists=("rockyou.txt")

config_file="config.json"

cracking_sequence_path=$(jq -r '.cracking_sequence_path' "$config_file")

clem9669_wordlists_path=$(jq -r '.clem9669_wordlists_path' "$config_file")
clem9669_rules_path=$(jq -r '.clem9669_rules_path' "$config_file")
Hob0Rules_path=$(jq -r '.Hob0Rules_path' "$config_file")
OneRuleToRuleThemAll_rules_path=$(jq -r '.OneRuleToRuleThemAll_rules_path' "$config_file") #OneRuleToRuleThemAll

cracking_sequence="cracking_sequence.txt"

script_args="$@"

run_hashcat() {

  echo $script_args
  regex="/[[:alnum:]_/.-]+" # test if a path is in argument or not
  if [[ "$script_args" =~ $regex ]]; then

    # cat $cracking_sequence | while read line || [ -n "$line" ]; do 
    #   echo $line
    # done


    readarray -t lines < $cracking_sequence

    for line in "${lines[@]}"; do

    #cat $cracking_sequence | while read line || [ -n "$line" ]; do 

      echo "$line llllll"
      if [[ $line == *"brute-force"* ]]; then
        nb_digits=$(echo "$line" | grep -oE '(0|1?[0-9]|20)')
        echo "$mask_total $nb_digits"
        echo "${mask_total:0:($nb_digits)*2}"
        mask="${mask_total:0:($nb_digits)*2}"
        

        #timeout --foreground 3600 hashcat $script_args -a 3 -1 ?l?d?u -2 ?l?d -3 3_default.hcchr $mask -O -w 3 
      else

        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        if [ -f "$clem9669_rules_path/$rule" ]; then
          rule_path=$clem9669_rules_path/$rule
        elif [ -f "$Hob0Rules_path/$rule" ]; then
          rule_path=$Hob0Rules_path/$rule
        elif [ -f "$OneRuleToRuleThemAll_rules_path/$rule" ]; then
          rule_path=$OneRuleToRuleThemAll_rules_path/$rule
        elif [ -f "/usr/share/hashcat/rules/$rule" ]; then
          rule_path="/usr/share/hashcat/rules/$rule"
        else 
          echo "$rule still missing :(..."
          exit 1
        fi
        echo $line
        #hashcat -h
        #timeout --foreground 3 hashcat -m 1000 ../ntds_test /usr/share/wordlists/wordlists/actors -0
        timeout --foreground 3600 hashcat $script_args $clem9669_wordlists_path/$wordlist -r $rule_path -O -w 3 
      
      fi
    done

  else
    hashcat  $script_args
  fi
}

download() {
  
  if [ ! -d "$clem9669_wordlists_path" ]; then
    echo "Downloading wordlists from Clem9669..."
    sudo git clone https://github.com/clem9669/wordlists.git $clem9669_wordlists_path

    for file in $clem9669_wordlists_path/*.7z; do
      echo "sudo 7z x "$clem9669_wordlists_path/$file" 2>/dev/null #-o $wordlist_location/wordlists"
      sudo 7z x "$file" 2>/dev/null #-o $wordlist_location/wordlists
    done

  fi
  
  
  if [ ! -d "$clem9669_rules_path" ]; then
    echo "Downloading rules from Clem9669..."
    sudo git clone https://github.com/clem9669/hashcat-rule.git $clem9669_rules_path
  fi

  if [ ! -d "$Hob0Rules_path" ]; then
    echo "Downloading Hob0Rules..."
    sudo git clone https://github.com/praetorian-inc/Hob0Rules.git $Hob0Rules_path
  fi

  if [ ! -d "$OneRuleToRuleThemAll_rules_path" ]; then
    echo "Downloading OneRuleToRuleThemAll..."
    sudo git clone https://github.com/NotSoSecure/password_cracking_rules.git $OneRuleToRuleThemAll_rules_path
  fi


}

ask_for_downloading() {

    echo "Do you want to download the required wordlists+rules manually or automatically"
    echo ""
    options=("Automatically (recommended)" "Manually = Quit")

    select choice in "${options[@]}"; do
        case $REPLY in
            1)
                echo "automatic download..."

                if [ ! -e "$(dirname "$clem9669_wordlists_path")" ]; then
                  mkdir $(dirname "$clem9669_wordlists_path") 
                  chmod 777 $(dirname "$clem9669_wordlists_path") 
                fi
                # if [ ! -e "$clem9669_wordlists_path" ]; then
                #   mkdir "$clem9669_wordlists_path" 
                # fi
                download
                run_hashcat
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

  if [ ! -d "$clem9669_wordlists_path" ]; then
    echo "Clem9669 wordlists not present..."
    ask_for_downloading

  fi

  if [ ! -d "$clem9669_rules_path" ]; then
    echo "Clem9669 rules not present..."
    ask_for_downloading
  fi

  if [ ! -d "$Hob0Rules_path" ]; then
    echo "Hob0Rules rules not present..."
    ask_for_downloading
  fi

  if [ ! -d "$OneRuleToRuleThemAll_rules_path" ]; then
    echo "OneRuleToRuleThemAll rules not present..."
    ask_for_downloading
  fi

  if boolean_ask_for_downloading=false; then
    #cat $cracking_sequence | while read line || [ -n "$line" ]; do
    readarray -t lines < $cracking_sequence

    for line in "${lines[@]}"; do

      if [[ ! $line = *"brute-force"* ]]; then

        wordlist=$(echo "$line" | cut -d " " -f 1)
        rule=$(echo "$line" | cut -d " " -f 2)

        if [ ! -f "$clem9669_wordlists_path/$wordlist" ] || ([ ! -f "$clem9669_rules_path/$rule" ] && [ ! -f "/usr/share/hashcat/rules/$rule" ] && [ ! -f "$Hob0Rules_path/$rule" ] && [ ! -f "$OneRuleToRuleThemAll_rules_path/$rule" ]); then
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

check_for_wordlist
run_hashcat





