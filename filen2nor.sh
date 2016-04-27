#bin/bash/

filen_file=$1

echo $filen_file
counter=1
string=$(awk 'END {print NR}' $filen_file)
echo $string

awk '{print $NF}' $filen_file > temp.txt

while read line; 
do 
echo $line; 
done < temp.txt