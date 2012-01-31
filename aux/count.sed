#!/bin/sed -f
#  wc.sed - count lines, words, and characters in a text file
#  Written by Greg Ubben on 25 March 1989

1{
        x
        s/^/hgfedcba/
        s/.*/,&,&;&/
        x
}
s/^/ /
H
s/./a/g
H
g
s/[     ]\{1,\}[^       - ]\{1,\}/a/g
s/\(;[a-z]*\).\(a*\)/\2\1/
s/[     - ]//g
s/a/aa/
:a
        s/\(.\)\(.\)\2\2\2\2\2\2\2\2\2\2/\1\1\2/
ta
h
$!d
s/\([a-z]\)\1\1\1\1\1\1\1\1\1/9/g
s/\([a-z]\)\1\1\1\1\1\1\1\1/8/g
s/\([a-z]\)\1\1\1\1\1\1\1/7/g
s/\([a-z]\)\1\1\1\1\1\1/6/g
s/\([a-z]\)\1\1\1\1\1/5/g
s/\([a-z]\)\1\1\1\1/4/g
s/\([a-z]\)\1\1\1/3/g
s/\([a-z]\)\1\1/2/g
s/\([a-z]\)\1/1/g
s/\([a-z]\)/0/g
s/[,;]0*\([0-9]\)/ \1/g
s/ //
