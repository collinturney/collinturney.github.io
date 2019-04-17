#!/bin/bash

SRC_DIR=$1
DST_DIR=$2

if [ $# != 2 ]; then
   echo "Usage: $0 SRC_DIR DST_DIR"
   exit 1
fi

for img in ${SRC_DIR}/*.jpg; do
    name="$(basename -- $img)"

    echo "Resizing '$img' ... "
	
	 convert $img \
      -auto-orient \
	   -resize 960x960 \
      -quality 95 \
	   ${DST_DIR}/${name}

    echo "Thumbnailing '$img' ... "

    convert $img \
       -auto-orient \
       -thumbnail 130x130 \
       -bordercolor white \
       -background grey75 \
       +polaroid \
       ${DST_DIR}/${name}_thumb.png
done
