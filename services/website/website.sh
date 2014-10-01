#!/bin/bash
set -uf -o pipefail

. "$MDZ_DIR/functions.sh"

# TODO: convert to HTML - generate links, etc
gen_desc(){
    xmlstarlet sel -t -m "//description" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
}

gen_prov(){
    xmlstarlet sel -t -m "//provenance" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
}

gen_files(){
    echo "<table border=\"1\"><tr><th>Path</th><th>Description</th><th>Type</th><th>md5sum</th></tr>"
    files "$MDZ_DATADIR/$1" | while read f; do
	TYPE=$(xmlstarlet sel -t -m "//file[@path='$f']" -v @mimetype -n "$MDZ_DATADIR/$1/meta.xml")
	DESC=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "." -n "$MDZ_DATADIR/$1/meta.xml")
	MD5=$(xmlstarlet  sel -t -m "//file[@path='$f']" -v @md5 -n "$MDZ_DATADIR/$1/meta.xml")
	LINK="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$1/$f"
        echo "  <tr> <td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$1/$f\">$f</a></td> <td>$DESC</td> <td>$TYPE</td> <td>$MD5</td> </tr>"
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

extract_species(){
    FILE="$MDZ_DATADIR/$1/meta.xml"
    xmlstarlet sel -t -m "//species" -v "@tsn" -o "	"  -v "@sciname" -o "	" -v "." -n "$FILE" 
}

cp "$MDZ_DIR/services/website/index_template.html" "$MDZ_WEBSITE_DIR/index.html" || error "Couldn't create front page - exiting"
path="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX"
mkdir -p "$path"
rm -f /tmp/tmp_species_list

for name in $(ls "$MDZ_DATADIR"); do 
    if [ -f "$MDZ_DATADIR/$name/meta.xml" ]; then
	mkdir -p "$path/$name"
        gen_index "$name" > "$path/$name/index.html"
	extract_species $name >> /tmp/tmp_species_list
    else 
       warn "$name does not appear to be a valid dataset - skipping"
    fi
done
    
