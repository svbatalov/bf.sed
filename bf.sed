#!/bin/sed -rf
# BF interpreter. Inspired by Greg Ubben's awful dc.sed.
# Supported commands: <>+-[].
# `.' and `,' supported via system (e command). GNU sed only.
# 

# remove comments
s/[^][,.<>+-]//g

### Optimizations
# replace [-] by Z -- reset current memory cell to zero
s/\[-\]/Z/g

b no_opt

# Match symmetrical patterns like [->>>+<<<] => MZ>>>I<<<
# Append lookup table. Allow up to ten ><'s
s/$/?>>>>>>>>>>;>>>>>>>>>><<<<<<<<<</
# [->+<]
: reduce_incr_right
s/\[-(>+)\+(<+)\]((.*\?)\1(.+);\5.{10}\2)/MZ\1I\2\3/
t reduce_incr_right
# [->-<]
: reduce_decr_right
s/\[-(>+)\-(<+)\]((.*\?)\1(.+);\5.{10}\2)/MZ\1D\2\3/
t reduce_decr_right
s/\?.*$//

# the same for [-<+>] => M<I>
s/$/?<<<<<<<<<<;<<<<<<<<<<>>>>>>>>>>/
: reduce_incr_left
s/\[-(<+)\+(>+)\]((.*\?)\1(.+);\5.{10}\2)/MZ\1I\2\3/
t reduce_incr_left
: reduce_decr_left
s/\[-(<+)\-(>+)\]((.*\?)\1(.+);\5.{10}\2)/MZ\1D\2\3/
t reduce_decr_left
s/\?.*$//

: no_opt

# Add program and expression pointers.
# Expression pointer `|' needed due to
# lack of lazy regular expressions.
# It also allows to remove already evaluated parts of a program.
s/^/%|/
# Prepare the "memory". one cell initially
s/$/;:0,/


# Main loop
: next

#l180

# Remove already evaluated loops
# because we never get there again.
# e.g.: p[.. pp[]pp ..]p %|[] => %|[]
s/.*\]p %\|/%|/

# Remove already evaluated code without loops
# e.g.:  +++.%|[->+<];... => %|[->+<];...
s/.*(%\|)/\1/

# Program end
/%\|;/b

# Mark matching parentheses in first independent subexpression
# so we can jump freely inside this subexpression.
# e.g.: %|[..[]..] [] => % p[.. pp[]pp ..]p |[]
/%\|/b mark_brackets

### Process BF commands

# `.' Print current memory cell. Uses `e' command -- GNU sed only, and bash.
/%\./ {
	h
	#s/.*:([0-9]+),.*/\1/
	s/.*:([0-9]+),.*/bash -c 'printf "\\x$(printf %x \1)"'/; e
	p
	x
	b step
}
# `,' Read one character and put its ascii code to the current memory cell.
# Uses `e' command -- GNU sed only, and bash.
/%,/ {
	# advance program pointer
	s/%([^;])/\1%/
	x
	s/.*/bash -c 'c=0; read -n1 c; printf %d \\"$c'/; e
	b put_to_memory
}
# `>' Move right in memory.
/%>/ {
	# add memory cell
	/:[0-9]+,$/ s/([^:]*):([0-9]+),$/\1\2,:0,/
	# .. or move to already "allocated" one
	s/([^:]*):([0-9]+),(.+)$/\1\2,:\3/
	b step
}

# `<' Move left in memory.
/%</ {
	s/([0-9]+),:(.*)$/:\1,\2/
	b step
}
# `+' Increment current memory cell.
/%\+/ {
	# advance program pointer
	s/%([^;])/\1%/
	h
	s/.*:([0-9]+),.*/\1/
	b incr
}

# `-' Decrement current memory cell.
/%-/ {
	# advance program pointer
	s/%([^;])/\1%/
	h
	s/.*:([0-9]+),.*/\1/
	b decr
}

# `[' Start loop.
/% p+\[/ {
	# If current memory cell is zero -- jump to next `]'.
	#/:0,/s/% (p+)\[(.*)\]\1 / \1[\2]\1 %/
	# Ugly hack due to lack of lazy regexps.
	# May nullify advantages of enumerating of brackets.
	/:0,/ {
		: mark
		s/% (p+)\[(.*)\]\1 /% \1[\2]@\1 /
		t mark
		s/%//
		s/@([^@ ]+) /\1 %/
		s/\@//g
	}
	# advance program pointer otherwise
	/:0,/!s/% (p+)\[(.*) / \1[%\2 /
b next
}

# `]' End loop.
/%\]p+ / {
	# go forward if zero
	/:0,/s/%(\]p+ )/\1%/
	# jump back if current memory cell is not zero
	/:0,/!s/(.*) (p+)\[(.*)%\]\2 /\1% \2[\3]\2 /
b next
}

### Process metacommands
# Reset current memory cell to zero
/%Z/ {
	s/:([0-9]+)/:0/
	b step
}

# Remember current memory cell
/%M/ {
	s/(.*:)([0-9]+)/\2~\1\2/
	b step
}

# Add to current memory cell number remembered with M
/%I/ {
	# if memory cell empty
	s/([0-9]+)~(.*:)0,/\2\1/
	# otherwise -- add
	#s/([0-9]+)~(.*:)([0-9]),/\2\1/
}

b
# End of main loop

### Auxiliary "functions"

# advance program pointer
: step
	s/%([^;])/\1%/
t next

# Increment a number in pattern space and place
# the result into "memory"
: incr
	# replace all leading 9s by _ (any other char except digits, could be used)
	: incr_loop
	s/9(_*)$/_\1/
	t incr_loop

	# if there aren't any digits left, add a MostSign Digit 0
	s/^(_*)$/0\1/

	# incr last digit
	s/$/;0123456789/
	s/([0-8])(_*);.*\1(.).*/\3\2/
	# replace all _ to 0s
	s/_/0/g
b put_to_memory
# end of incr.

# Decrement a number in pattern space and place
# the result into "memory"
: decr
	/^0$/b decr_end
	: decr_loop
	s/0(_*)$/_\1/
	t decr_loop
	# decr last digit
	s/$/;9876543210/
	s/([1-9])(_*);.*\1(.).*/\3\2/

	s/_/9/g
	# remove leading zeros
	s/^0+([^0])/\1/

	: decr_end
b put_to_memory
# end of decr.
	
# pattern space: number
# hold space:    program state
# put the number in pattern space into current memory cell
# and reset hold space
: put_to_memory
	x
	G
	s/:[0-9]+(,.*)\n([0-9]+)/:\2\1/
	# clear hold space
	x; s/^.*$//; x
b next

# Enumerate matching brackets in first subexpression
# Uses hold space to remember nesting level
# May be optimized.
# e.g.: |[[]] [] =>  p[ pp[]pp ]p |[]
# Space used to eliminate unsertainty like in ][ => ]pp[.
# It is ]pp and [ or ]p and p[?
: mark_brackets
# p -- parenthesis
# we are about to loop
/\|\[/ {
# increase nesting level
x
s/(p*)/\1p/
x
G
# add space and nesting level to the `[' bracket
s/\|\[(.*)\n(p+)/ \2|[\1/
}

/\|\]/ {
# add nesting level and space to the `]' bracket
G
s/\|\](.*)\n(.*)/|]\2 \1/
x
# decrease nesting level
s/(p*)p/\1/
x
}

# advance expression marker
s/\|([^;])/\1|/

#/\|;/ {
#	# if we still inside brackets, read next line of input
#	G
#	N
#	/\n.+$/ {
#	s/\|;([^\n]*)\n[^\n]*\n([^\n]*)/|\2{;}\1/
#	}
#}

# do not mark next independent subexpression yet
/\]p \|/b mark_brackets_end

t mark_brackets

: mark_brackets_end
# clear hold space
x;s/^.*$//;x
b next
