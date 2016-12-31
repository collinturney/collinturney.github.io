---
layout: post
title:  "Dynamic to Static Binaries"
date:   2016-12-18 19:08:13 -0600
categories: gcc statifier qrencode binary
---
Every now and then it can be very handy to take a dynamically linked binary and make it static. This can make for something that is highly portable and depends on nothing else. One common tool that is used is something called [statifier](http://statifier.sourceforge.net). Statifier goes back a long time but still can be useful after you overcome a couple issues that occur on a modern Linux system. It's basically rewriting all of the dynamic dependencies in a single ELF binary.

In order to compile statifier like the README mentions, you'll want to install the g++-multilib package in order to compile and run 32-bit applications on a modern 64-bit system.

	collin@thinkpad ~ $ sudo apt instal g++-multilib

Once that is done, you'll be able to extract, make, and make install statifier as you would expect... That's about as far as your luck will take you though. Actually running statifier to generate a static executable will give you a nice fresh core dump instead.

	collin@thinkpad ~/qrencode-3.4.4/.libs $ statifier ./qrencode ./qrencode-static
	collin@thinkpad ~/qrencode-3.4.4/.libs $ ./qrencode-static 
	Segmentation fault (core dumped)

In order to fix this we need to disable address space randomization. This will allow statifier to generate a coherent ELF binary.

	collin@thinkpad ~ $ cat /proc/sys/kernel/randomize_va_space
	2

	collin@thinkpad ~ $ echo -n 0 >/proc/sys/kernel/randomize_va_space

Now, statifier can be run without cores.

	collin@thinkpad ~/qrencode-3.4.4/.libs $ statifier ./qrencode qrencode-static

	collin@thinkpad ~/qrencode-3.4.4/.libs $ ldd ./qrencode-static 
	not a dynamic executable

That's what we want.. But does it work?

	collin@thinkpad ~/qrencode-3.4.4/.libs $ ./qrencode-static -h
	qrencode version 3.4.4
	Copyright (C) 2006-2012 Kentaro Fukuchi
	Usage: qrencode [OPTION]... [STRING]
	Encode input data in a QR Code and save as a PNG or EPS image.

Good. Now, re-enable randomization again immediately before you are the victim of a primitive [buffer overflow](https://www.youtube.com/watch?v=1S0aBV-Waeo) attack.

	collin@thinkpad ~ $ echo -n 2 >/proc/sys/kernel/randomize_va_space

