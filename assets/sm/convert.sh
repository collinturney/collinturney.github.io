#!/bin/bash

for i in *.jpg; do
        echo "Generating thumbnail for $i ... "
	#convert ${i} \
	#    -bordercolor snow \
	#    -background  black  \( +clone -shadow 60x4+4+4 \) +swap \
	#    +polaroid \
	#    -resize 120 \
	#    ${i}_thumb.png
	
	#convert $i \
        #  -bordercolor white \
        #  -bordercolor snow -border 1 \
        #  -background  none \
        #  -background  black  \( +clone -shadow 60x4+4+4 \) +swap \
        #  -background  none   -flatten \
	#  -resize 150 \
	#  +polaroid \
        #  ${i}_thumb.png
	
	convert $i \
	   -thumbnail 130x130 \
	   -bordercolor white \
	   -background grey75 \
           +polaroid \
	   ${i}_thumb.png
done
