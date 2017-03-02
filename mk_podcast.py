#! /usr/bin/python
#! -*- coding: utf-8 -*-

"""
Making a Podcast.
https://www.apple.com/jp/itunes/podcasts/specs.html
"""

import argparse
import os
import string
import sys
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
    ".mp3"  : "audio/mpeg",
    ".m4a"  : "audio/x-m4a",
    ".mp4"  : "video/mp4",
    ".m4v"  : "video/x-m4v",
    ".mov"  : "video/quicktime",
    ".pdf"  : "application/pdf",
    ".epub" : "document/x-epub",
}

def main():
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('src')
    parser.add_argument('url')
    parser.add_argument('-t', '--title')
    parser.add_argument('-d', '--duration')
    parser.add_argument('-o', '--output')
    args = parser.parse_args()

    src = args.src
    url = args.url

    title = ""
    if args.title != None:
        title = args.title

    duration = 0
    if args.duration != None:
        duration = int(args.duration)

    output = args.output

    # Get header
    xml = get_header({
        "title"       : title,
        "link"        : url,
        "copyright"   : "",
        "subtitle"    : "",
        "author"      : "",
        "summary"     : "",
        "description" : "",
        "name"        : "",
        "email"       : "",
        "image"       : os.path.join(url, "image.png"),
    })

    # Get data folder path
    data_path = os.path.join(src, "data/")

    # Rotate data files
    rotate(data_path)

    files = os.listdir(data_path)
    files.sort(reverse=True)
    for f in files:
        path      = os.path.join(data_path, f)
        name, ext = os.path.splitext(f)
        data_url  = os.path.join(url, "data/" + f)
        # Make item
        items = {
            "title"    : name,
            "author"   : "",
            "subtitle" : "",
            "summary"  : "",
            "image"    : "",
            "url"      : data_url,
            "length"   : os.path.getsize(path),
            "guid"     : data_url,
            "date"     : datetime.fromtimestamp(os.path.getctime(path)).strftime("%a, %d %b %Y %H:%M:%S +0900"),
            "duration" : "%2d:%02d" % (duration / 60, duration % 60),
        }
        if TYPES.has_key(ext):
            items["type"] = TYPES[ext]
        else:
            continue
        xml += get_item(items)

    # Get footer
    xml += get_footer()

    # Output
    if output != None:
        # xml
        with open(output, "w") as f:
            f.write(xml)
    else:
        # std
        print xml

def get_header(items):
    return string.Template(HEADER).safe_substitute(
        title       = items["title"],
        link        = items["link"],
        copyright   = items["copyright"],
        subtitle    = items["subtitle"],
        author      = items["author"],
        summary     = items["summary"],
        description = items["description"],
        name        = items["name"],
        email       = items["email"],
        image       = items["image"],
    )

def get_item(items):
    return string.Template(ITEM).safe_substitute(
        title    = items["title"],
        author   = items["author"],
        subtitle = items["subtitle"],
        summary  = items["summary"],
        image    = items["image"],
        url      = items["url"],
        length   = items["length"],
        type     = items["type"],
        guid     = items["guid"],
        date     = items["date"],
        duration = items["duration"],
    )

def get_footer():
    return FOOTER

def rotate(path):
    files = os.listdir(path)
    files.sort(reverse=True)
    for f in files[10:]:
        os.remove(os.path.join(path, f))

if __name__ == "__main__":
    main()

