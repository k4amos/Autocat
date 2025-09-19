# Autocat - Intelligent Hashcat Automation Tool

<p align="center">
    <img src="tool/img/logo.png" style="height:350px">
</p>

## Overview

Autocat is an intelligent wrapper for Hashcat that automates password cracking using optimized attack sequences for french🇫🇷 passwords. It automatically manages wordlists, rules, attack methods and potfile used as a wordlist.

The password cracking method sequence for french passwords was obtained using the following code : [autocat-training](https://github.com/k4amos/Autocat-training)

⚠️ The README is currently under construction.


## Installation

1. Clone the repository:
```bash
git clone https://github.com/k4amos/Autocat
cd Autocat
```

2. Make the script executable:
```bash
chmod +x autocat.sh
```

## Usage

Autocat uses the same syntax as Hashcat. The attack mode (`-a` option) is handled automatically based on the cracking sequence.

### Basic Usage

```bash
./autocat.sh -m [hash_type] [hash_file]
```

### Examples

Crack NTLM hashes:
```bash
./autocat.sh -m 1000 hashes.txt
```

### Supported Hash Types

Autocat supports all hash types that Hashcat supports.

## Configuration

### config.json

The configuration file defines paths to resources

You can modify these paths to point to existing wordlist collections on your system.

### cracking_sequence.txt

This file defines the attack sequence for french🇫🇷 password. Each line specifies an attack type.

## Disclaimer

This tool is provided for educational and authorized security testing purposes only. Users are responsible for complying with all applicable laws and regulations. The authors assume no liability for misuse or damage caused by this tool.