#!/bin/bash

# check specific formats
check_format_fasta(){
    set +e
    egrep -n -m 3 -v '^>|^[A-Za-z]*$' "$1" && warn "Suspicious characters in FASTA sequence data!"
    grep -v '^>' "$1" | cut -c100- | grep -q . && warn "FASTA file contains very long lines"
    set -e
}

check_format(){
    file="$1"
    type="$2"

    case "$type" in
	text/x-fasta-prot|text/x-fasta-rna|text/x-fasta-dna)
	    echo "Checking formats: $f"
	    check_format_fasta "$(datafile "$sha1")"
	    ;;
    esac
}
