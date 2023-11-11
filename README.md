<div align="center">

# `vfetch`

<h3>
  System fetch for MacOs written in <code>vlang</code>
</h3>

<img src="https://user-images.githubusercontent.com/19891059/180103104-db95ce20-4b2a-4a92-96d1-2f1e11a69b57.png" width="50%">
</div>

# Usage
```bash
vfetch
```
flags:
```
 -s --song   | Print current playing music, works with Apple Music
 -i --image  | Display custom image, only works with kitty terminal
```

# Installation

## Homebrew

```bash
brew install carlosqsilva/brew/vfetch
```

## Install from source

### 0) Install [vlang](https://vlang.io), and add to your `path`
### 1) clone repo
```bash
git clone https://github.com/carlosqsilva/vfetch.git
```
### 2) change dir to `vfetch`
```bash
cd vfetch/
```
### 3) build program
```bash
v -prod .
```
After that you will get a ready-made binary file in the root directory of the project.


# Thanks for ideas & examples 💬
- [pfetch](https://github.com/dylanaraps/pfetch/)
- [neofetch](https://github.com/dylanaraps/neofetch)
- [nitch](https://github.com/unxsh/nitch)
