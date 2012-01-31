#!/bin/sed -f

# replace all leading 9s by _ (any other char except digits, could be used)
#
:d
s/9\(_*\)$/_\1/
td

# if there aren't any digits left, add a MostSign Digit 0
#
s/^\(_*\)$/0\1/

# incr last digit only - there is no need for more
#
s/$/;0123456789/
s/\([0-8]\)\(_*\);.*\1\(.\).*/\3\2/

# replace all _ to 0s
#
s/_/0/g

