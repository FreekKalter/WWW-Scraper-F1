#!/usr/bin/env sh

cpanm Dist::Zilla
dzil authordeps | cpanm --no-test --quit --mirror http://cpan.mirrors.travis-ci.org 
dzil build
cd WWW-Scraper-F1*
cpanm --quit --installdeps --notest --mirror http://cpan.mirrors.travis-ci.org .
