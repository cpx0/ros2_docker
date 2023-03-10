# ROS2 動作環境構築 with Docker

## 実行環境構築手順

<details>

<summary>Ubuntu22 - Docker - DeepLearning</summary>

### 1. Ubuntu 22.04 LTS (Jammy Jellyfish) インストール

Ubuntuを入れるとしても、Windowsも残しておく必要がある場合が多いと思いますので、ここではWindowsとUbuntuのデュアルブート手順を示します。ただし、GPGPUを安心/安全に実行するためにも、UEFIを利用したパーティション分割によるDual Bootではなく、ブートデバイスを2つのディスクに物理的に分けた状態でのDual Bootとなります。

#### 1.1. Ubuntu 22.04 LTS起動用LiveUSB作成

最低4GB以上のUSBフラッシュドライブを用意してください。また、LiveUSBにするにはドライブ全体をフォーマットしなければいけないので、フォーマット以前のドライブ内データはすべて消去されることにご注意ください。
以下のリンクから[ubuntu-22.04.1-desktop-amd64.iso](https://ubuntu.com/download/desktop/thank-you?version=22.04.1&architecture=amd64)をダウンロードしてください。
[ubuntu - Download Ubuntu Desktop](https://ubuntu.com/download/desktop)

LiveUSBを作成するツールとしては、Windowsだとダウンロードのみでインストールせずに使える[Rufus](https://rufus.ie/ja/)（ダウンロードした実行ファイルを開けば使用可能）、Ubuntuではデフォルトで使えるディスクイメージライター（英語名は[Startup Disk Creator](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#3-launch-startup-disk-creator)？）がおすすめです。

<img src="https://rufus.ie/pics/screenshot1_ja.png" width=50% height=50% alt="Rufus起動イメージ">

#### 1.2. デスクトップPCの準備

今回は別のSSDを用意してデュアルブートを行うため、パーティションは分割しません。
UEFI(BIOS)の設定を行えばそのままWindowsのブートドライブが繋がった状態でUbuntuを新たに別のドライブに入れることもできますが、パーティション分割操作をミスするとWindowsのドライブに書き込んでしまう可能性があるので、Ubuntuを入れるドライブ以外はすべて物理的に外して作業することをお勧めします。
UEFIの設定を行い、USBからブートできるようになったら再起動してUbuntuのインストールに入ります。

#### 1.3. Ubuntu 22.04 LTSのインストール

Ubuntuを入れるドライブ以外はすべて物理的に外した状態で[ubuntu - Install Ubuntu desktop](https://ubuntu.com/tutorials/install-ubuntu-desktop)の手順に従ってインストールしていきます。

以上でUbuntuのインストールが終わり、Ubuntuの利用が可能となります。
ひとまず、Ubuntu起動後にターミナル（端末）を開いて（`Alt`+`Ctrl`+`T`）、以下コマンドでレジストリを更新しておきましょう。

```terminal:terminal
sudo apt update
```

#### 1.4. GRUBの設定

この時点でWindowsのブートドライブをつなぎ直しても大丈夫です。どちらのOSを起動するかはブートローダーによります。
起動するOSを変更するにはUEFIから起動するドライブを変更することもできますが、UbuntuではGRUBを用いて起動するOSを変更できます。
インストールしたデフォルトの状態ではGRUBがWindowsを認識できず、必ずUbuntuが起動してしまいます。理由としては`/boot/grub/grub.cfg`にWindowsの記述がないため、自動的にUbuntuが立ち上がってしまいます。

そこで、まずデバイス上の他の起動可能なOSを検出できるように、`GRUB_DISABLED_OS_PROBER=false`を`/etc/default/grub`に追記してGRUBにてOS-Proberが使えるようにします。

```terminal:terminal
sudo vi /etc/default/grub
```

viの使い方は[2.1.b.a. コマンドモードのみ](https://qiita.com/cpx/items/8069cb7c9896e16febcf#21ba-%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E3%83%A2%E3%83%BC%E3%83%89%E3%81%AE%E3%81%BF)近辺をご参照ください。

```terminal:/etc/default/grub
# If you change this file, run 'update-grub' afterwards to update
# 省略
# ...
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=false

# Uncomment to enable BadRAM filtering, modify to suit your needs
# 省略
# ...
```

次にGRUBがWindowsを認識できるようにターミナルで以下を実行します。

```terminal:terminal
sudo update-grub
```

```terminal:output
Sourcing file `/etc/default/grub'
Sourcing file `/etc/default/grub.d/init-select.cfg'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-5.19.0-32-generic
Found initrd image: /boot/initrd.img-5.19.0-32-generic
Found linux image: /boot/vmlinuz-5.15.0-43-generic
Found initrd image: /boot/initrd.img-5.15.0-43-generic
Memtest86+ needs a 16-bit boot, that is not available on EFI, exiting
Warning: os-prober will be executed to detect other bootable partitions.
Its output will be used to detect bootable binaries on them and create new boot entries.
Found Windows Boot Manager on /dev/nvme*****@/efi/Microsoft/Boot/bootmgfw.efi
Adding boot menu entry for UEFI Firmware Settings ...
done
```

Windowsが入っているドライブも挿入されていれば、上記のようにWindows Boot Managerを他のbootable partitionとして検出できると思います。（`*`にて一部情報を伏せています。）
他にも`/boot/grub/grub.cfg`にWindowsの情報が追記されていることを確認できると思います。

```terminal:terminal
grep windows /boot/grub/grub.cfg
```

```terminal:output
menuentry 'Windows Boot Manager (on /dev/nvme*****)' --class windows --class os $menuentry_id_option 'osprober-efi-EA6B-5F8E' {
```

### 2. NVIDIA driverインストール

NVIDIA driverのインストールでは大まかに以下の2つの方法に分かれると思います。

* UEFIのSecure Bootを無効化してから、インストール作業開始
* UEFIのSecure Bootを有効化したまま、Machine Owner Keyリストにバイナリの署名鍵を登録してインストール

Secure Bootを無効化している前提の記事をよく見かけるので、ここではSecure Bootを有効化したままMOKを登録してインストールする手順を示します。

#### 2.1. UbuntuデフォルトグラフィックドライバーのNouveauを無効化（GUI or CLI）

UbuntuではデフォルトでNouveau driverがロードされているので、NVIDIA driverインストール前に無効化しておく必要があります。
無効化の方法が2パターンあるのでお好きな方で無効化してください。

##### 2.1.a. GUI(Graphical User Interface)でのNouveau無効化

「設定」＞「このシステムについて」＞「グラフィック」でドライバーを確認してください。
上記画像ではすでにNVIDIA driverをインストール済みですが、Ubuntuインストール後のデフォルトは"NV132"のようなNouveau driverが有効化されていると思います。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/fccf1c3a-575e-aefe-7dab-dedabae7bc9b.png" alt="Screenshot from 2023-02-10 15-21-32.png">

上記で有効化グラフィックドライバーを確認後、「ソフトウェアとアップデート」＞「追加のドライバー」がおそらくいちばん下の「X.Org X server -- Nouveau display driverをxserver-xorg-video-nouveauから使用します（オープンソース）」が選択されていると思いますので、「NVIDIA driver metapackageをnvidia-driver-***から使用します（プロプライエタリ）」を選択して「変更の適用(A)」をクリックしてください。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/badbe0ec-d519-81f9-4b45-dd0361ac6853.png" alt="Screenshot from 2023-02-10 15-17-55.png">

上記操作完了後におそらく再起動を求められると思いますので、再起動を実施してください。

```terminal:terminal
reboot
```

##### 2.1.b. CLI(Command-Line Interface)でのNouveau無効化

sudoユーザーで各コマンドを実施してください。
（もちろんrootユーザーでも大丈夫です。その場合は`sudo`の枕詞は不要です。）

```terminal:terminal
lsmod | grep nouveau
```

```terminal:output
nouveau              2306048  1
mxm_wmi                16384  1 nouveau
i2c_algo_bit           16384  1 nouveau
drm_ttm_helper         16384  1 nouveau
ttm                    86016  2 drm_ttm_helper,nouveau
drm_kms_helper        311296  1 nouveau
drm                   622592  5 drm_kms_helper,drm_ttm_helper,ttm,nouveau
video                  61440  1 nouveau
wmi                    32768  2 mxm_wmi,nouveau
```

テキストエディタで`/etc/modprobe.d/blacklist-nouveau.conf`を編集します。

```terminal:terminal
sudo vi /etc/modprobe.d/blacklist-nouveau.conf
```

おそらく新規作成となるはずです。

```conf:/etc/modprobe.d/blacklist-nouveau.conf
# 最終行に追記 (ファイルがない場合は新規作成)
blacklist nouveau
options nouveau modeset=0
```

ここでのviの使い方としては、事前に上追記内容を事前にコピーしておき、以下a,bどちらかの手順でキー操作を実施ください。

###### 2.1.b.a. コマンドモードのみ

1. `Shift`+`Ctrl`+`V`でペースト
1. `:`でコマンドモードの入力待ち状態
1. `wq`で上書き保存＋vi終了
1. `Enter(Return)`でコマンド実行

##### 2.1.b.b. 挿入モード＋コマンドモード

1. `i`で挿入モードへ移行
1. `Shift`+`Ctrl`+`V`でペースト
1. `Esc`でコマンドモードへ移行
1. `:`でコマンドモードの入力待ち状態
1. `wq`で上書き保存＋vi終了
1. `Enter(Return)`でコマンド実行

initramfsを再生成します。
initramfsについての説明は、[こちら](https://zenn.dev/miwarin/articles/d9cc9fbc227c53#initramfs-%E3%81%A8%E3%81%AF)の記事がわかりやすかったです。

```terminal:terminal
sudo update-initramfs -u
```

initramfsのupdate反映のために再起動します。

```terminal:terminal
reboot
```

#### 2.2. NVIDIA driverインストール

搭載グラフィックカードに対応するドライバーを確認します。

```terminal:terminal
ubuntu-drivers devices
```

```terminal:output
== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd00002503sv00001462sd0000397Dbc03sc00i00
vendor   : NVIDIA Corporation
model    : GA106 [GeForce RTX 3060]
driver   : nvidia-driver-525-server - distro non-free
driver   : nvidia-driver-525-open - distro non-free recommended
driver   : nvidia-driver-470 - distro non-free
driver   : nvidia-driver-510 - distro non-free
driver   : nvidia-driver-470-server - distro non-free
driver   : nvidia-driver-525 - distro non-free
driver   : nvidia-driver-515-server - distro non-free
driver   : nvidia-driver-515 - distro non-free
driver   : nvidia-driver-515-open - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin
```

所望のドライバーをインストールします。

```terminal:terminal
sudo apt install -y nvidia-driver-525
```

ターミナルが「パッケージの設定」という画面になるので、キー操作で進めていきます。

`<了解>`を`Enter`でクリックします。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/d32292f4-4bb9-2dfa-a16e-d40c8a0e6e4f.jpeg" alt="20230210_configure_secure_boot.jpg">

MOKリストに署名鍵を登録する際に必要となるパスワードを設定して、`<了解>`を`Enter`でクリックします。

> **Warning**
>
> "Perform MOK management"内ではシステムキーボードが英字キー配列が適用となっています。日本語キーボードで作業しかつ記号を用いたパスワードを設定する場合は、ご注意ください。
>
> 例．日本語キーボード上での`"`(`Shift`+`2`)＝英字キー配列での`@`(`Shift`+`2`)
>

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/b54b8704-91cc-bbb6-b0f4-f5bd10dcd47d.jpeg" alt="20230210_enter_pw_secure_boot.jpg">

"Configure Secure Boot"の設定完了後、再起動します。

```terminal:terminal
reboot
```

再起動すると以下のような"Perform MOK management"という青い画面に移行すると思います。

はじめに、方向キーで`Enroll MOK`に移動して`Enter`キーで選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/36635bd8-cfd8-f825-2129-bf865419805c.jpeg" alt="20230210_perform_mok_management_enroll_mok.JPG">

次に、方向キーで`Continue`に移動して`Enter`キーで選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/944fadfa-a424-ad11-7f59-a2f61fbbff56.jpeg" alt="20230210_enroll_mok.JPG">

方向キーで`Yes`に移動して`Enter`キーで選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/a8af6ca0-4480-5a6f-cebe-e36f8cf242bf.jpeg" alt="20230210_enroll_the_key.JPG">

「パッケージの設定」で設定したSecure Boot用のパスワードを入力して`Enter`キーで選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/83591893-e7b4-48aa-a7de-a8c61439eb26.jpeg" alt="20230210_enroll_the_key_pw.JPG">

これでバイナリ署名鍵を登録できたので、`Reboot`に移動して`Enter`キーで選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/8893903f-9c58-a564-cc26-99a3d7ed67ed.jpeg" alt="20230210_perform_mok_management_reboot.JPG">

Ubuntuでログインしてターミナルを開いて次のコマンドを打てば、選択したバージョンのNVIDIA driverが適用されていることを確認できます。

```terminal:terminal
nvidia-smi
```

```terminal:output
Sat Feb 18 01:05:08 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 525.78.01    Driver Version: 525.78.01    CUDA Version: 12.0     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0  On |                  N/A |
|  0%   43C    P8    15W / 170W |    449MiB / 12288MiB |     25%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A      2019      G   /usr/lib/xorg/Xorg                206MiB |
|    0   N/A  N/A      2157      G   /usr/bin/gnome-shell               28MiB |
|    0   N/A  N/A      3539      G   ...264950234617016841,131072      189MiB |
|    0   N/A  N/A      5376      G   gnome-control-center                2MiB |
+-----------------------------------------------------------------------------+
```

### 3. CUDA Toolkitインストール

CUDA Toolkitをインストールする場合、おすすめはrunfileでのインストールとなります。
必要なコマンドが2つのみで済み、一番簡単だからです。
以下のアーカイブから目的のバージョンを選択ください。
[nVIDIA DEVELOPER - CUDA Toolkit Archive](https://developer.nvidia.com/cuda-toolkit-archive)

例として、Ubuntu 22.04 LTSにCUDA Toolkit 11.7.1をインストールする場合、以下コマンドを実施することになります。
[nVIDIA DEVELOPER - Download Installer for Linux Ubuntu 22.04 x86_64](https://developer.nvidia.com/cuda-11-7-1-download-archive?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=runfile_local)

```terminal:terminal
wget https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_linux.run
sudo sh cuda_11.7.1_515.65.01_linux.run
```

NVIDIA driverインストール時と同じようにターミナル内で方向キーで移動、`Enter`キーで選択する画面になります。

こちらの画面では、「すでにドライバーインストールパッケージがあるけど、CUDA Toolkitインストール作業を続ける前に削除することをお勧めするよ」と言われていますが、必要なバージョンのNVIDIA driverを消すわけにはいかないので、`Continue`を選択します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/2c6c451a-eff6-f81e-4073-c9c166936584.jpeg" alt="20230210_cuda_tk_warning_existing_nvidia_driver.JPG">

次にライセンスへの同意を求められます。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/a75955e0-8adc-f940-d3ca-d6e444063714.jpeg" alt="20230210_cuda_tk_accept_eula_1.jpg">

とりあえず大丈夫そうであれば、`accept`を入力して`Enter`キーで次に進みます。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/c53008b5-ced2-9c43-ebb2-dc828781034f.jpeg" alt="20230210_cuda_tk_accept_eula_2.jpg">

インストールするソフトウェアを選択していきます。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/6287df34-368c-8d35-b6cb-a94b2bf82c17.jpeg" alt="20230210_cuda_tk_installer_1.JPG">

右方向キーで詳細展開、左方向キーで詳細縮小です。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/fc478787-d54f-e6c9-f8f2-3c1629bd3c99.jpeg" alt="20230210_cuda_tk_installer_2.JPG">

インストールするソフトウェアを確認していきます。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/fa46764c-8584-2e97-bc0a-3c6ab9f57146.jpeg" alt="20230210_cuda_tk_installer_3.JPG">

ドライバーはすでにインストール済みなので、`Enter`キーで`X`マークを外して除外します。

<img src="https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/765592/b32f9f37-b8ee-3f8a-53a4-394e723aa02b.jpeg" alt="20230210_cuda_tk_installer_4.JPG">

そして`Install`を選択して、CUDA Toolkitのインストールが開始されます。

インストールが完了すると、以下のようにインストールの概要が表示されます。

```terminal:output
===========
= Summary =
===========

Driver:   Not Selected
Toolkit:  Installed in /usr/local/cuda-11.7/

Please make sure that
 -   PATH includes /usr/local/cuda-11.7/bin
 -   LD_LIBRARY_PATH includes /usr/local/cuda-11.7/lib64, or, add /usr/local/cuda-11.7/lib64 to /etc/ld.so.conf and run ldconfig as root

To uninstall the CUDA Toolkit, run cuda-uninstaller in /usr/local/cuda-11.7/bin
***WARNING: Incomplete installation! This installation did not install the CUDA Driver. A driver of version at least 515.00 is required for CUDA 11.7 functionality to work.
To install the driver using this installer, run the following command, replacing <CudaInstaller> with the name of this run file:
    sudo <CudaInstaller>.run --silent --driver

Logfile is /var/log/cuda-installer.log

```

`PATH`と`LD_LIBRARY_PATH`にCUDAへのパスを通してね、と指示が記載されているので、ユーザーディレクトリ`~/`直下の`.bashrc`に追記します。

```terminal:terminal
vi ~/.bashrc
```

以下内容をコピペしてください。
viの使い方は[2.1.b.a. コマンドモードのみ](https://qiita.com/cpx/items/8069cb7c9896e16febcf#21ba-%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E3%83%A2%E3%83%BC%E3%83%89%E3%81%AE%E3%81%BF)をご参照ください。

```vim:~/.bashrc
# 最終行に追記
export PATH=/usr/local/cuda-11.7/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64:$LD_LIBRARY_PATH
```

再起動します。

```terminal:terminal
reboot
```

再起動後、以下コマンドでインストールされているCUDA Toolkitのバージョンを確認できます。

```terminal:terminal
nvcc -V
```

```terminal:output
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Wed_Jun__8_16:49:14_PDT_2022
Cuda compilation tools, release 11.7, V11.7.99
Build cuda_11.7.r11.7/compiler.31442593_0
```

### 4. cuDNNインストール

[nVIDIA DEVELOPER - cuDNN Archive](https://developer.nvidia.com/rdp/cudnn-archive)で目的のバージョンを選択してダウンロードしてください。

[nVIDIA DEVELOPER - NVIDIA Deep Learning cuDNN Documentation - 1.3.1. Tar File Installation](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html#installlinux-tar)に記載されているインストール手順に従っていきます。

例として、CUDA Toolkit 11.7を入れたUbuntu 22.04 LTSにcuDNN 8.7をインストールする場合、以下リンクを開いてダウンロードします。
[Local Installer for Linux x86_64 (Tar)](https://developer.nvidia.com/downloads/c118-cudnn-linux-8664-87084cuda11-archivetarz)

`~/Downloads`ディレクトリ下に`cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz`を保存した場合、`~$`=`/home/${USER}`のホームディレクトリにて以下コマンドを実施することになります。

```termial:terminal
tar -xvf ~/Downloads/cudnn-linux-x86_64-8.7.0.84_cuda11-archive.tar.xz -C ~/
sudo cp cudnn-linux-x86_64-8.7.0.84_cuda11-archive/include/cudnn*.h /usr/local/cuda/include
sudo cp -P cudnn-linux-x86_64-8.7.0.84_cuda11-archive/lib/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
```

以下コマンドでインストールしたcuDNNバージョンを確認できます。

```terminal:terminal
cat /usr/local/cuda/include/cudnn_version.h | grep CUDNN_MAJOR -A 2
```

```terminal:output
#define CUDNN_MAJOR 8
#define CUDNN_MINOR 7
#define CUDNN_PATCHLEVEL 0
--
#define CUDNN_VERSION (CUDNN_MAJOR * 1000 + CUDNN_MINOR * 100 + CUDNN_PATCHLEVEL)

/* cannot use constexpr here since this is a C-only file */

```

### 5. Docker Engineインストール

[docker docs - Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)に従ってDocker Engineをインストールしていきます。

とりあえず、以下コマンドを実行することで、Docker Engineインストールとバージョン確認ができます。

```terminal:terminal
sudo apt update
sudo apt-get install \
     ca-certificates \
     curl \
     gnupg \
     lsb-release
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker version
```

次に、dockerを`sudo`なしで実行できるように、ユーザーをdockerグループに追加します。
[docker docs - Linux post-installation steps for Docker Engine](https://docs.docker.com/engine/install/linux-postinstall/)に従って作業します。
以下コマンドでいいのですが、dockerグループはできているはずなので、`groupadd`と`newgrp`は必要ないと思われますが、とりあえず公式ドキュメントに従って記載しておきました。私の環境では「すでにdockerグループあるよ」とエラーが出てしまいましたが、とりあえず`usermod -aG`でdockerグループにユーザーを追加することになるので、`docker version`は正常に動作しました。

```terminal:terminal
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
docker version
```

### 6. NVIDIA Container Toolkitインストール

[NVIDIA Cloud Native Technologies - NVIDIA CONTAINER TOOLKIT: Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)に従って、Docker内でのGPU動作に必要なNVIDIA Container Tooolkitをインストールします。

一昔前（1年ほど前？）までは`nvidia-docker2`がDocker内でのGPU動作に必要だったのですが、現在の情報によると、`nvidia-docker2`および`nvidia-container-runtime`は`nvidia-container-toolkit`に統合されたことで非推奨となっているそうです。
情報のソースは[NVIDIA Cloud Native Technologies - NVIDIA CONTAINER TOOLKIT: Architecture Overview](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/arch-overview.html)になります。該当箇所を以下に抜粋しておきます。

> **Note**
> 
> In the past the `nvidia-docker2` and `nvidia-container-runtime` packages were also discussed as part of the NVIDIA container stack. These packages should be considered deprecated as their functionality has been merged with the `nvidia-container-toolkit` package. The packages may still be available to introduce dependencies on `nvidia-container-toolkit` and ensure that older workflows continue to function. For more information on these packages see the documentation archive for version older than `v1.12.0`.
> 

[Setting up NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#setting-up-nvidia-container-toolkit)からNVIDIA Container Tooolkitインストール準備が始まります。

まず、以下コマンドでパッケージリポジトリとGPGキーを設定します。

```terminal:terminal
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

上記設定内容を反映するために、以下コマンドでパッケージリストを更新し`nvidia-container-toolkit`をインストールします。

```terminal:terminal
sudo apt update
sudo apt install -y nvidia-container-toolkit
```

次にNVIDIA Container Runtimeを認識するために、以下コマンドでDockerデーモンを設定します。

```terminal:terminal
sudo nvidia-ctk runtime configure --runtime=docker
```

```terminal:output
INFO[0000] Loading docker config from /etc/docker/daemon.json 
INFO[0000] Config file does not exist, creating new one 
INFO[0000] Flushing docker config to /etc/docker/daemon.json 
INFO[0000] Successfully flushed config                  
INFO[0000] Wrote updated config to /etc/docker/daemon.json 
INFO[0000] It is recommended that the docker daemon be restarted. 
```

しかし、私の環境では「`/etc/docker/daemon.json`なんていうディレクトリやファイルは存在しないよ」と怒られてしまったので、以下コマンドで当該ディレクトリおよびファイルを新規作成しました。

```terminal:terminal
sudo mkdir -p /etc/docker
sudo vi /etc/docker/daemon.json
```

以下内容をコピペしてください。

```json:/etc/docker/daemon.json
{
   "runtimes" : {
      "nvidia" : {
         "path" : "/usr/bin/nvidia-container-runtime",
         "runtimeArgs" : []
      }
   }
}
```

そうすれば以下コマンドが正常に動作します。（表面上では上記jsonの書き順が整理されるだけでしたが、内部的にはこのコマンドでしかランタイムの設定が更新されない可能性などもあるので、しっかり実行しておきましょう。）

```terminal:terminal
sudo nvidia-ctk runtime configure --runtime=docker
```

新しいランタイム設定を適用するためにDockerデーモンを再始動します。

```terminal:terminal
sudo systemctl restart docker
```

以上で、Ubuntu 22.04 LTSにてDocker内でGPUを動かすための環境構築は完了となります。

念のため、以下コマンドを実行してDocker内でGPUを動かせるかどうかを確認しましょう。
新しくDockerイメージ(下記イメージは約6.8GB)をpullしてくるので、ダウンロードに少々時間がかかります。

```terminal:terminal
docker run --rm --gpus all \
    nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 \
    bash -c "nvidia-smi; nvcc -V"
```

以下のような出力が得られれば、Docker内でGPUを動かせていることの確認が完了となります。

```terminal:output
==========
== CUDA ==
==========

CUDA Version 11.7.1

Container image Copyright (c) 2016-2022, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.nvidia.com/ngc/nvidia-deep-learning-container-license

A copy of this license is made available in this container at /NGC-DL-CONTAINER-LICENSE for your convenience.

Fri Feb 17 16:47:33 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 525.78.01    Driver Version: 525.78.01    CUDA Version: 12.0     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  Off  | 00000000:01:00.0  On |                  N/A |
|  0%   43C    P8    15W / 170W |    380MiB / 12288MiB |     22%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2022 NVIDIA Corporation
Built on Wed_Jun__8_16:49:14_PDT_2022
Cuda compilation tools, release 11.7, V11.7.99
Build cuda_11.7.r11.7/compiler.31442593_0

```

</details>

## Dockerコンテナ構築手順

### リポジトリのクローン
```terminal:terminal
git clone https://github.com/cpx0/ros2_docker.git
```

### Dockerイメージの構築
```terminal:terminal
. docker/build.sh
```
ROS 2 Distro の humble または galactic のどちらにするかの標準入力を促される（10秒間以内に入力しなければ自動的に humble を選択）
```terminal:interactive
input for selecting ROS Distro (default: humble): 
```
|select Distro|input|
|-|-|
|humble|'&crarr;', 'humble' (anything except 'galactic')|
|galactic|'galactic'|

### Dockerコンテナの立ち上げ
```terminal:terminal
. docker/launch.sh
```
ROS 2 Distro の humble または galactic のどちらにするかの標準入力を促される（10秒間以内に入力しなければ自動的に humble を選択）
```terminal:interactive
input for selecting ROS Distro (default: humble): 
```
|select Distro|input|
|-|-|
|humble|'&crarr;', 'humble' (anything except 'galactic')|
|galactic|'galactic'|

### ROS 2 パッケージ郡のビルドおよびソース

`host`:`container`=`$(pwd)`:`home/${USER}/workspace`とボリュームしており、`$(pwd)`=`ros2_docker`ディレクトリ（repo直下）でコンテナを立ち上げたと思います。

ros2_dockerディレクトリは次のようなツリー構造としています。
```
ros2_docker
|-- docker
|   |-- etc...
|-- src
|   |-- pkgs...
|-- etc...
```

上記の`ros2_docker/src`ディレクトリ内に利用したいROS2パッケージを配置ください。

以下コマンドで`ros2_docker/src`ディレクトリ内のROS2パッケージのビルドとソースを実行すれば、配置したROS2パッケージを利用可能となります。

```terminal:terminal
colcon build --symlink-install
source ./install/setup.bash
```

