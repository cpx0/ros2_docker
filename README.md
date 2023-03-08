# myCobot 動作環境構築 with Docker

## 実行環境構築手順
以下にインストール手順の記事を順番に貼り付けてみました。

1. Ubuntu20.04LTSブート：[Windows10とUbuntu18.04を別ディスクで簡単デュアルブート](https://qiita.com/udai1532/items/4893af6ea4da3e20b302)
1. Proxy設定：[UbuntuのProxy設定備忘録](https://qiita.com/daichi-ishida/items/b77c151067427806ede5) ※Proxy環境でない場合はスキップ
1. NVIDIA driver, [CUDA Toolkit 11.0](https://developer.nvidia.com/cuda-11-0-3-download-archive?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=runfile_local), cuDNN インストール：[Installing the NVIDIA driver, CUDA and cuDNN on Linux (Ubuntu 20.04)](https://gist.github.com/kmhofmann/cee7c0053da8cc09d62d74a6a4c1c5e4)
1. RDP接続対応(xrdp)：[ubuntu18.04でのxrdpトラブル対応とリモートデスクトップ設定](https://qiita.com/underwell111/items/c0069a4d39d3694e1d4a)
    - 【Dual Boot】リモートでブートOSを切り替え：[リモートでデュアルブートを切り替える](https://qiita.com/ykawakamy/items/c1bb215aec15591d29f3)
        
        Ubuntuのターミナルにて以下コマンドで、grubメニューのデフォルトを設定する。 
        ```sh
        sudo grub-reboot 2 
        ```
        ↑Grubメニュー(0番で始まる)の”2”(Windows)を次回の選択bootデフォルトに設定。 
        （再起動するごとにデフォルトは"0"(Ubuntu)に戻される。） 
        ```sh
        sudo reboot 
        ```
1. Dockerインストール：[Ubuntu 18.04 LTS / 20.04 LTS に Docker をインストールする](https://sid-fm.com/support/vm/guide/install-docker-ubuntu.html)
1. nvidia-docker2インストール：[Ubuntu20.04にNVIDIA-dockerを簡単にインストールする（2021/09）](https://takake-blog.com/ubutnu2004-install-nvidia-docker/)

## Dockerコンテナ構築手順

### リポジトリのクローン
```sh
git clone https://github.com/cpx0/mycobot_ve.git
```

### Dockerイメージの構築
```sh
. docker/build.sh
```
ROS 2 Distro の humble または galactic のどちらにするかの標準入力を促される（10秒間以内に入力しなければ自動的に humble を選択）
```
input for selecting ROS Distro (default: humble): 
```
|select Distro|input|
|-|-|
|humble|'&crarr;', 'humble' (anything except 'galactic')|
|galactic|'galactic'|

### Dockerコンテナの立ち上げ
```sh
. docker/launch.sh
```
ROS 2 Distro の humble または galactic のどちらにするかの標準入力を促される（10秒間以内に入力しなければ自動的に humble を選択）
```
input for selecting ROS Distro (default: humble): 
```
|select Distro|input|
|-|-|
|humble|'&crarr;', 'humble' (anything except 'galactic')|
|galactic|'galactic'|
