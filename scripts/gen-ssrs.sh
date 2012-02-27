#!/bin/sh

DOC_INDIR=/var/git/portal_continuous/doc
DOC_OUTDIR=/var/www/portal/doc

if [ ! -d "$DOC_OUTDIR" ]; then
	mkdir -p $DOC_OUTDIR
fi

cd $DOC_INDIR
latex2html SSRS.tex -dir $DOC_OUTDIR
