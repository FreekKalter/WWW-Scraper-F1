#!/usr/bin/env sh

cpanm Dist::Zilla
dzil authordeps | cpanm
dzil build
cd WWW-Scraper-F1*
cpanm --quit --installdeps --notest .
