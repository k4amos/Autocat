#!/bin/bash

# Autocat - Automated hashcat workflow manager
# This script automates the process of running hashcat with wordlists and rules

set -euo pipefail

##################################################
############## GLOBAL SETTINGS ###################
##################################################

# Debug mode (set to true for verbose output)
DEBUG_MODE=false

##################################################
############## COLOR DEFINITIONS #################
##################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;93m'
readonly RESET='\033[0m'
readonly LIGHT_MAGENTA="\033[1;95m"
readonly LIGHT_CYAN="\033[1;96m"

##################################################
############## EMOJI DEFINITIONS #################
##################################################

readonly EMOJI_CHECK="\u2714"
readonly EMOJI_CAT="\U1F431"
readonly EMOJI_CROSS="\u274C"

##################################################
############## CONFIGURATION #####################
##################################################

readonly CONFIG_FILE="config.json"
readonly HASHCAT_MASK="?1?2?2?2?2?2?2?3?3?3?3?d?d?d?d"


# Parse configuration
readonly CRACKING_SEQUENCE_PATH=$(jq -r '.paths.cracking_sequence' "$CONFIG_FILE")
readonly HASHCAT_POTFILE_PATH=$(jq -r '.paths.hashcat_potfile' "$CONFIG_FILE" | envsubst)

readonly AUTOCAT_PROCESSED_POTFILE_PATH=$(jq -r '.paths.autocat_processed_potfile' "$CONFIG_FILE")
readonly AUTOCAT_NEW_CRACKED_POTFILE_PATH=$(jq -r '.paths.autocat_new_cracked_potfile' "$CONFIG_FILE")
readonly AUTOCAT_ALL_POTFILE_PATH=$(jq -r '.paths.autocat_all_potfile' "$CONFIG_FILE")

readonly POTFILE_CRACKING_RULE=$(jq -r '.potfile_cracking_rule' "$CONFIG_FILE")


# Create associative arrays for resources
declare -A RESOURCE_PATHS
declare -A RESOURCE_URLS
declare -A RESOURCE_TYPES
declare -A RESOURCE_POST_DOWNLOAD

# Parse resources from config.json
while IFS= read -r resource; do
  name=$(echo "$resource" | jq -r '.name')
  RESOURCE_PATHS["$name"]=$(echo "$resource" | jq -r '.path')
  RESOURCE_URLS["$name"]=$(echo "$resource" | jq -r '.url')
  RESOURCE_TYPES["$name"]=$(echo "$resource" | jq -r '.type')
  RESOURCE_POST_DOWNLOAD["$name"]=$(echo "$resource" | jq -c '.post_download // {}')
done < <(jq -c '.download_resources[]' "$CONFIG_FILE")

# Get additional rule paths
ADDITIONAL_RULES_PATH=($(jq -r '.additional_rules_path[]' "$CONFIG_FILE" 2>/dev/null))

# Get additional wordlist paths
ADDITIONAL_WORDLISTS_PATH=($(jq -r '.additional_wordlists_path[]' "$CONFIG_FILE" 2>/dev/null))

# Script arguments passed to hashcat
readonly SCRIPT_ARGS=("$@")

##################################################
############## HELPER FUNCTIONS ##################
##################################################

# Print debug messages if debug mode is enabled
debug_print() {
  if [ "$DEBUG_MODE" = true ]; then
    printf "${YELLOW}[DEBUG] $1${RESET}\n" >&2
  fi
}

# Validate JSON file
validate_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    printf "${RED}Error: Invalid JSON in $file${RESET}\n" >&2
    return 1
  fi
  return 0
}

##################################################
############## WELCOME MESSAGE ###################
##################################################

printf "${LIGHT_CYAN}Welcome to Autocat${RESET} $EMOJI_CAT\n\n"

##################################################
############## UTILITY FUNCTIONS #################
##################################################

# Find rule file in various locations
# Arguments:
#   $1 - rule filename to search for
# Returns:
#   0 on success (prints path to stdout)
#   1 on failure
find_rule_path() {
  local rule="$1"

  debug_print "Searching for rule: $rule"

  # Check rule resources first
  for name in "${!RESOURCE_PATHS[@]}"; do
    if [ "${RESOURCE_TYPES[$name]}" = "rules" ]; then
      local path="${RESOURCE_PATHS[$name]}/$rule"
      if [ -f "$path" ]; then
        debug_print "Found rule at: $path"
        echo "$path"
        return 0
      fi
    fi
  done

  # Check additional rule paths
  for path in "${ADDITIONAL_RULES_PATH[@]}"; do
    if [ -f "$path/$rule" ]; then
      debug_print "Found rule at: $path/$rule"
      echo "$path/$rule"
      return 0
    fi
  done

  printf "${RED}Rule $rule not found${RESET}\n" >&2
  return 1
}

# Find wordlist file in various locations
# Arguments:
#   $1 - wordlist filename to search for
# Returns:
#   0 on success (prints path to stdout)
#   1 on failure
find_wordlist_path() {
  local wordlist="$1"

  debug_print "Searching for wordlist: $wordlist"

  # Check wordlist resources first
  for name in "${!RESOURCE_PATHS[@]}"; do
    if [ "${RESOURCE_TYPES[$name]}" = "wordlists" ]; then
      local path="${RESOURCE_PATHS[$name]}/$wordlist"
      if [ -f "$path" ]; then
        debug_print "Found wordlist at: $path"
        echo "$path"
        return 0
      fi
    fi
  done

  # Check additional wordlist paths
  for path in "${ADDITIONAL_WORDLISTS_PATH[@]}"; do
    if [ -f "$path/$wordlist" ]; then
      debug_print "Found wordlist at: $path/$wordlist"
      echo "$path/$wordlist"
      return 0
    fi
  done

  printf "${RED}Wordlist $wordlist not found${RESET}\n" >&2
  return 1
}

# Download required resources from configured URLs
# No arguments
# Returns:
#   0 on success
#   1 on failure
download_resources() {
  debug_print "Starting resource download"

  for name in "${!RESOURCE_PATHS[@]}"; do
    local path="${RESOURCE_PATHS[$name]}"
    local url="${RESOURCE_URLS[$name]}"
    local parent_dir=$(dirname "$path")

    # Create parent directory if needed
    if [ ! -e "$parent_dir" ]; then
      sudo mkdir -p "$parent_dir"
      sudo chmod 755 "$parent_dir"
    fi

    # Download resource if not present
    if [ ! -d "$path" ]; then
      printf "${YELLOW}Downloading $name...${RESET}\n"
      sudo git clone "$url" "$path"
      printf "${GREEN}$EMOJI_CHECK $name downloaded${RESET}\n"

      # Handle post-download actions
      local post_download="${RESOURCE_POST_DOWNLOAD[$name]}"
      if [ "$post_download" != "{}" ]; then
        # Extract 7z files if configured
        if [ "$(echo "$post_download" | jq -r '.extract_7z // false')" = "true" ]; then
          local max_depth=$(echo "$post_download" | jq -r '.max_depth // 1')
          find "$path" -maxdepth "$max_depth" -type f -name "*.7z" -exec sudo 7z x {} -o"{%h}" \;
        fi
      fi
    fi
  done
}

# Prompt user for automatic download of missing resources
# No arguments
# Side effects:
#   May call download_resources() and run_hashcat()
ask_for_download() {
  printf "${LIGHT_MAGENTA}Do you want to download the required wordlists and rules automatically?${RESET}\n"
  echo ""

  local options=("Download automatically (recommended)" "Exit")

  select choice in "${options[@]}"; do
    case $REPLY in
      1)
        download_resources
        run_hashcat
        break
        ;;
      2)
        echo "Exiting..."
        exit 0
        ;;
      *)
        printf "${RED}Invalid option. Please select 1 or 2.${RESET}\n"
        ;;
    esac
  done
}

##################################################
############## RESOURCE CHECKING #################
##################################################

# Check if all required resources are present
# No arguments
# Side effects:
#   May call ask_for_download() if resources are missing
check_resources() {
  debug_print "Checking for required resources"
  local missing_resources=false

  # Check for required directories from resources config
  for name in "${!RESOURCE_PATHS[@]}"; do
    local path="${RESOURCE_PATHS[$name]}"
    if [ ! -d "$path" ]; then
      printf "${RED}$EMOJI_CROSS $name not found${RESET}\n"
      missing_resources=true
    fi
  done

  # If any core resources are missing, prompt for download
  if [ "$missing_resources" = true ]; then
    ask_for_download
    return
  fi

  # Check for specific files mentioned in cracking sequence
  local need_download=false

  if [ -f "$CRACKING_SEQUENCE_PATH" ]; then
    readarray -t lines < "$CRACKING_SEQUENCE_PATH"

    for line in "${lines[@]}"; do
      # Skip brute-force and potfile lines
      if [[ $line == *"brute-force"* ]] || [[ $line == *"potfile"* ]]; then
        continue
      fi

      local wordlist=$(echo "$line" | cut -d " " -f 1)
      local rule=$(echo "$line" | cut -d " " -f 2)

      # Check if wordlist exists using find_wordlist_path
      if ! find_wordlist_path "$wordlist" >/dev/null 2>&1; then
        need_download=true
        break
      fi

      # Check if rule exists in any location
      if ! find_rule_path "$rule" >/dev/null 2>&1; then
        printf "${RED}$EMOJI_CROSS Rule $rule not found${RESET}\n"
        need_download=true
        break
      fi
    done

    if [ "$need_download" = true ]; then
      ask_for_download
    fi
  fi
}

##################################################
############## MAIN HASHCAT FUNCTION #############
##################################################

# Main function to run hashcat with configured sequence
# No arguments (uses global SCRIPT_ARGS)
# Returns:
#   0 on success
#   Exit codes from hashcat on failure
run_hashcat() {
  debug_print "Starting hashcat sequence"

  # Create the empty processed potfile tracker
  : > "$AUTOCAT_PROCESSED_POTFILE_PATH"

  # Read cracking sequence
  readarray -t lines < "$CRACKING_SEQUENCE_PATH"

  for line in "${lines[@]}"; do
    # Skip empty lines
    [ -z "$line" ] && continue

    if [[ $line == *"brute-force"* ]]; then
      # Handle brute-force attacks
      local nb_digits=$(echo "$line" | grep -oE '(0|1?[0-9]|20)')
      local mask="${HASHCAT_MASK:0:($nb_digits)*2}"

      printf "${LIGHT_MAGENTA}Running brute-force attack (${nb_digits} characters)${RESET}\n"
      printf "${YELLOW}hashcat $SCRIPT_ARGS -a 3 -1 ?l?d?u -2 ?l?d -3 tool/3_default.hcchr $mask -O -w 3${RESET}\n"
      hashcat "${filtered_args[@]}" -a 3 -1 ?l?d?u -2 ?l?d -3 tool/3_default.hcchr $mask -O -w 3

    else
      # Handle wordlist + rule attacks
      local wordlist=$(echo "$line" | cut -d " " -f 1)
      local rule=$(echo "$line" | cut -d " " -f 2)
      local rule_path=$(find_rule_path "$rule")

      # Find wordlist using find_wordlist_path
      local wordlist_path=$(find_wordlist_path "$wordlist" 2>/dev/null)
      if [ -z "$wordlist_path" ]; then
        printf "${RED}Error: Wordlist $wordlist not found${RESET}\n"
        continue
      fi

      printf "${LIGHT_MAGENTA}Running attack with wordlist: $wordlist, rule: $rule${RESET}\n"
      printf "${YELLOW}hashcat $SCRIPT_ARGS $wordlist_path -r $rule_path -O -w 3${RESET}\n"
      hashcat "${filtered_args[@]}" "$wordlist_path" -r "$rule_path" -O -w 3

    fi

    if ! "$disable_potfile"; then
      # === Potfile cracking step if there are new passwords ===
      # Extract all cracked passwords from the potfile
      cat "$HASHCAT_POTFILE_PATH" | rev | cut -d':' -f1 | rev | sort -u > "$AUTOCAT_ALL_POTFILE_PATH"
      # Compare with already processed passwords
      comm -23 "$AUTOCAT_ALL_POTFILE_PATH" <(sort -u "$AUTOCAT_PROCESSED_POTFILE_PATH") > "$AUTOCAT_NEW_CRACKED_POTFILE_PATH"

      if [ -s "$AUTOCAT_NEW_CRACKED_POTFILE_PATH" ]; then
        # Find rule for potfile cracking
        local potfile_rule_path=$(find_rule_path "$POTFILE_CRACKING_RULE" 2>/dev/null)
        if [ -z "$potfile_rule_path" ]; then
          printf "${RED}Error: Potfile rule $POTFILE_CRACKING_RULE not found${RESET}\n"
          continue
        fi

        printf "${LIGHT_MAGENTA}Running potfile attack with rule: $POTFILE_CRACKING_RULE (only new cracked passwords)${RESET}\n"
        printf "${YELLOW}hashcat $SCRIPT_ARGS $AUTOCAT_NEW_CRACKED_POTFILE_PATH -r $potfile_rule_path -O -w 3${RESET}\n"
        hashcat "${filtered_args[@]}" $AUTOCAT_NEW_CRACKED_POTFILE_PATH -r "$potfile_rule_path" -O -w 3

        # Update processed potfile list
        sort -u "$AUTOCAT_NEW_CRACKED_POTFILE_PATH"> "$AUTOCAT_PROCESSED_POTFILE_PATH"
      else
        printf "${LIGHT_MAGENTA}No new passwords to process for potfile attack, skipping.${RESET}\n"
      fi

      # Clean temporary files
      rm -f "$AUTOCAT_NEW_CRACKED_POTFILE_PATH" "$AUTOCAT_ALL_POTFILE_PATH"

    else
      debug_print "Potfile cracking disabled"
    fi

  done
}

##################################################
############## MAIN EXECUTION ####################
##################################################

# Check for required dependencies
if ! command -v jq &> /dev/null; then
  printf "${RED}Error: jq is not installed. Please install it first.${RESET}\n"
  exit 1
fi

if ! command -v hashcat &> /dev/null; then
  printf "${RED}Error: hashcat is not installed. Please install it first.${RESET}\n"
  exit 1
fi

# Check and validate configuration file
if [ ! -f "$CONFIG_FILE" ]; then
  printf "${RED}Error: Configuration file $CONFIG_FILE not found${RESET}\n"
  exit 1
fi

if ! validate_json "$CONFIG_FILE"; then
  exit 1
fi

# Check cracking sequence file exists
if [ ! -f "$CRACKING_SEQUENCE_PATH" ]; then
  printf "${RED}Error: Cracking sequence file $CRACKING_SEQUENCE_PATH not found${RESET}\n"
  exit 1
fi

# Parse command line arguments
# Initialize flags
show_help=false
disable_potfile=false
filtered_args=()

for arg in "${SCRIPT_ARGS[@]}"; do
    case "$arg" in
        -h|--help)
            show_help=true
            ;;
        --disable_potfile)
            disable_potfile=true
            ;;
        --debug)
            DEBUG_MODE=true
            debug_print "Debug mode enabled"
            ;;
        *)
            filtered_args+=("$arg")  # garde les autres
            ;;
    esac
done

if $show_help; then
    printf "${YELLOW}Autocat Help :${RESET}\n"
    echo "Usage: $0 [same options as Hashcat]"
    echo "  -h, --help           Show help"
    echo "  --disable_potfile    Disable potfile cracking"
    echo "  --debug              Enable debug output\n"
    printf "${YELLOW}\nHashcat Help :${RESET}\n"
    hashcat -h
    exit 0
fi

if $disable_potfile; then
    debug_print "Potfile disabled"
fi

# Main execution
main() {
  check_resources
  run_hashcat
}

main