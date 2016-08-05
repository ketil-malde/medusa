
if [ -z ${TERM+x} ]; then
   R="$(tput setaf 1)"
   G="$(tput setaf 2)"
   Y="$(tput setaf 3)"
   C="$(tput setaf 6)"
   N="$(tput sgr0)"
else
   R=
   G=
   Y=
   C=
   N=
fi

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
    openssl sha1 "$@" | sed -e 's/^.*= //g'
    }

is_valid_id() { [[ $1 =~ ^[0-9a-f]{40}$ ]]; }

# find all dataset objects
is_dataset(){
    f="$(datafile "$1")"
    [ -f "$f" ] && is_valid_id "$1" && test "$(head -c 5 "$f")" = "<?xml" && test "$(tail -n +2 "$f" | head -c 5)" = "<meta"
}

assert_is_dataset(){ is_dataset "$1" || error "'$1' is not a valid dataset."; }

# get path to object
datafile(){ is_valid_id "$1" && echo "$MDZ_DATADIR/${1:0:3}/$1" || error "Invalid object id: $1"; }

datasets(){
    find "$MDZ_DATADIR" -type f | while read f; do if is_dataset "$(basename "$f")"; then basename "$f"; fi; done
}

# list all files (by id, sha1 checksum) in a dataset
fileids(){
    D="$1"
    assert_is_dataset "$D"
    xmlstarlet sel -t -m //file -v @sha1 -n "$(datafile "$D")" | grep .
}

# list all files (by path) in a dataset
files(){
    D="$1"
    assert_is_dataset "$D"
    xmlstarlet sel -t -m //file -v @path -n "$(datafile "$D")" | grep .
}

# list all files with a given type
files_by_type(){
    D="$1"
    T="$2"
    assert_is_dataset "$D"
    xmlstarlet sel -t -m "//file[@mimetype='$T']" -v @path -n "$(datafile "$D")" | grep .
}

buildcache(){
    C="$MDZ_DATADIR/cache"
    rm -rf "$C"
    mkdir "$C"
    touch "$C/obsolete" "$C/invalid" "$C/all_datasets" "$C/other_rel" "$C/current"
    set +e
    datasets | while read d; do
       echo "**** $d"
       xmlstarlet sel -t -m "//dataset" -v "@id" -o "	" -v "@rel" -n "$(datafile "$d")" | while read id rel; do
           echo "**** $rel $id"
           case "$rel" in
	       invalidates)
		   echo "$id	$d" >> "$C/invalid"
		   ;;
	       obsoletes)
		   echo "$d obsoletes $d"
		   echo "$id	$d" >> "$C/obsolete"
		   ;;
	       *)
		   echo "$id	$d	$rel" >> "$C/other_rel"
		   ;;
	   esac
       done
       desc="$(xmlstarlet sel -t -m //description -v "." "$(datafile "$d")" | tr '\n' ' ')"
       name="$(xmlstarlet sel -t -m /meta -v "@name" "$(datafile "$d")")"
       echo  "$d	$name	$desc" >> "$C/all_datasets"
    done
    cut -f1 "$C/all_datasets" | while read d; do
        grep -q "^$d" "$C/invalid" "$C/obsolete" || echo "$d" >> "$C/current"
    done
}
