#!/usr/bin/env sh

cpanm Dist::Zilla
dzil authordeps | cpanm
dzil build
