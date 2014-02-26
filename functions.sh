R="$(tput setaf 1)"
G="$(tput setaf 2)"
Y="$(tput setaf 3)"
N="$(tput sgr0)"

error(){
    echo >&2 "${R}Error:${N} $@"
    exit -1
}

warn(){
    echo >&2 "${Y}Warning:${N} $@"
}

