#!/bin/bash

echo "$2" | passwd "$1"  2> 30.txt
iconv -f UTF-8 -t CP1251 30.txt > 40.txt
