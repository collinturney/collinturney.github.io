---
layout: post
title:  "Software RAID to the Rescue"
date:   2014-08-16 15:19:13 -0600
categories: raid spinrite backup nas
---
After rsync-ing files for years to achieve some kind of redundancy I finally decided to splurge on a few drives for a RAID5 array. Western Digital 2TB Red drives were marked down to $100. So, three drives would give me a nice 4TB to work with. It was time. However, in the process of shuffling files around the disk in my server died and made the process a lot more complicated to get a single backup of everything. Files were scattered across three drives of different sizes.

I wasn't worried about the dead drive because I had a copy of SpinRite which has saved me on numerous occasions. Unfortunately, this would not be another SpinRite success to add to the list. Every time I attempted to run a level 2 recovery on the crippled drive I would get this lovely message after several hours of churning:

![Spinrite failure]({{ site.baseurl }}/assets/spinrite-failure.jpg){: .center-image}

Isn't that a daisy? It wasn't ideal but I eventually got everything shuffled around without my main backup drive in the loop.

The process of creating the software RAID array could not have been easier. It was just a matter of creating a /dev/md0 device to represent the array of three separate disks:

    collin@newton $ mdadm --create --verbose /dev/md0 --level=5 --raid-devices=3 /dev/sda1 /dev/sdc1 /dev/sdd1

And that was it. I had a new device to format with ext4 and I could already watch the replication building via /proc/mdstat:

    collin@newton $ cat /proc/mdstat
    Personalities : [raid6] [raid5] [raid4]
    md0 : active raid5 sdd1[3] sdc1[1] sda1[0]
          3906765824 blocks super 1.2 level 5, 512k chunk, algorithm 2 [3/2] [UU_]
          [=====>...............]  recovery = 25.6% (500420408/1953382912) finish=188.7min speed=128270K/sec
    
    unused devices: <none>

Once I get my files copied over I'll also begin the long process of backing this all up to CrashPlan. It will probably take several months to get it all uploaded without saturating my upload bandwidth. However, having a full offsite backup would have saved me from some of this pain in the first place.
