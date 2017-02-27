#! /bin/bash

# URLs of Radiko
#PLAYER_URL=http://radiko.jp/player/swf/player_4.1.0.00.swf
PLAYER_URL=http://radiko.jp/apps/js/flash/myplayer-release.swf
AUTH1_URL=https://radiko.jp/v2/api/auth1_fms
AUTH2_URL=https://radiko.jp/v2/api/auth2_fms
CHANNEL_URL=http://radiko.jp/v2/station/stream/
# Recording margin (sec.)
MARGIN=30
# Path of output
DST=/storage/owncloud/luciole/files/Radios/
#DST=/webdav/localhost/Radios/
# Workspace
WORKSPACE=/tmp/radiko
# Path of rtmpdump
RTMPDUMP=/usr/local/bin/rtmpdump
# Path of swfextract
SWFEXTRACT=/usr/bin/swfextract
# Path of ffmpeg
FFMPEG=/usr/bin/ffmpeg


# Check argments
if [ $# -lt 4 ]; then
  echo "usage: ${0} title rtime fname channel"
  exit 1
fi
# Title
title=$1
# Recording time (sec.)
rtime=$2
# File name title
fname=$3
# Channel
channel=$4

# Create workspace if need
if [ ! -f ${WORKSPACE} ]; then
  /usr/bin/mkdir -p ${WORKSPACE}
fi

# Get player if need
player_file=${WORKSPACE}/player.swf
if [ ! -f ${player_file} ]; then
  /usr/bin/wget -q -O ${player_file} ${PLAYER_URL}
  if [ $? -ne 0 ]; then
    echo "failed get player"
    exit 1
  fi
fi

# Get authkey if need
key_file=${WORKSPACE}/authkey.png
if [ ! -f ${key_file} ]; then
  ${SWFEXTRACT} -b 12 ${player_file} -o ${key_file}
  if [ $? -ne 0 ]; then
    echo "failed get key"
    exit 1
  fi
fi

# Access auth1_fms
auth1_file=${WORKSPACE}/auth1_fms_${channel}
/usr/bin/wget -q \
              --header="pragma: no-cache" \
              --header="X-Radiko-App: pc_ts" \
              --header="X-Radiko-App-Version: 4.0.0" \
              --header="X-Radiko-User: test-stream" \
              --header="X-Radiko-Device: pc" \
              --post-data='\r\n' \
              --no-check-certificate \
              --save-headers \
              -O ${auth1_file} \
              ${AUTH1_URL}
if [ $? -ne 0 ]; then
  echo "failed get auth1"
  exit 1
fi

# Get partialkey
authtoken=`/usr/bin/sed -ne 's/^X-Radiko-AuthToken=\(.\+\)\r$/\1/p' ${auth1_file}`
length=`/usr/bin/sed -ne 's/^X-Radiko-KeyLength=\([0-9]\+\)\r$/\1/p' ${auth1_file}`
offset=`/usr/bin/sed -ne 's/^X-Radiko-KeyOffset=\([0-9]\+\)\r$/\1/p' ${auth1_file}`
partialkey=`/usr/bin/dd if=${key_file} bs=1 skip=${offset} count=${length} 2>/dev/null | /usr/bin/base64`

# Remove auth1
/usr/bin/rm -f ${auth1_file}

# Access auth2_fms
auth2_file=${WORKSPACE}/auth2_fms_${channel}
/usr/bin/wget -q \
              --header="pragma: no-cache" \
              --header="X-Radiko-App: pc_ts" \
              --header="X-Radiko-App-Version: 4.0.0" \
              --header="X-Radiko-User: test-stream" \
              --header="X-Radiko-Device: pc" \
              --header="X-Radiko-AuthToken: ${authtoken}" \
              --header="X-Radiko-PartialKey: ${partialkey}" \
              --post-data='\r\n' \
              --no-check-certificate \
              -O ${auth2_file} \
              ${AUTH2_URL}
if [ ! -f ${auth2_file} ]; then
  echo "failed get auth2"
  exit 1
fi

# Remove auth2
/usr/bin/rm -f ${auth2_file}

# Get channel
channel_file=${WORKSPACE}/${channel}.xml
/usr/bin/wget -q -O ${channel_file} ${CHANNEL_URL}${channel}.xml
if [ ! -f ${channel_file} ]; then
  echo "failed get channel"
  exit 1
fi

# Get stream url
stream_url=`echo "cat /url/item[1]/text()" | /usr/bin/xmllint --shell ${channel_file} | tail -2 | head -1`
url_parts=(`echo ${stream_url} | /usr/bin/sed -e 's/^\(.*\):\/\/\(.*\)\/\(.*\)\/\(.*\)\/\(.*\)$/\1:\/\/\2 \3\/\4 \5/'`)

# Remove channel
/usr/bin/rm ${channel_file}

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
flv_file=${WORKSPACE}/${file_name}.flv

# Sleep
/usr/bin/sleep `expr \( 60 - ${MARGIN} % 60 \) % 60`

# Recording
${RTMPDUMP} --rtmp ${url_parts[0]} \
            --app ${url_parts[1]} \
            --playpath ${url_parts[2]} \
            --swfVfy ${PLAYER_URL} \
            --conn S:"" --conn S:"" --conn S:"" --conn S:${authtoken} \
            --live \
            --stop ${stop} \
            --flv ${flv_file}

# Encode
output="${DST}${title}"
if [ ! -e ${output} ]; then
  mkdir -p ${output}
fi
output="${output}/${file_name}.m4a"
${FFMPEG} -y -i ${flv_file} -vn -acodec copy ${output}

# Rescan owncloud of rtmpdump files
/usr/bin/php /var/www/html/owncloud/occ files:scan --path="/luciole/files/Radios/${title}"
