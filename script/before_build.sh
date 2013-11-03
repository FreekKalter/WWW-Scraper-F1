#!/usr/bin/env sh

echo "****** Begin before_build script. *******"
cpanm Dist::Zilla --notest --quiet
dzil authordeps | cpanm --notest --quiet
dzil build
cd WWW-Scraper-F1*
cpanm --quiet --installdeps --notest .
