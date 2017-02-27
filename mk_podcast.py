#! /usr/bin/python
#! -*- coding: utf-8 -*-

"""
Making a Podcast.
https://www.apple.com/jp/itunes/podcasts/specs.html
"""

import os, string, sys
from datetime import datetime

HEADER = """<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
<channel>
<title>$title</title>
<link>$link</link>
<language>ja-jp</language>
<copyright>$copyright</copyright>
<itunes:subtitle>$subtitle</itunes:subtitle>
<itunes:author>$author</itunes:author>
<itunes:summary>$summary</itunes:summary>
<description>$description</description>
<itunes:owner>
<itunes:name>$name</itunes:name>
<itunes:email>$email</itunes:email>
</itunes:owner>
<itunes:image href="$image" />
<itunes:category text="Philosophy" />
"""

ITEM = """<item>
<title>$title</title>
<itunes:author>$author</itunes:author>
<itunes:subtitle>$subtitle</itunes:subtitle>
<itunes:summary>$summary</itunes:summary>
<itunes:image href="$image" />
<enclosure url="$url" length="$length" type="$type" />
<guid>$guid</guid>
<pubDate>$date</pubDate>
<itunes:duration>$duration</itunes:duration>
</item>
"""

FOOTER = """</channel>
</rss>
"""

TYPES = {
         ".mp3" :"audio/mpeg",
         ".m4a" :"audio/x-m4a",
         ".mp4" :"video/mp4",
         ".m4v" :"video/x-m4v",
         ".mov" :"video/quicktime",
         ".pdf" :"application/pdf",
         ".epub":"document/x-epub"
        }

class Item:
    pass

def main():
    #
    args = sys.argv
    base_path = args[1]
    url       = args[2]
    output    = args[3]
    title     = args[4]
    time      = int(args[5])
    #
    xml  = ''
    #
    item = Item()
    item.title       = title
    item.link        = url
    item.copyright   = ""
    item.subtitle    = ""
    item.author      = ""
    item.summary     = ""
    item.description = ""
    item.name        = ""
    item.email       = ""
    item.image       = os.path.join(url, "image.png")
    xml += get_header(item)
    #
    data_path = os.path.join(base_path, "data/")
    #
    rotate(data_path)
    #
    files = os.listdir(data_path)
    files.sort(reverse=True)
    for file in files:
        path      = os.path.join(data_path, file)
        name, ext = os.path.splitext(file)
        #
        item = Item()
        item.title    = name
        item.author   = ""
        item.subtitle = ""
        item.summary  = ""
        item.image    = ""
        item.url      = os.path.join(url, "data/" + file)
        item.length   = os.path.getsize(path)
        if TYPES.has_key(ext):
            item.type = TYPES[ext]
        else:
            continue
        item.guid     = item.url
        item.date     = datetime.fromtimestamp(os.path.getctime(path)).strftime("%a, %d %b %Y %H:%M:%S +0900")
        item.duration = "%2d:%2d" % (time / 60, time % 60)
        xml += get_item(item)
    #
    xml += get_footer()
    #
    out = open(os.path.join(base_path, output), "w")
    out.write(xml)
    out.close()

def get_header(item):
    return string.Template(HEADER).safe_substitute(
        title       = item.title,
        link        = item.link,
        copyright   = item.copyright,
        subtitle    = item.subtitle,
        author      = item.author,
        summary     = item.summary,
        description = item.description,
        name        = item.name,
        email       = item.email,
        image       = item.image,
    )

def get_item(item):
    return string.Template(ITEM).safe_substitute(
        title    = item.title,
        author   = item.author,
        subtitle = item.subtitle,
        summary  = item.summary,
        image    = item.image,
        url      = item.url,
        length   = item.length,
        type     = item.type,
        guid     = item.guid,
        date     = item.date,
        duration = item.duration,
    )

def get_footer():
    return FOOTER

def rotate(path):
    files = os.listdir(path)
    files.sort(reverse=True)
    for file in files[10:]:
        os.remove(os.path.join(path, file))
    pass

if __name__ == "__main__":
    main()
    pass

