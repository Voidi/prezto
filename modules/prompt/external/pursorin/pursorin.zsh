#
# Pursorin, a Zsh-theme mixed from pure and sorin theme
#
# Authors:
#   Tobias Wohlfarth <tobias.wohlfarth@gogglemail.com>
#

# For my own and others sanity
# git:
# %b => current branch
# %a => current action (rebase/merge)
# prompt:
# %F => color dict
# %f => reset color
# %~ => current path
# %* => time
# %n => username
# %m => shortname host
# %(?..) => prompt conditional - %(condition.true.false)
# terminal codes:
# \e7   => save cursor position
# \e[2A => move cursor 2 lines up
# \e[1G => go to position 1 in terminal
# \e8   => restore cursor position
# \e[K  => clears everything after the cursor on the current line
# \e[2K => clear everything on the current line
#
# 16 Terminal Colors
# -- ---------------
#  0 black
#  1 red
#  2 green
#  3 yellow
#  4 blue
#  5 magenta
#  6 cyan
#  7 white
#  8 bright black
#  9 bright red
# 10 bright green
# 11 bright yellow
# 12 bright blue
# 13 bright magenta
# 14 bright cyan
# 15 bright white
#

PROMPT_SYMBOL="❯ "
ROOT_PROMPT_SYMBOL="⚡"
CMD_EXEC_TIME_SYMBOL="⌛"
SEGMENT_SEPARATOR=":" #"\ue0b0" #▶ #only in powerline patched font
CMD_MAX_EXEC_TIME=3

# Colors
ERROR="red"
SUCCESS="green"
HOST_NAME="136"
USER_NAME="167"
ROOT_NAME="red"
WORKING_DIR="blue"

# Load dependencies.
pmodload 'helper'

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
prompt_human_time_to_var() {
	local human=" " total_seconds=$1 var=$2
	local days=$(( total_seconds / 60 / 60 / 24 ))
	local hours=$(( total_seconds / 60 / 60 % 24 ))
	local minutes=$(( total_seconds / 60 % 60 ))
	local seconds=$(( total_seconds % 60 ))
	(( days > 0 )) && human+="${days}d "
	(( hours > 0 )) && human+="${hours}h "
	(( minutes > 0 )) && human+="${minutes}m "
	human+="${seconds}s"

	# store human readable time in variable as specified by caller
	typeset -g "${var}"="${human}"
}

# stores (into prompt_cmd_exec_time) the exec time of the last command if set threshold was exceeded
prompt_check_cmd_exec_time() {
	integer elapsed
	(( elapsed = EPOCHSECONDS - ${prompt_cmd_timestamp:-$EPOCHSECONDS} ))
	prompt_cmd_exec_time=
	(( elapsed > ${CMD_MAX_EXEC_TIME:=5} )) && {
		prompt_human_time_to_var $elapsed "prompt_cmd_exec_time"
	}
}

function prompt_pursorin_git_info {
	if (( _prompt_pursorin_precmd_async_pid > 0 )); then
	# Append Git status.
	if [[ -s "$_prompt_pursorin_precmd_async_data" ]]; then
		alias typeset='typeset -g'
		source "$_prompt_pursorin_precmd_async_data"
		RPROMPT+='${git_info:+${(e)git_info[status]}}'
		unalias typeset
	fi

	# Reset PID.
	_prompt_pursorin_precmd_async_pid=0

	# Redisplay prompt.
	zle && zle reset-prompt
	fi
}

prompt_set_title() {
	# emacs terminal does not support settings the title
	(( ${+EMACS} )) && return

	# tell the terminal we are setting the title
	print -n '\e]0;'
	# show hostname if connected through ssh
	[[ -n $SSH_CONNECTION ]] && print -Pn '(%m) '
	case $1 in
		expand-prompt)
			print -Pn $2;;
		ignore-escape)
			print -rn $2;;
	esac
	# end set title
	print -n '\a'
}

prompt_preprompt_render() {
	local preprompt=""
	# execution time
	if [[ -n ${prompt_cmd_exec_time} ]]; then
		preprompt+="%F{yellow} ${CMD_EXEC_TIME_SYMBOL}${prompt_cmd_exec_time}%f"
	fi
	# username and machine if applicable
	preprompt+="\n${prompt_username}%{$FG[$HOST_NAME]%}%{$BG[$WORKING_DIR]%}$SEGMENT_SEPARATOR"
	# Path, shortened if under home directory
	preprompt+=%{$BG[$WORKING_DIR]%}%{$FG[253]%}%B%~/%b%f
	# git info
	# preprompt+="${_git_prompt}"

	print -P "${preprompt}"
}
prompt_pursorin_preexec() {
	prompt_cmd_timestamp=$EPOCHSECONDS

	# shows the current dir and executed command in the title while a process is active
	prompt_set_title 'ignore-escape' "$PWD:t: $2"
}

function prompt_pursorin_precmd_async {
	# Get Git repository information.
	if (( $+functions[git-info] )); then
	git-info
	typeset -p git_info >! "$_prompt_pursorin_precmd_async_data"
	fi

	# Signal completion to parent process.
	kill -WINCH $$
}

function prompt_pursorin_precmd {
	setopt LOCAL_OPTIONS
	unsetopt XTRACE KSH_ARRAYS

	# check exec time and store it in a variable
	prompt_check_cmd_exec_time

	# by making sure that prompt_cmd_timestamp is defined here the async functions are prevented from interfering
	# with the initial preprompt rendering
	prompt_cmd_timestamp=

	# shows the full path in the title
	prompt_set_title 'expand-prompt' '%~'

	# Define prompts.
	RPROMPT='${editor_info[overwrite]}%(?.%F{$SUCCESS}%\⏎ %f.%F{$ERROR}%?⏎ %f)${VIM:+" %B%F{6}V%f%b"}'

	# Kill the old process of slow commands if it is still running.
	if (( _prompt_pursorin_precmd_async_pid > 0 )); then
	kill -KILL "$_prompt_pursorin_precmd_async_pid" &>/dev/null
	fi

	# Compute slow commands in the background.
	trap prompt_pursorin_git_info WINCH
	prompt_pursorin_precmd_async &!
	_prompt_pursorin_precmd_async_pid=$!

	# print the preprompt
	prompt_preprompt_render "precmd"

	# remove the prompt_cmd_timestamp, indicating that precmd has completed
	unset prompt_cmd_timestamp
}

function prompt_pursorin_setup {

	# for calculating prompt_cmd_exec_time
	zmodload zsh/datetime

	setopt LOCAL_OPTIONS
	unsetopt XTRACE KSH_ARRAYS
	prompt_opts=(cr percent subst)
	_prompt_pursorin_precmd_async_pid=0
	_prompt_pursorin_precmd_async_data="${TMPPREFIX}-prompt_pursorin_data"

	# Load required functions.
	autoload -Uz add-zsh-hook

	# Add hook for calling git-info before each command.
	add-zsh-hook precmd prompt_pursorin_precmd

	# Add hook for saving start time
	add-zsh-hook preexec prompt_pursorin_preexec

	# Set editor-info parameters.
	zstyle ':prezto:module:editor:info:completing' format '%B%F{white}...%f%b'
	# zstyle ':prezto:module:editor:info:keymap:primary' format ' %B%F{1}❯%F{3}❯%F{2}❯%f%b'
	zstyle ':prezto:module:editor:info:keymap:primary:overwrite' format ' %F{yellow}♺%f'
	# zstyle ':prezto:module:editor:info:keymap:alternate' format ' %B%F{2}❮%F{3}❮%F{1}❮%f%b'

	# Set git-info parameters.
	zstyle ':prezto:module:git:info' verbose 'yes'
	zstyle ':prezto:module:git:info:action' format '%F{white}:%f%%B%F{9}%s%f%%b'
	zstyle ':prezto:module:git:info:added' format ' %%B%F{green}✚%f%%b'
	zstyle ':prezto:module:git:info:ahead' format ' %%B%F{13}⬆%f%%b'
	zstyle ':prezto:module:git:info:behind' format ' %%B%F{13}⬇%f%%b'
	zstyle ':prezto:module:git:info:branch' format ' %%B%F{green}%b%f%%b'
	zstyle ':prezto:module:git:info:commit' format ' %%B%F{yellow}%.7c%f%%b'
	zstyle ':prezto:module:git:info:deleted' format ' %%B%F{red}✖%f%%b'
	zstyle ':prezto:module:git:info:modified' format ' %%B%F{blue}✱%f%b'
	zstyle ':prezto:module:git:info:position' format ' %%B%F{13}%p%f%%b'
	zstyle ':prezto:module:git:info:renamed' format ' %%B%F{magenta}➜%f%%b'
	zstyle ':prezto:module:git:info:stashed' format ' %%B%F{cyan}✭%f%%b'
	zstyle ':prezto:module:git:info:unmerged' format ' %%B%F{yellow}═%f%%b'
	zstyle ':prezto:module:git:info:untracked' format ' %%B%F{white}◼%f%%b'
	zstyle ':prezto:module:git:info:keys' format \
	'status' '$(coalesce "%b" "%p" "%c")%s%A%B%S%a%d%m%r%U%u'

	prompt_username="%{$FG[$USER_NAME]%}%n%f%F{white}@%f%{$FG[$HOST_NAME]%}%m%f"

	if [[ $UID -eq 0 ]]; then
		prompt_username="$FX[bold]%{$FG[default]%}%n%f$FX[no-bold]%F{white}@%f%{$FG[$HOST_NAME]%}%m%f"
		PROMPT_SYMBOL=${ROOT_PROMPT_SYMBOL}
	fi

	# shows current date and time, prompt turns red if the previous command didn't exit with 0
	PROMPT="%D{%d.%m} ⌚ %B%D{%H:%M:%S}%b%(?.%F{$SUCCESS}.%F{$ERROR})${PROMPT_SYMBOL}%f${editor_info[keymap]}"

	# shows the return code in red if not 0, otherwise green arrow
	RPROMPT=''
	SPROMPT='zsh: correct %F{1}%R%f to %F{2}%r%f [nyae]? '
}

function prompt_pursorin_preview {
	local +h PROMPT=''
	local +h RPROMPT=''
	local +h SPROMPT=''

	editor-info 2>/dev/null
	prompt_preview_theme 'pursorin'
}

prompt_pursorin_setup "$@"
