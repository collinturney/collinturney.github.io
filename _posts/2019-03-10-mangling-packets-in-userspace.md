---
layout: post
title:  "Mangling Packets in Userspace"
date:   2019-03-10 14:07:00 -0600
categories: linux kernel nfqueue netfilter ids ips snort
---

Some time ago I became interested in the kernel mechanism that the [Snort IDPS](https://www.snort.org) can utilize to defer packet verdicts over to userspace. It can be extremely useful to be able to intercept and modify network traffic in realtime. Snort uses this ability to actively prevent exploits from running against a target host by disabling the payload.

This definitely has uses outside of active intrusion prevention. For example, an IoT device that could potentially leak sensitive information could transparently have its network traffic restricted to only the bare minimum that is required for it to function. Since you have control over the verdict and ultimately the mangled output, anything is possible.

Snort utilizes libnetfilter_queue in order to hook into the kernel and really any user space program can do the same. When packets arrive in raw form, the APIs allow it to be accepted as is or rejected. When the verdict is set to accept, a raw packet may also be provided in place of the original. This is what really gets us to something useful.

To demonstrate this I built a [proof of concept](https://www.github.com/collinturney/nfqueue_poc). In the example below, libtins is used to change the simple UDP payload in the following example to "Mangled!!!", regardless of what was actually received by our userspace code. The libtins library also generates a proper checksum of the outgoing packet since packets without a valid checksum won't make it through the kernel's IP stack.

![nfqueue]({{ site.base_url }}/static/images/2019/nfqueue_poc.png)

## Building

In order to build the example, you'll need the following packages available to you in some form. These should be available on just about any distribution but the following package names are used in Debian Stretch.

- libmnl-dev
- libnfnetlink-dev
- libnetfilter-queue-dev
- libtins-dev
- libpcap-dev

A simple Makefile is included:

    collin@thinkpad:~/nfqueue$ make
    g++ -g -c nfqueue.cpp -std=c++11
    g++ -g -lnetfilter_queue -ltins -std=c++11 -o nfqueue nfqueue.o

## Running

The nfnetlink kernel modules will need to be loaded in order for packets to be queued into the userspace API.

    collin@thinkpad:~/nfqueue$ sudo modprobe nfnetlink
    collin@thinkpad:~/nfqueue$ sudo modprobe nfnetlink_queue

Next, an iptables rule must be created with the queue numbers that our userspace program will bind to. In this case, we're balancing aross 4 queues and fanning out to multiple CPUs. This can be a handy way to scale to a higher volume of incoming traffic by balancing across several queues in parallel.

    root@thinkpad:~/nfqueue# iptables -A INPUT \
       -p udp \
       --dport 6000 \
       -j NFQUEUE \
       --queue-balance 0:3 \
       --queue-bypass \
       --queue-cpu-fanout

Note: You can also specify a single queue using the '--queue-num' argument.

Finally, run the nfqueue target must be run as root in order to create a nfqueue handle.

    root@thinkpad:/home/collin/nfqueue# ./nfqueue
    Creating nfqueue handle
    Binding handle to queue '0'
    Got UDP packet (sport=59286 dport=6000 length=12 checksum=42972)
    payload=[foo
    ]
    Modified UDP packet (sport=59286 dport=6000 length=18 checksum=53209)
    payload=[Mangled!!!]
