# Autocat - Hashcat Wrapper with more optimal cracking method


<p align="center">
    <img src="tool/img/logo.png" style="height:350px">
</p>

## How it works

The password cracking method sequence was obtained using the following code : [autocat-training](https://github.com/k4amos/Autocat-training)


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
