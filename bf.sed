#!/bin/sed -nrf
#e seq 0 5 | xargs printf '\d%.3d'

# remove comments
s/[^][,.<>+-]//g

# add program and expression pointers
s/^/%|/
# prepare the "memory". one cell initially
s/$/;:0,/


: next

l
# remove already evaluated loops
s/.*\]p %\|/%|/
/%\|;/b
/%\|/b mark_brackets

/%\./ {
	h
	s/.*:([0-9]+),.*/\1/
	#s/.*:([0-9]+),.*/bash -c 'printf "\\x$(printf %x \1)"'/; e
	p
	x
	b step
}
# move right memory pointer
/%>/ {
	# add memory cell if necessary
	/:[0-9]+,$/ s/([^:]*):([0-9]+),$/\1\2,:0,/
	s/([^:]*):([0-9]+),(.+)$/\1\2,:\3/
	b step
}

# move left memory pointer
/%</ {
	s/([0-9]+),:(.*)$/:\1,\2/
	b step
}
/%\+/ {
	# advance program pointer
	s/%([^;])/\1%/
	h
	s/.*:([0-9]+),.*/\1/
	b incr
}
/%-/ {
	# advance program pointer
	s/%([^;])/\1%/
	h
	s/.*:([0-9]+),.*/\1/
	b decr
}

/% p+\[/ {
#s/:0/:1/
	# if current memory cell is zero -- jump to next ]
	/:0,/s/% (p+)\[(.*)\]\1 / \1[\2]\1 %/
	# advance program pointer otherwise
	/:0,/!s/% (p+)\[(.*) / \1[%\2 /
b next
}

/%\]p+ / {
	/:0,/s/%(\]p+ )/\1%/
	# jump back if current memory cell is not zero
	/:0,/!s/ (p+)\[(.*)%\]\1 /% \1[\2]\1 /
b next
}

b
# End of main loop

# advance program pointer
: step
s/%([^;])/\1%/
t next

: incr
# replace all leading 9s by _ (any other char except digits, could be used)
: incr_loop
s/9(_*)$/_\1/
t incr_loop

# if there aren't any digits left, add a MostSign Digit 0
s/^(_*)$/0\1/

# incr last digit only - there is no need for more
s/$/;0123456789/
s/([0-8])(_*);.*\1(.).*/\3\2/
# replace all _ to 0s
s/_/0/g
# put the result into memory
x
G
s/:[0-9]+(,.*)\n([0-9]+)/:\2\1/
b next

: decr
/^0$/b decr_end
: decr_loop
s/0(_*)$/_\1/
t decr_loop
# decr last digit only - there is no need for more
s/$/;9876543210/
s/([1-9])(_*);.*\1(.).*/\3\2/

s/_/9/g
s/^0+([^0])/\1/

: decr_end
# put the result into memory
x
G
s/:[0-9]+(,.*)\n([0-9]+)/:\2\1/
b next

# enumerate matching brackets
: mark_brackets
# p -- parenthesis
/\|\[/ {
x
s/(p*)/\1p/
x
G
s/\|\[(.*)\n(p+)/ \2|[\1/
}

/\|\]/ {
G
s/\|\](.*)\n(.*)/|]\2 \1/
x
s/(p*)p/\1/
x
}
# advance expression marker
s/\|([^;])/\1|/
# do not mark next expression
/\]p \|/b mark_brackets_end
t mark_brackets

: mark_brackets_end
x;z;x
b next
