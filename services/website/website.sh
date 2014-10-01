#!/bin/bash
set -uf -o pipefail

. "$MDZ_DIR/functions.sh"

# TODO: convert to HTML - generate links, etc
gen_desc(){
    xmlstarlet sel -t -m "//description" -v "." "$MDZ_DATADIR/$1/meta.xml"
}

gen_prov(){
    xmlstarlet sel -t -m "//provenance" -v "." "$MDZ_DATADIR/$1/meta.xml"
}

gen_files(){
    files $1
}

gen_index(){
    NAME="$1"
    echo "<html><head>"
    echo "</head><body>"
    echo "<h1>$NAME</h1>"
    gen_desc "$NAME"
    echo "<h2>Provenance</h2>"
    gen_prov "$NAME"
    echo "<hr>"
    gen_files "$1"
    echo "</body></html>"
}

cp "$MDZ_DIR/services/website/index_template.html" "$MDZ_WEBSITE_DIR/index.html" || error "Couldn't create front page - exiting"
path="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX"
mkdir -p "$path"

for name in $(ls "$MDZ_DATADIR"); do 
    if [ -f "$MDZ_DATADIR/$name/meta.xml" ]; then
	mkdir -p "$path/$name"
        gen_index "$name" > "$path/$name/index.html"
    else 
       warn "$name does not appear to be a valid dataset - skipping"
    fi
done
    
