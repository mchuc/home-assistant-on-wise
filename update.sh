#!/usr/bin/env bash

git add --all .
echo "Upgraduję projekt"
echo "temat zmiany:"
read temat
echo "opis zmiany:"
read opis

git commit -m "$(date '+%Y-%m-%d %H:%M:%S'): $temat" -m "$opis"
git push -u origin main
