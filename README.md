# RadiRec

- 超！A&G+ と Radiko を録音するための環境、Webインタフェース

## 必須環境

- ffmpeg
    - https://ffmpeg.org/
        - version 2.6.8 で動作確認

- rtmpdump
    - https://rtmpdump.mplayerhq.hu/
        - v2.4 で動作確認

- swftools
    - http://www.swftools.org/download.html
        - 2013-04-09-1007(Development Snapshot) で動作確認

- php
    - 7.0 で動作確認

- python
    - 2.7.5 で動作確認

- Web サーバー
    - apache 2.4.6 で動作確認

## セットアップ

- 任意のディレクトリで

```
# git clone https://github.com/tukasa-1019/radirec
```

- ブラウザからアクセス出来る場所に配備

### 設定

- radirec.sh を適宜調整

```
# 開始時間の何秒前から録音を開始するか
# Recording margin (sec.)
MARGIN=20

# 録音データの出力先
# Path of output
DST=/home/rtmpdump

# ワークスペース（.flv などの DL 先）
# Workspace
WORKSPACE=/tmp/rtmpdump

# ffmpeg のパス（デフォルトと異なれば指定）
# Path of ffmpeg
FFMPEG=/usr/bin/ffmpeg

# rtmpdump のパス（デフォルトと異なれば指定）
# Path of rtmpdump
RTMPDUMP=/usr/bin/rtmpdump

# swfextract のパス（デフォルトと異なれば指定）
# Path of swfextract
SWFEXTRACT=/usr/local/bin/swfextract

# Podcast データの出力先（機能を使わないのであれば空欄のママ）
# Path of podcast
PODCAST_DST=

# Podcast の配信 URL
# URL of podcast
PODCAST_URL=https://sample.com/podcast

# 超！A&G+ の配信 URL 、変更があった場合に修正
# URL of A&G
AANDG_URL=rtmp://fms-base1.mitene.ad.jp/agqr/aandg22

# Radiko の配信 URL など、変更があった場合に修正
# URLs of Radiko
RADIKO_PLAYER_URL=http://radiko.jp/apps/js/flash/myplayer-release.swf
RADIKO_AUTH1_URL=https://radiko.jp/v2/api/auth1_fms
RADIKO_AUTH2_URL=https://radiko.jp/v2/api/auth2_fms
RADIKO_CHANNEL_URL=http://radiko.jp/v2/station/stream/
```

- 録音完了後に任意のスクリプトを動作させたい場合

```
# cp post-script.sample post-script
# chmod +x post-script
```

----------------------------------------------------------------------------------------------------

#### 参考

##### CentOS 7 で ffmpeg, rtmpdump, swftools, php の導入手順

- nux-dextop リポジトリの導入
    - https://li.nux.ro/repos.html を参考に

```
# yum -y install epel-release && rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
```

- ffmpeg と rtmpdump を nux-dextop からインストール

```
# yum install ffmpeg rtmpdump --enablerepo=epel,nux-dextop
```

- swftools のインストール
    - 「\* The following headers/libraries are missing:」みたいなメッセージが出たら適宜パッケージをインストール
        - freetype-devel, giflib-devel, giflib-utils, jpeglib-devel, zlib-devel など

```
# wget http://www.swftools.org/swftools-2013-04-09-1007.tar.gz
# tar xzvf swftools-2013-04-09-1007.tar.gz
# cd swftools-2013-04-09-1007
# ./configure
# make && make install
```

- remi リポジトリのインストール

```
# rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
```

- php 7.0 のインストール

```
# yum install --enablerepo=remi-php70 php php-mbstring
```

