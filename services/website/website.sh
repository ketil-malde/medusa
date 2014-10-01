#!/bin/bash
set -uf -o pipefail

. "$MDZ_DIR/functions.sh"

TMP_ST=/tmp/tmp_species_list

gen_desc(){
    echo "<h1>$1</h1>"
    xmlstarlet sel -t -m "//description" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
}

gen_prov(){
    echo "<h2>Provenance</h2>"
    xmlstarlet sel -t -m "//provenance" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" - 2>/dev/null
    # discard warnings when dataset doesn't have provenance (sorry)
}

gen_files(){
    echo "<h2>Files</h2>"
    echo "<table border=\"1\"><tr><th>Path</th><th>Description</th><th>Type</th><th>md5sum</th></tr>"
    files "$MDZ_DATADIR/$1" | while read f; do
	TYPE=$(xmlstarlet sel -t -m "//file[@path='$f']" -v @mimetype -n "$MDZ_DATADIR/$1/meta.xml")
	DESC=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "." -n "$MDZ_DATADIR/$1/meta.xml")
	MD5=$(xmlstarlet  sel -t -m "//file[@path='$f']" -v @md5 -n "$MDZ_DATADIR/$1/meta.xml")
	LINK="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$1/$f"
        echo "  <tr> <td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$1/$f\">$f</a></td> <td>$DESC</td> <td>$TYPE</td> <td>$MD5</td> </tr>"
	echo "</tr>"

        mkdir -p $(dirname "$LINK") || error "Failed to create directory - exiting"
        ln -fs "$MDZ_DATADIR/$1/$f" "$LINK" || error "Failed to create link - exiting"
    done
    echo "</table>"
}

gen_index(){
    NAME="$1"
    echo "<html><head></head><body>"
    gen_desc "$NAME"
    gen_prov "$NAME"
    gen_files "$NAME"
    echo "</body></html>"
}

extract_species(){
    FILE="$MDZ_DATADIR/$1/meta.xml"
    xmlstarlet sel -t -m "//species" -v "@tsn" -o "	"  -v "@sciname" -o "	" -v "." -o "	$1" -n "$FILE" 
}

build_species_table(){
    echo "<html><body><h1>Species referenced</h1>"
    echo "  <table border=\"1\"><tr> <th>TSN</th> <th>sciname</th> <th>Descriptions</th><th>Datasets</th></tr>"
    for tsn in $(cut -f1 "$TMP_ST" | sort | uniq); do
	PAT="^$tsn	"
	echo -n "  <tr><td>$tsn</td>" 
        echo -n "      <td>$(grep $PAT $TMP_ST | cut -f2 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo -n "      <td>$(grep $PAT $TMP_ST | cut -f3 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo    "      <td>$(grep $PAT $TMP_ST | cut -f4 | grep . | tr '\n' ' ') </td></tr>"
    done
    echo "</table></body></html>"
}

cp "$MDZ_DIR/services/website/index_template.html" "$MDZ_WEBSITE_DIR/index.html" || error "Couldn't create front page - exiting"
path="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX"
mkdir -p "$path" "$MDZ_WEBSITE_DIR/TSN" || error "Failed to make directory - exiting"
rm -f "$TMP_ST"

for name in $(ls "$MDZ_DATADIR"); do 
    if [ -f "$MDZ_DATADIR/$name/meta.xml" ]; then
	echo "Processing ${name}..."
	mkdir -p "$path/$name"
        gen_index "$name" > "$path/$name/index.html"
	extract_species $name >> "$TMP_ST"
    else 
       warn "$name does not appear to be a valid dataset - skipping"
    fi
done

build_species_table > "$MDZ_WEBSITE_DIR/TSN/index.html"
