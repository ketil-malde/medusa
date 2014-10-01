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
    echo "<table border=\"1\"><tr><th>Path</th><th>Description</th><th>Type</th><th>md5sum</th></tr>"
    files "$MDZ_DATADIR/$1" | while read f; do
	TYPE=$(xmlstarlet sel -t -m "//file[@path='$f']" -v @mimetype -n "$MDZ_DATADIR/$1/meta.xml")
	DESC=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "." -n "$MDZ_DATADIR/$1/meta.xml")
	MD5=$(xmlstarlet  sel -t -m "//file[@path='$f']" -v @md5 -n "$MDZ_DATADIR/$1/meta.xml")
	LINK="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$1/$f"
        echo "  <tr> <td><a href=\"$LINK\">$f</a></td> <td>$DESC</td> <td>$TYPE</td> <td>$MD5</td> </tr>"
	echo "</tr>"

        mkdir -p $(dirname "$LINK")
        ln -fs "$MDZ_DATADIR/$1/$f" "$LINK"
    done
    echo "</table>"
}

gen_index(){
    NAME="$1"
    echo "<html><head></head><body>"
    echo "<h1>$NAME</h1>"
    gen_desc "$NAME"
    echo "<h2>Provenance</h2>"
    gen_prov "$NAME"
    echo "<h2>Files</h2>"
    gen_files "$NAME"
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
    
