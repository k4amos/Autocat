# Autocat - Hashcat Wrapper with optimal cracking method

![](https://github.com/thomas-girard/Autocat/img.logo.png)


## How it works


## Quick Start

```bash
git clone git@github.com:thomas-girard/Autocat.git
cd Autocat
chmod +x autocat.sh
```

Use exactly the same syntax as Hashcat; the choice of cracking methods (option -a) will be done automatically.

```bash
./autocat.sh -m 1000 hash_file_name
```