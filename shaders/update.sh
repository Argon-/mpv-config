#!/usr/bin/env bash
for d in */; do cd "${d}"; git pull; cd ..; done
