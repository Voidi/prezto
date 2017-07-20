#
# Defines Overwrites for other prezto modules.
#
# Authors:
#   Tobias Wohlfarth <tobias.wohlfarth@googlemail.com>
#

# Editor: Inserts '_ ' (alias for sudo) at the beginning of the line.
sudoalias=$(alias | grep "=sudo" | head -n 1 | sed 's/=sudo//g')
function prepend-sudo {
  if [[ "$BUFFER" != su(do|)\ * ]]; then
    BUFFER="$sudoalias $BUFFER"
    (( CURSOR += 2 ))
  fi
}
zle -N prepend-sudo

# Undo.
bindkey "^Z" undo

# Redo.
bindkey "^Y" redo
