#!/bin/sed -rf

s/^/%/
:a
# p -- parenthesis
/%\[/ {
x
s/(p*)/\1p/
x
G
s/%\[(.*)\n(p+)/\2%[\1/
y/p/s/
}

/%\]/ {
G
s/%\](.*)\n(.*)/%]\2\1/
x
s/(p*)p/\1/
x
y/p/e/
}

s/%(.)/\1%/
ta
x;z;x
