#!/bin/bash

gmtdefaults -D > .gmtdefaults4
gmtset HEADER_FONT_SIZE 16
gmtset COLOR_BACKGROUND 0/0/127
gmtset COLOR_FOREGROUND 132/0/0
gmtset OUTPUT_DEGREE_FORMAT +D
gmtset PLOT_DEGREE_FORMAT +D


### Clean all files

rm -f main.out
rm -f aux.out
rm -f contour_error.out
rm -f STAR.cpt

#file_foc='norm_planes.out'
#filece='tmp/mesh_cluster0001.out'
filece=$1
clu_num=$2
file_foc=$3

title=`echo Cluster $clu_num`
fileoutput='Plot_Polar_Cluster.pdf'
#filece='vit.out'
export LC_NUMERIC=POSIX

## Make calculation

blockmean $filece -Hi1 -I1/1 -R0/360/0/90 > Datafilt.xyz
surface Datafilt.xyz -Gvat.grd -I0.5/0.5 -R0/360/0/90
scale=10
max_dat=`minmax $filece -Eh2 | awk '{print $3}'`

T=`minmax -T100/2 $filece`
makecpt -Cjet -T0/1/0.01 -Z > E.cpt
psbasemap -JPa10c -R0/360/0/90 -B30/100:."$title": -K -Y4c > plot.ps
grdview vat.grd -CE.cpt -J -R -K -O -Qi >> plot.ps
cat << EOF > cont.txt
0.1 C
EOF

grdcontour vat.grd -Ccont.txt -W1p,white -J -K -O >> plot.ps

## Transform FM file and plot

if [ -e $file_foc ] ; then
#./read_fps.py $file_foc | awk '{print $1,$2}' > 'main.out'
#./read_fps.py $file_foc | awk '{print $3,$4}' > 'aux.out'
awk 'NR>1 {print $1,$2,NR-1}' $file_foc > 'main.out'
awk 'NR>1 {print $3,$4,NR-1}' $file_foc > 'aux.out'

## Get number of lines to edit cpt

num_l=$(wc -l < 'main.out')
num_l=$(printf '%i' $num_l)

if [ $num_l -le 1 ];then
	com='-Sa0.5c -W1p,white -G160/160/255'
else
	makecpt -Csealand -T1/$num_l/0.1 > STAR.cpt
	com='-Sa0.5c -W1p,white -CSTAR.cpt'
fi
psxy 'main.out' -J -R $com -O -K >> plot.ps
psxy 'aux.out' -J -R $com -O -K >> plot.ps
fi

#### Add uncertainty

if [ -e $file_foc ] ; then

AZ_fault=`awk 'NR==2 {print $1}' $file_foc`
PHI_fault=`awk 'NR==2 {print $2}' $file_foc`
AZ_aux=`awk 'NR==2 {print $3}' $file_foc`
PHI_aux=`awk 'NR==2 {print $4}' $file_foc`
error_F=`awk 'NR==2 {print $5}' $file_foc`
error_A=`awk 'NR==2 {print $6}' $file_foc`

./comput_circle_path.py $AZ_fault $PHI_fault $error_F
psxy contour_error.out -J -R -O -K -m -L -W0.8p,white >> plot.ps
./comput_circle_path.py $AZ_aux $PHI_aux $error_A
psxy contour_error.out -J -R -O -K -m -L -W0.8p,white >> plot.ps

fi

## retrieve 


## Add circles

psxy -J -R -O -K -W1p,white,'..' -Sc << EOF >> plot.ps
0 0 $(echo "30 * $scale / 90" |bc -l)
0 0 $(echo "60 * $scale / 90" |bc -l)
0 0 $(echo "0.1 * $scale / 90" |bc -l)
EOF

# Add text 

pstext -J -R -O -K -Gwhite << EOF >> plot.ps
90 0 12 0 0 LT 0\260
90 32 12 0 0 LT 30\260
90 63 12 0 0 LT 60\260
EOF


## Add scale

gmtset LABEL_FONT_SIZE 10
gmtset ANNOT_FONT_SIZE_PRIMARY 12
psscale -D5/-1/$scale/0.5ch -CE.cpt -B0.2g0.1:"Normalized normal vectors density": -O -K >> plot.ps
## Show plot
ps2pdf plot.ps $fileoutput

#### Remove file

rm -f main.out
rm -f aux.out
rm -f contour_error.out

#mv $fileoutput tmp/
#open $fileoutput