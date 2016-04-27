#!/usr/bin/bash


station=$1
letter=$2

for file in ~/SDS1/2015/N/$station/?$letter"Z".?/*; do 
echo $file
east="S"$letter"E"
north="S"$letter"N"
msmod --chan $east $file -A /home/baillard/SDS1/%Y/%n/%s/%c.%q/%n.%s.%l.%c.%q.%Y.%j
msmod --chan $north $file -A /home/baillard/SDS1/%Y/%n/%s/%c.%q/%n.%s.%l.%c.%q.%Y.%j
done

#msmod --loc "00" $file
