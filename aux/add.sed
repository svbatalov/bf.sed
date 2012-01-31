
 # Add 2 numbers using the stream editor SED
 # 
 # Copyright (C) 2011  Alin C Soare <as1789@gmail.com>
 # 
 #    This program is free software: you can redistribute it and/or modify
 #    it under the terms of the GNU General Public License as published by
 #    the Free Software Foundation, either version 3 of the License, or
 #    (at your option) any later version.
 # 
 #    This program is distributed in the hope that it will be useful,
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #    GNU General Public License for more details.
 # 
 #    You should have received a copy of the GNU General Public License
 #    along with this program.  If not, see <http://www.gnu.org/licenses/>.




# read the second number and replace newline by space
N
s:\n: :

:next-digit

/[[:digit:]]/ {							# START CYCLE

# when the first number is longer than the first, replace the missing
# digits with 0
s:[ ]$: 0:
s:^[ ]:0 :

#  PS should look like this : | NNNX MMMY #XY  |
#  move the last digit of every number at the end of PS
s_\([[:digit:]]*\)\([[:digit:]]\)[ ]\([[:digit:]]*\)\([[:digit:]]\)_\1 \3#\2\4_

# save PS to HS. Keep the old value of HS, as it could contain a '.'
H

# commute to HS
x
# in HS remove all apart from the point of last addition
# [when present]  and the digits to add
s:\(^[.]*\)[^#]*#\(.*\):\1\2:

# in HS replace the digits by points
s:0::g
s:1:.:g
s:2:..:g
s:3:...:g
s:4:....:g
s:5:.....:g
s:6:......:g
s:7:.......:g
s:8:........:g
s:9:.........:g

# if there are more than 10 points, we must keep 1 point for the next
# cycle
s:[.]\{10\}$:+:

# replace the points with the digit
s:^[.]\{9\}:9:
s:^[.]\{8\}:8:
s:^[.]\{7\}:7:
s:^[.]\{6\}:6:
s:^[.]\{5\}:5:
s:^[.]\{4\}:4:
s:^[.]\{3\}:3:
s:^[.]\{2\}:2:
s:^[.]\{1\}:1:

# START PRINTING

# VOID : PRINT 0
/^$/{
s::0:p
s:.*::
}

# DIGIT: PRINT DIGIT + REMOVE IT
/\([[:digit:]]\)$/ {
p
s:::
}

# if there are more than 10 points, make a sign: 

# Exactly 10 points : PRINT 0 and keep SIGN
/^[+]$/{
s::0:p
s:.*:.:
}

# DIGIT + 10 points: PRINT DIGIT + keep SIGN
/\([[:digit:]]\)[+]/ {
s::\1\n.:
P
s:.*:.:
}

# END PRINTING

# return to PS
x

# remove the last digits
s:\([^#]*\)#.*:\1:

}								# END CYCLE

# next cycle for next pair of digits
t next-digit

x

# When the result has more digits than the longests of 2 numbers,
# the first digit is '1', and print it either
/[.]/ {
s::1:
q
}
