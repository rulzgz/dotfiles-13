# Inspired by:
#   https://github.com/dreadatour/dotfiles/blob/master/.bash_profile

# Setup color variables
color_is_on=
color_red=
color_green=
color_yellow=
color_blue=
color_white=
color_gray=
color_bg_red=
color_off=
color_user=
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  color_is_on=true
  color_black="\[$(/usr/bin/tput setaf 0)\]"
  color_red="\[$(/usr/bin/tput setaf 1)\]"
  color_green="\[$(/usr/bin/tput setaf 2)\]"
  color_yellow="\[$(/usr/bin/tput setaf 3)\]"
  color_blue="\[$(/usr/bin/tput setaf 6)\]"
  color_white="\[$(/usr/bin/tput setaf 7)\]"
  color_gray="\[$(/usr/bin/tput setaf 8)\]"
  color_off="\[$(/usr/bin/tput sgr0)\]"

  color_error="$(/usr/bin/tput setab 1)$(/usr/bin/tput setaf 7)"
  color_error_off="$(/usr/bin/tput sgr0)"

  # Set user color
  case `id -u` in
    0) color_user=$color_red ;;
    *) color_user=$color_green ;;
  esac
fi

# Some kind of optimization - check if git installed only on config load
PS1_GIT_BIN=$(which git 2>/dev/null)

function prompt_command {
  local PS1_GIT=
  local GIT_BRANCH=
  local GIT_DIRTY=
  local PWDNAME=$PWD

  # Beautify working directory name
  if [ $HOME == $PWD ]; then
    PWDNAME="~"
  elif [ $HOME == ${PWD:0:${#HOME}} ]; then
    PWDNAME="~${PWD:${#HOME}}"
  fi

  # Parse git status and get git variables
  if [[ ! -z $PS1_GIT_BIN ]]; then
    # Check we are in git repo
    local CUR_DIR=$PWD
    while [[ ! -d "${CUR_DIR}/.git" ]] && [[ ! "${CUR_DIR}" == "/" ]] && [[ ! "${CUR_DIR}" == "~" ]] && [[ ! "${CUR_DIR}" == "" ]]; do CUR_DIR=${CUR_DIR%/*}; done
    if [[ -d "${CUR_DIR}/.git" ]]; then
      # 'git repo for dotfiles' fix: show git status only in home dir and other git repos
      if [[ "${CUR_DIR}" != "${HOME}" ]] || [[ "${PWD}" == "${HOME}" ]]; then
        # get git branch
        GIT_BRANCH=$($PS1_GIT_BIN symbolic-ref HEAD 2>/dev/null)
        if [[ ! -z $GIT_BRANCH ]]; then
          GIT_BRANCH=${GIT_BRANCH#refs/heads/}

          # get git status
          local GIT_STATUS=$($PS1_GIT_BIN status --porcelain 2>/dev/null)
          [[ -n $GIT_STATUS ]] && GIT_DIRTY=1
        fi
      fi
    fi
  fi

  # Build B&W prompt for git
  [[ ! -z $GIT_BRANCH ]] && PS1_GIT=" #${GIT_BRANCH}"

  # Calculate prompt length
  local PS1_length=$((${#USER}+${#HOSTNAME}+${#PWDNAME}+${#PS1_GIT}+3))
  local FILL=

  # Of length is greater, than terminal width
  if [[ $PS1_length -gt $COLUMNS ]]; then
    # strip working directory name
    PWDNAME="...${PWDNAME:$(($PS1_length-$COLUMNS+3))}"
  else
    # else calculate fillsize
    local fillsize=$(($COLUMNS-$PS1_length))
    FILL=$color_gray
    while [[ $fillsize -gt 0 ]]; do FILL="${FILL}─"; fillsize=$(($fillsize-1)); done
    FILL="${FILL}${color_off}"
  fi

  if $color_is_on; then
    # Git status for prompt
    if [ ! -z $GIT_BRANCH ]; then
      if [ -z $GIT_DIRTY ]; then
        PS1_GIT=" #${color_green}${GIT_BRANCH}${color_off}"
      else
        PS1_GIT=" #${color_red}${GIT_BRANCH}${color_off}"
      fi
    fi
  fi

  # Set new color prompt
  PS1="${color_user}${USER}${color_off}@${color_yellow}${HOSTNAME}${color_off}:${color_white}${PWDNAME}${color_off}${PS1_GIT} ${FILL}\n→ "

  # get cursor position and add new line if we're not in first column
  # cool'n'dirty trick (http://stackoverflow.com/a/2575525/1164595)
  # XXX FIXME: this hack broke ssh =(
  # exec < /dev/tty
  # local OLDSTTY=$(stty -g)
  # stty raw -echo min 0
  # echo -en "\033[6n" > /dev/tty && read -sdR CURPOS
  # stty $OLDSTTY
  echo -en "\033[6n" && read -sdR CURPOS
  [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}●${color_error_off}"

  # Terminal title
  TITLE=`basename ${PWDNAME}`
  [ $SHLVL -gt 1 ] && TITLE="${TITLE} — ${HOSTNAME}"
  echo -ne "\033]0;${TITLE}"; echo -ne "\007"
}

# Set prompt command (title update and color prompt)
PROMPT_COMMAND=prompt_command
# Set new B&W prompt (will be overwritten in `prompt_command` later with color prompt)
PS1='\u@\h:\w\$ '
