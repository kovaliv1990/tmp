#!/bin/bash

adduser "$1"
echo "$2" | passwd "$1" --stdin  2> 30.txt
iconv -f UTF-8 -t CP1251 30.txt > 40.txt
