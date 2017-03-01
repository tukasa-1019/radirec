#! /bin/bash

# Recording margin (sec.)
MARGIN=20

# Path of output
DST=/tmp/rtmpdump

# Workspace
WORKSPACE=/tmp/rtmpdump

# Path of ffmpeg
FFMPEG=/usr/bin/ffmpeg

# Path of rtmpdump
RTMPDUMP=/usr/bin/rtmpdump

# Path of swfextract
SWFEXTRACT=/usr/local/bin/swfextract

# Path of podcast
PODCAST_DST=

# URL of podcast
PODCAST_URL=https://sample.com/podcast

# URL of A&G
AANDG_URL=rtmp://fms-base1.mitene.ad.jp/agqr/aandg22

# URLs of Radiko
RADIKO_PLAYER_URL=http://radiko.jp/apps/js/flash/myplayer-release.swf
RADIKO_AUTH1_URL=https://radiko.jp/v2/api/auth1_fms
RADIKO_AUTH2_URL=https://radiko.jp/v2/api/auth2_fms
RADIKO_CHANNEL_URL=http://radiko.jp/v2/station/stream/


# Check argments
if [ $# -ne 4 ]; then
  cat <<EOT
Usage:
  $0 chennel title rtime fname

channel:
  Selected from below.

    AGQR            A&G+
    AGQRA           A&G+ (Sound only)

    TBS             JOKR (TBS Radio)
    QRR             JOQR (Bunka Hoso AM 1134)
    LFR             JOLF (Nippon Hoso)
    RN1             JOZ4 (Radio Nikkei 1)
    RN2             JOZ7 (Radio Nikkei 2)
    INT             JODW-FM (InterFM897)
    FMT             JOAU-FM (Tokyo FM)
    FMJ             JOAV-FM (J-WAVE)
    JOFR            JORF (Radio Nippon)
    BAYFM87         JOGV-FM (bayfm78)
    NACK5           JODV-FM (FM NACK5)
    YFM             JOTU-FM (FM Yokohama 84.7)
    HOUSOU-DAIGAKU  JOUD-FM (The Open University of Japan)

title:
  The recording title used for folder name and podcast.

rtime:
  The recording seconds.

fname:
  The recording file name.
EOT
  exit 1
fi
# Channel
channel=$1
# Title
title=$2
# Recording time (sec.)
rtime=$3
# File name title
fname=$4

# Create workspace if need
if [ ! -f ${WORKSPACE} ]; then
  /usr/bin/mkdir -p ${WORKSPACE}
fi

# Get padding minutes for filename
padding=`expr ${MARGIN} / 60`
if [ `expr ${MARGIN} % 60` -ne 0 ]; then
  padding=`expr ${padding} + 1`
fi

# Get file name
file_name=`date --date "${padding} minutes" +%Y%m%d%H%M`"_${fname}"

# Get recording time
stop=`expr ${rtime} + ${MARGIN}`

# Set temporary file path
flv=${WORKSPACE}/${file_name}.flv

if [ ${channel} = "AGQR" -o ${channel} = "AGQRA" ]; then
  # Set rtmpdump parameters
  rtmpdump_params="--rtmp ${AANDG_URL}
                   --live
                   --stop=${stop}
                   --flv ${flv}"
else
  # Get player if need
  radiko_player=${WORKSPACE}/player.swf
  if [ ! -f ${radiko_player} ]; then
    /usr/bin/wget -q -O ${radiko_player} ${RADIKO_PLAYER_URL}
    if [ $? -ne 0 ]; then
      echo "Fail to get Radiko player"
      exit 1
    fi
  fi

  # Get authkey if need
  radiko_authkey=${WORKSPACE}/authkey.png
  if [ ! -f ${radiko_authkey} ]; then
    ${SWFEXTRACT} -b 12 ${radiko_player} -o ${radiko_authkey}
    if [ $? -ne 0 ]; then
      echo "Fail to get Radiko authkey"
      exit 1
    fi
  fi

  # Access auth1_fms
  radiko_auth1=${WORKSPACE}/auth1_fms_${channel}
  /usr/bin/wget -q \
                --header="pragma: no-cache" \
                --header="X-Radiko-App: pc_ts" \
                --header="X-Radiko-App-Version: 4.0.0" \
                --header="X-Radiko-User: test-stream" \
                --header="X-Radiko-Device: pc" \
                --post-data="\r\n" \
                --no-check-certificate \
                --save-headers \
                -O ${radiko_auth1} \
                ${RADIKO_AUTH1_URL}
  if [ $? -ne 0 ]; then
    echo "Fail to get Radiko auth1"
    exit 1
  fi

  # Get partialkey
  auth_token=`/usr/bin/sed -ne 's/^X-Radiko-AuthToken=\(.\+\)\r$/\1/p' ${radiko_auth1}`
  length=`/usr/bin/sed -ne 's/^X-Radiko-KeyLength=\([0-9]\+\)\r$/\1/p' ${radiko_auth1}`
  offset=`/usr/bin/sed -ne 's/^X-Radiko-KeyOffset=\([0-9]\+\)\r$/\1/p' ${radiko_auth1}`
  partial_key=`/usr/bin/dd if=${radiko_authkey} bs=1 skip=${offset} count=${length} 2>/dev/null | /usr/bin/base64`

  # Remove auth1
  /usr/bin/rm -f ${radiko_auth1}

  # Access auth2_fms
  radiko_auth2=${WORKSPACE}/auth2_fms_${channel}
  /usr/bin/wget -q \
                --header="pragma: no-cache" \
                --header="X-Radiko-App: pc_ts" \
                --header="X-Radiko-App-Version: 4.0.0" \
                --header="X-Radiko-User: test-stream" \
                --header="X-Radiko-Device: pc" \
                --header="X-Radiko-AuthToken: ${auth_token}" \
                --header="X-Radiko-PartialKey: ${partial_key}" \
                --post-data="\r\n" \
                --no-check-certificate \
                -O ${radiko_auth2} \
                ${RADIKO_AUTH2_URL}
  if [ ! -f ${radiko_auth2} ]; then
    echo "Fail to get Radiko auth2"
    exit 1
  fi

  # Remove auth2
  /usr/bin/rm -f ${radiko_auth2}

  # Get channel
  radiko_channel=$WORKSPACE/${channel}.xml
  /usr/bin/wget -q \
                -O ${radiko_channel} \
                ${RADIKO_CHANNEL_URL}${channel}.xml

  # Get stream url
  stream_url=`echo "cat /url/item[1]/text()" | /usr/bin/xmllint --shell ${radiko_channel} | /usr/bin/tail -2 | /usr/bin/head -1`
  url_parts=(`echo ${stream_url} | /usr/bin/sed -e "s/^\(.*\):\/\/\(.*\)\/\(.*\)\/\(.*\)\/\(.*\)$/\1:\/\/\2 \3\/\4 \5/"`)

  # Remove channel
  /usr/bin/rm ${radiko_channel}

  # Set rtmpdump parameters
  rtmpdump_params="--rtmp ${url_parts[0]}
                   --app ${url_parts[1]}
                   --playpath ${url_parts[2]}
                   --swfVfy ${RADIKO_PLAYER_URL}
                   --conn S:\"\" --conn S:\"\" --conn S:\"\" --conn S:${auth_token}
                   --live
                   --stop ${stop}
                   --flv ${flv}"
  echo ${rtmpdump_params}
fi

# Sleep
/usr/bin/sleep `expr \( 60 - ${MARGIN} % 60 \) % 60`

# Recording
${RTMPDUMP} ${rtmpdump_params}

# Set extension
if [ ${channel} = "AGQR" ]; then
  ext="mp4"
else
  ext="m4a"
fi

# Encode
dst="${DST}/${title}"
if [ ! -e ${dst} ]; then
  /usr/bin/mkdir -p ${dst}
fi
dst="${dst}/${file_name}.${ext}"
if [ ${ext} = "mp4" ]; then
  ffmpeg_opt="-vcodec copy -acodec copy"
else
  ffmpeg_opt="-vn -acodec copy"
fi
${FFMPEG} -y -i ${flv} ${ffmpeg_opt} ${dst}

# Podcast
if [ -e ${PODCAST_DST} ]; then
  data_dir="${PODCAST_DST}/${fname}/data"
  if [ ! -e ${data_dir} ]; then
    /usr/bin/mkdir -p ${data_dir}
  fi
  /usr/bin/cp -p ${dst} ${data_dir}
  mk_podcast=`dirname "$0"`/mk_podcast.py
  /usr/bin/python ${mk_podcast} ${PODCAST_DST}/${fname} ${PODCAST_URL}/${fname} podcast.xml ${title} ${stop}
fi

