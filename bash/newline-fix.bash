# newline-fix.bash: Force the bash prompt to start after a newline
# http://snippets.scripts.mit.edu/gitweb.cgi/.git/blob/HEAD:/bash/newline-fix.bash
#
# Some commands don’t print a newline at the end of their output, or
# take long enough to return that you’ve already typed part of the
# next command.  Either causes bash to start its prompt in the middle
# of a line, which confuses it.  This script sets $PROMPT_COMMAND to
# echo a magic sequence of terminal commands that will display a red
# “<no LF>\n” before the prompt if it would otherwise start in the
# middle of a line.
#
# Copyright © 2010 Anders Kaseorg <andersk@mit.edu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# Usage: Source this file from your ~/.bashrc.

show_no_lf () {
    tput -S <<NOLF && echo -n '<no LF>' && \
    tput -S <<SPSP && echo -n '  ' && \
    tput -S <<EOF
sc
tbc
cr
cuf 8
hts
rc
setaf 1
rev
NOLF
sgr0
ht
sc
tbc
cr
$(for ((i=8; i<=320; i+=8)); do echo cuf 8; echo hts; done)
rc
SPSP
cr
el
EOF
}

show_no_lf="$(show_no_lf)" && \
PROMPT_COMMAND="echo -n \"\$show_no_lf\" >&2;$PROMPT_COMMAND"
