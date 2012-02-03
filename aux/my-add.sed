#!/bin/sed -rf
# Add two or more positive integers delimited by space
# Author: Batalov Sergey
# Date: Thu Feb  2 16:25:09 YEKT 2012
# Computation performed completely in pattern space.

: start
s/[^0-9 ]//
s/ +/|; /
# lookup table
s/$/#dddddddddd0123456789/
: loop
	/\|;/ s/(.?)\|/|\1/
	s/;(.*):/d;\1/
	s/([0-9]?)\|(.*)([0-9])#/\1|\3\2#/
	: to_analog
	s/([^|]*)([0-9])([;d].*#(.*).{10}\2.*)/\1\4\3/
	t to_analog
	# condition -- just to speed up a little; may be omitted
	/d{10}d*;/ {
		s/d{10}(d*);(.*#\1.{10}(.).*)/;\3\2:/
		t loop
	}
	s/(d*);(.*#\1.{10}(.).*)/;\3\2/

/\|;.* #/!b loop

s/[;\|]//g; s/ ?#.*//

# If we want to sum more than two numbers
/ / b start
