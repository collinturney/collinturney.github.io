---
layout: post
title:  "HDHomeRun CLI"
date:   2016-01-03 18:17:43 -0600
categories: hdhomerun python tv cli
---
I really don't like paying for overpriced TV packages when we don't really watch much anyway. We're pretty much streaming everything these days. However, you can't stream local channels very well just yet. This prompted me to buy a HDHomeRun years ago and it has been great. I can simply run VLC on any device in the house and watch live TV. This really comes in handy when my son is watching Curious George on the living room TV and my wife and I happen to want to check out the local news for a couple minutes.

VLC works great on Linux, but I am a command line junkie. There aren't really any decent Linux tools for browsing, watching, and recording TV from my HDHomeRun. The following Python script allows me to list the available channels and browse without ever touching a mouse.

Recording PVR style is just a matter of redirecting this MPEG over HTTP stream to disk. This really comes in handy for recording hte local news every night, for example. I currently have this running via cron at 10pm every night and overwriting last week's showings. It's simple, it works, and I don't have to pay some provider an inflated cost to have it.

## View and Browse

### Usage

    $ ./watch.py -h
    usage: watch.py [-h] [-u URL] [-c CHANNEL] [-l]

    optional arguments:
      -h, --help            show this help message and exit
      -u URL, --url URL
      -c CHANNEL, --channel CHANNEL
      -l, --list-channels

### Examples

Export the channel lineup URL:

    $ export HDHR_HOST="10.10.1.100"

List lineup data:

    $ watch.py -l
    2.1,KETS-1,http://10.10.1.100:5004/auto/v2.1
    2.2,KETS-2,http://10.10.1.100:5004/auto/v2.2
    2.3,KETS-3,http://10.10.1.100:5004/auto/v2.3
    2.4,KETS-4,http://10.10.1.100:5004/auto/v2.4
    4.1,KARK-DT,http://10.10.1.100:5004/auto/v4.1
    7.1,KATV-HD,http://10.10.1.100:5004/auto/v7.1
    7.2,RTV,http://10.10.1.100:5004/auto/v7.2
    7.3,GRIT,http://10.10.1.100:5004/auto/v7.3
    11.1,KTHV-DT,http://10.10.1.100:5004/auto/v11.1
    11.2,THV2,http://10.10.1.100:5004/auto/v11.2
    11.3,Justice,http://10.10.1.100:5004/auto/v11.3
    16.1,KLRT-DT,http://10.10.1.100:5004/auto/v16.1
    20.1,KLRA-CD,http://10.10.1.100:5004/auto/v20.1
    30.1,KKYK-CD,http://10.10.1.100:5004/auto/v30.1
    30.2,KKYK-CD,http://10.10.1.100:5004/auto/v30.2
    30.3,KKYK-CD,http://10.10.1.100:5004/auto/v30.3
    30.4,KKYK-CD,http://10.10.1.100:5004/auto/v30.4
    36.1,KKAP-DT,http://10.10.1.100:5004/auto/v36.1
    38.1,KASN-HD,http://10.10.1.100:5004/auto/v38.1
    42.1,KARZ-DT,http://10.10.1.100:5004/auto/v42.1
    42.2,BOUNCE,http://10.10.1.100:5004/auto/v42.2
    49.1,KMYA-DT,http://10.10.1.100:5004/auto/v49.1
 
View channel 7.1 using VLC:

    $ watch.py -c 7.1

## Code

{% highlight python linenos %}
#!/usr/bin/env python

import argparse
import json
import os
import requests
import subprocess
import sys
from urllib.parse import urlunparse


def lineup_url(options):
    scheme = 'http'
    netloc = options.hostname or os.environ.get('HDHR_HOST')
    path = '/lineup.json'
    params = ''
    query = ''
    fragment = ''

    if not netloc:
        print("HDHR_HOST environment variable undefined.")
        print("    (e.g., export HDHR_HOST='10.10.1.100')\n")
        sys.exit(2)

    return urlunparse((scheme, netloc, path, params, query, fragment))

def print_lineup(lineup):
    for channel in lineup:
        print("{GuideNumber},{GuideName},{URL}".format(**channel))

def watch_channel(lineup, target):
    for channel in lineup:
        if channel['GuideNumber'] == target:
            playlist = [channel['URL'] for channel in lineup]
            subprocess.call(['vlc', channel['URL']] + playlist)
            break
    else:
        print("Channel '%s' not found in lineup" % target)

def main(args=None):
    args = args or sys.argv[1:]

    parser = argparse.ArgumentParser()

    def configure(args):
        parser.add_argument('-H', '--hostname')
        parser.add_argument('-c', '--channel')
        parser.add_argument('-l', '--list-channels', action='store_true')

        return parser.parse_args(args)

    options = configure(args)

    response = requests.get(lineup_url(options), timeout=3.00)
    lineup = json.loads(response.text)

    if options.list_channels:
        print_lineup(lineup)
        return 0
    elif options.channel:
        watch_channel(lineup, options.channel)
        return 0
    else:
        parser.print_help()
        return 2

if __name__ == "__main__":
    sys.exit(main())
{% endhighlight %}

## Record

### Usage

    $ record.py -h
    usage: record.py [-h] [-u URL] [-o OUTPUT_FILE] [-m MINUTES]

    optional arguments:
      -h, --help            show this help message and exit
      -u URL, --url URL
      -o OUTPUT_FILE, --output-file OUTPUT_FILE
      -m MINUTES, --minutes MINUTES

### Examples

Record channel 11.1 for 30 minutes:

    $ record.py -c 11.1 -o output.mpg -m 30

Record the nightly news:

    HDHR_HOST=10.10.1.100

    30 17 * * * record.py -c 7.1 -o news.mpg -m 30

## Code

{% highlight python linenos %}
#!/usr/bin/env python

import argparse
import os
import requests
import signal
import sys
import time
from urllib.parse import urlunparse

def channel_url(options):
    scheme = 'http'
    netloc = options.hostname or os.environ.get('HDHR_HOST')
    path = '/auto/v' + options.channel
    params = ''
    query = ''
    fragment = ''

    if not netloc:
        print("HDHR_HOST environment variable undefined.")
        print("    (e.g., export HDHR_HOST='10.10.1.100')\n")
        sys.exit(2)

    netloc += ":5004"

    return urlunparse((scheme, netloc, path, params, query, fragment))

def main(args=None):
    args = args or sys.argv[1:]

    parser = argparse.ArgumentParser()

    def configure(args):
        parser.add_argument("-H", "--hostname")
        parser.add_argument("-c", "--channel")
        parser.add_argument("-o", "--output-file")
        parser.add_argument("-m", "--minutes", type=int)

        return parser.parse_args(args)

    options = configure(args)

    done = False

    def handler(signum, frame):
        nonlocal done
        done = True
    
    signal.signal(signal.SIGALRM, handler)
    signal.signal(signal.SIGTERM, handler)
    signal.signal(signal.SIGINT, handler)

    signal.alarm(options.minutes * 60)

    url = channel_url(options)

    print("Recording", url, "...")

    response = requests.get(url, stream=True, timeout=3.00)
    response.raise_for_status()

    with open(options.output_file, 'wb') as fd:
        for chunk in response.iter_content(1 * 1024 * 1024):
            if done: break
            fd.write(chunk)

    response.close()

    return 0

if __name__ == "__main__":
    sys.exit(main())
{% endhighlight %}
