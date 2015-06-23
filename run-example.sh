#!/bin/bash

SITES=(
	"http://your.sitedoma.in/ first.site"
	"http://your.2nd.sitedoma.in/ second.site"
)
IFS=','

for site in ${SITES[@]}; do 
	set -- $site
	eval casperjs --ignore-ssl-errors=yes wmt-casper.coffee $1 $2
done
