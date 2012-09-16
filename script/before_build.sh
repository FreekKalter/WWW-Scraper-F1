#!/usr/bin/env sh

cpanm Dist::Zilla
dzil authordeps | cpanm --notest --quiet --mirror http://cpan.mirrors.travis-ci.org 
dzil build
cd WWW-Scraper-F1*
cpanm --quiet --installdeps --notest --mirror http://cpan.mirrors.travis-ci.org .
