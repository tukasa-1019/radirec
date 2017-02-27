#! /bin/bash

# URL of A&G
URL=rtmp://fms-base1.mitene.ad.jp/agqr/aandg22
# Recording margin (sec.)
MARGIN=15
# Path of output
DST=/storage/owncloud/luciole/files/Radios/
#DST=/webdav/localhost/Radios/
# Path of rtmpdump
RTMPDUMP=/usr/local/bin/rtmpdump
# Path of ffmpeg
FFMPEG=/usr/bin/ffmpeg
# Path of podcast
PODCAST_DST=/var/www/html/podcast
# Url of podcast
PODCAST_URL="http://192.168.0.39/podcast"


# Check argments
if [ $# -lt 4 ]; then
  echo "usage: ${0} title rtime fname ext"
  exit 1
fi
# Title
TITLE=$1
# Recording time (sec.)
RTIME=$2
# File name title
FNAME=$3
# Format (mp4 or m4a)
EXT=$4

# Calc. sleep time (sec.)
SLEEP=`expr \( 60 - ${MARGIN} % 60 \) % 60`

# Get padding minutes for filename
PADDING=`expr ${MARGIN} / 60`
if [ `expr ${MARGIN} % 60` -ne 0 ]; then
  PADDING=`expr ${PADDING} + 1`
fi
# Date for file name
DATE=`date --date "${PADDING} minutes" +%Y%m%d%H%M`

# Recording
/usr/bin/sleep ${SLEEP}
STOP=`expr ${RTIME} + ${MARGIN}`
TEMP="/tmp/${DATE}_${FNAME}.flv"
${RTMPDUMP} -r ${URL} --stop ${STOP} --live -o ${TEMP}

# Encode
OUTPUT="${DST}${TITLE}"
if [ ! -e ${OUTPUT} ]; then
  mkdir -p ${OUTPUT}
fi
OUTPUT="${OUTPUT}/${DATE}_${FNAME}.${EXT}"
if [ ${EXT} = "mp4" ]; then
  OPT="-vcodec copy -acodec copy"
else # m4a
  OPT="-vn -acodec copy"
fi
${FFMPEG} -y -i ${TEMP} ${OPT} ${OUTPUT}

# Rescan owncloud of rtmpdump files
/usr/bin/php /var/www/html/owncloud/occ files:scan --path="/luciole/files/Radios/${TITLE}"

# Podcast
DATA_DIR=${PODCAST_DST}/${FNAME}/data
if [ ! -e ${DATA_DIR} ]; then
  mkdir -p ${DATA_DIR}
fi
cp -p ${OUTPUT} ${DATA_DIR}
MK_PODCAST=`dirname "$0"`/mk_podcast.py
/usr/bin/python ${MK_PODCAST} "${PODCAST_DST}/${FNAME}" "${PODCAST_URL}/${FNAME}" "podcast.xml" "${TITLE}" ${STOP}
