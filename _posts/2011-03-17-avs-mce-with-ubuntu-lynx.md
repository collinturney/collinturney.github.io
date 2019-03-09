---
layout: post
title:  "AVS MCE Remote (HA-IR01SV) with Ubuntu Lynx"
date:   2011-03-17 03:19:23 -0600
categories: linux kernel remote ubuntu migrated-posts
---

So, I purchased a piece of hardware that as best I could tell would work with Ubuntu right out of the box but that didn't turn out to be the case. The hardware was a MCE remote made by AVS (HA-IR01SV) and I found it for only $20. The problem was that I could get no output from irw while pressing keys on the remote, '/dev/lirc0' did not exist, and I got nothing descriptive from the kernel logs when plugging in the IR receiver.

    [570159.523784] usb 4-2: new full speed USB device using ohci_hcd and address 9
    [570159.760275] usb 4-2: configuration #1 chosen from 1 choice

It appeared that the drivers that were supposed to be very well informed of my IR receiver had no idea what it was. Google verified this and the solution was to add the vendor and product ID combination to the lirc_mceusb kernel module so that it would recognize the receiver. Running 'lsusb' showed me the vendor and product IDs for the receiver.

    # lsusb
    Bus 004 Device 014: ID 1784:0011 TopSeed Technology Corp.
    Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 003 Device 002: ID 1241:f767 Belkin
    Bus 003 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

So '0x1784' is the product identifier for TopSeed Technology Corp. and '0x0011' is the identifier for this specific receiver. What follows are instructions on how to proceed with adding these IDs to the kernel module.

First, stop lirc.

    # /etc/init.d/lirc stop

Install the source code for the lirc kernel modules.

    # apt-get install lirc-modules-source

Open the lirc_mceusb kernel module source.

    # vim /usr/src/lirc-0.8.6/drivers/lirc_mceusb/lirc_mceusb.c

The Topseed vendor ID already existed in the driver for me.

    #define VENDOR_TOPSEED          0x1784

So basically I just created an entry like the others in 'mceusb_dev_table[]' and in 'transmitter_mask_list[]' with a product ID of '0x0011'.

    186a187,188
    >       /* Topseed eHome Infrared Transceiver */
    >       { USB_DEVICE(VENDOR_TOPSEED, 0x0011) },
    247a250
    >       { USB_DEVICE(VENDOR_TOPSEED, 0x0011) },

Now that the change has been made it needs to be built, installed, and loaded into the kernel. First, remove the existing LIRC kernel module builds just to be safe. You may need to change '0.8.6' to your current version.

    # dkms remove -m lirc -v 0.8.6 --all

Next, add the sources back in for building.

    # dkms add -m lirc -v 0.8.6

Build and install them.

    # dkms -m lirc -v 0.8.6 build
    # dkms -m lirc -v 0.8.6 install

Now unload the previous version of lirc_mceusb and load the newly built one by starting lirc.

    # rmmod lirc_mceusb
    # /etc/init.d/lirc start

After doing this, I could see that '/dev/lirc0' was there.

    # ls -l /dev/lirc*
    crw-rw---- 1 root root 61, 0 2010-12-29 18:03 /dev/lirc0
    lrwxrwxrwx 1 root root    19 2010-12-29 18:03 /dev/lircd -> /var/run/lirc/lircd

Removing and re-plugging the receiver showed me that the kernel module was now recognizing my receiver.

    [578268.770034] usb 4-2: new full speed USB device using ohci_hcd and address 14
    [578269.009272] usb 4-2: configuration #1 chosen from 1 choice
    [578269.200034] usb 4-2: reset full speed USB device using ohci_hcd and address 14
    [578269.421023] lirc_dev: lirc_register_driver: sample_rate: 0
    [578269.427058] lirc_mceusb[14]: Topseed Technology Corp. eHome Infrared Transceiver on usb4:14

Also, 'irw' now generates output from remote key presses.

    # irw
    000000037ff07be7 00 Pause mceusb
    000000037ff07be7 01 Pause mceusb
    000000037ff07be7 02 Pause mceusb
    000000037ff07be9 00 Play mceusb
    000000037ff07be9 01 Play mceusb
    000000037ff07be9 02 Play mceusb
    000000037ff07be9 03 Play mceusb
    000000037ff07be9 04 Play mceusb
    000000037ff07be9 00 Play mceusb
    000000037ff07be9 01 Play mceusb
    000000037ff07be9 02 Play mceusb

At this point I was able to fire up XBMC and all of the important navigation and playback control functions just worked. I'll need to do some tweaking in the future to have everything mapped out perfectly. However, right now I'm just happy to be able to do about 95% of what I could do with the wireless keyboard from just the remote control.

