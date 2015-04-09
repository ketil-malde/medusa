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

checksum(){
    openssl sha1 -r "$@" | cut -c-40
    }

is_valid_id() { [[ $1 =~ ^[0-9a-f]{40}$ ]]; }

# find all dataset objects
is_dataset(){
    f="$(datafile "$1")"
    is_valid_id "$1" && test "$(head -c 5 "$f")" = "<?xml" && test "$(tail -n +2 "$f" | head -c 5)" = "<meta"
}

# get path to object
datafile(){ echo "$MDZ_DATADIR/$1"; }

# Check status of dataset - use this in scripts etc to avoid using incorrect data sets.
validate(){
    D="$1"
    is_dataset "$D" || error "'$D' is not a valid dataset."
    S=$(xmlstarlet sel -t -m /meta -v @status -n "$D")
    echo "$S"
    [ "$S" = "deprecated" ] && error "Dataset '$D' is deprecated!"
    [ "$S" = "superseded" ] && warn "Dataset '$D' is superseded!"
}

datasets(){
    find "$MDZ_DATADIR" -type f | while read f; do if is_dataset "$(basename "$f")"; then basename "$f"; fi; done
}

# list all files in a dataset
files(){
    D="$1"
    is_dataset "$D" || error "'$D' is not a valid dataset."
    xmlstarlet sel -t -m //file -v @path -n "$(datafile "$D")" | grep .
}

# list all files with a given type
files_by_type(){
    D="$1"
    T="$2"
    is_dataset "$D" || error "'$D' is not a valid dataset."
    xmlstarlet sel -t -m "//file[@mimetype='$T']" -v @path -n "$(datafile "$D")" | grep .
}
