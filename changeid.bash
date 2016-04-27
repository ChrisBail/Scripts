#!/usr/bin/bash


for file in ~/SDS/200?/*/*/*/*; do 
echo $file
msmod --loc "00" $file -A /home/baillard/SDS1/%Y/%n/%s/%c.%q/%n.%s.%l.%c.%q.%Y.%j
done

#msmod --loc "00" $file
