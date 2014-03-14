R="$(tput setaf 1)"
G="$(tput setaf 2)"
Y="$(tput setaf 3)"
C="$(tput setaf 6)"
N="$(tput sgr0)"

error(){
    echo >&2 "${R}Error:${N} $@"
    exit -1
}

warn(){
    echo >&2 "${Y}Warning:${N} $@"
}

note(){
    echo >&2 "${C}Note:${N} $@"
}

# Check status of dataset - use this in scripts etc to avoid using incorrect data sets.
validate(){
    D="$1"
    [ -f "$D/meta.xml" ] || error "Couldn't find 'meta.xml', '$D' is not a dataset directory."
    S=$(xmlstarlet sel -t -m /meta -v @status -n "$D/meta.xml")
    echo "$S"
    [ "$S" = "deprecated" ] && error "Dataset '$D' is deprecated!"
    [ "$S" = "superseded" ] && warn "Dataset '$D' is superseded!"
}

# list all files in a dataset
files(){
    D="$1"
    [ -f "$D/meta.xml" ] || error "Couldn't find 'meta.xml', '$D' is not a dataset directory."
    xmlstarlet sel -t -m //file -v @path -n "$D/meta.xml" | grep .
}

# list all files with a given type
files_by_type(){
    D="$1"
    T="$2"
    [ -f "$D/meta.xml" ] || error "Couldn't find 'meta.xml', '$D' is not a dataset directory."
    xmlstarlet sel -t -m "//file[@mimetype='$T']" -v @path -n "$D/meta.xml" | grep .
}