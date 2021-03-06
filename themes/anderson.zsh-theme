function theme_precmd {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))


    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)---()--}}
    local gitstring="`git_prompt_info`"
    local gitbuff=${#gitstring}
    local symbolString="`git_prompt_status`"
    local symbolSize=${#symbolString}

    CHARGE_STRING="`battery_pct_prompt`"

    if [ "$gitbuff" -eq "0" ] 
      then gitsize=0
      #subtract off a constant for the color codes and status symbol
      else 
        ##The color codes are currently 9 chars long each symbol consists
        #of a space a symbol and a color code so to find the number of
        #symbols divide by 11. Then to get the symbol and space back
        #multiply by two.
        ((symbolSize=($symbolSize * 2) / 11))
        ((gitsize=$gitbuff - (18 - $symbolSize)))
    fi
    local pwdsize=${#${(%):-%~}}

    if [[ "$promptsize + $pwdsize + $gitsize" -gt $TERMWIDTH ]]; then
      ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
      PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $gitsize + $pwdsize)))..${PR_HBAR}.)}"
    fi

    CHRGE_STRING=`battery_pct_prompt`
    if [ -z CHRGE_STRING ]
    then
        CHRGE_STRING="%{$fg[green]%}CHRGE"
    fi

}


setopt extended_glob
theme_preexec () {
    if [[ "$TERM" == "screen" ]]; then
	local CMD=${1[(wr)^(*=*|sudo|-*)]}
	echo -n "\ek$CMD\e\\"
    fi
}


setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
	colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
	eval PR_$color='%{$fg_no_bold[${(L)color}]%}'
	eval PR_LIGHT_$color='%{$fg_bold[${(L)color}]%}'
	(( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"

    ###
    # Modify Git prompt
    ZSH_THEME_GIT_PROMPT_PREFIX=" on %{$fg[green]%}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_DIRTY=""
    ZSH_THEME_GIT_PROMPT_CLEAN=""

    ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} ✚"
    ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} ✹"
    ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✖"
    ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} ➜"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} ═"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} ✭"

    ###
    # See if we can use extended characters to look nicer.

    typeset -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    PR_HBAR=${altchar[q]:--}
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
	xterm*)
	    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
	    ;;
	screen)
	    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
	    ;;
	*)
	    PR_TITLEBAR=''
	    ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
	PR_STITLE=$'%{\ekzsh\e\\%}'
    else
	PR_STITLE=''
    fi


    ###
    # Finally, the prompt.

    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_CYAN$PR_SHIFT_IN$PR_ULCORNER$PR_HBAR$PR_SHIFT_OUT$PR_CYAN(\
$PR_BLUE%$PR_PWDLEN<...<%~%<<$PR_LIGHT_CYAN%{$reset_color%}\
`git_prompt_info``git_prompt_status`$PR_CYAN)$PR_CYAN$PR_SHIFT_IN\
$PR_HBAR$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_SHIFT_OUT$PR_CYAN(\
$PR_MAGENTA%(!.%SROOT%s.%n)$PR_CYAN@$PR_GREEN%m:%l\
$PR_CYAN)$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_URCORNER$PR_SHIFT_OUT\

$PR_CYAN$PR_SHIFT_IN$PR_LLCORNER$PR_CYAN$PR_HBAR$PR_SHIFT_OUT(\
$PR_YELLOW%D{%H:%M:%S}\
$PR_CYAN)$PR_CYAN$PR_SHIFT_IN$PR_HBAR\
$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
>$PR_NO_COLOUR '

    # display exitcode on the right when >0
    return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"

    CHARGE_STRING="`battery_pct_prompt`"
    local chargeLen=${#CHARGE_STRING}

    if [ "$chargeLen" -eq "0" ]
        then RPROMPT=' $return_code$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_CYAN$PR_HBAR$PR_SHIFT_OUT\
($PR_YELLOW%D{%a,%b %d}$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_CYAN$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'
        else RPROMPT=' $return_code$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_CYAN$PR_HBAR$PR_SHIFT_OUT\
($CHARGE_STRING$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_CYAN$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'
    fi
    PS2='$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_LIGHT_GREEN%_$PR_CYAN)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

setprompt

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec
