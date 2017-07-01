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

function glob-alias() {
  if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
    zle _expand_alias
    zle expand-word
  fi
  zle self-insert
}
# Keybinds for emacs and vi insert mode
for keymap in 'emacs' 'viins'; do
  # control-space expands all aliases, including global
  bindkey -M "$keymap" " " glob-alias
  bindkey -M "$keymap" "$key_info[Control] " magic-space
done

open-widget() {
  [[ -z $BUFFER ]] && zle up-history
  [[ $BUFFER != o\ * ]] && LBUFFER="o $LBUFFER"
  zle accept-line
}
zle -N open-widget
bindkey "^O" open-widget

man-widget() {
  [[ -z $BUFFER ]] && zle up-history
  [[ $BUFFER != man\ * ]] && LBUFFER="man $LBUFFER"
  zle accept-line
}
zle -N man-widget
bindkey "^H" man-widget
