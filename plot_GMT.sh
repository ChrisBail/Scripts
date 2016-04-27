#!/usr/bin/env bash

######### DON'T TOUCH THIS PART ######
#### Comments
#----------------------------------------
# This files takes as input a GMT_config.sh file that defines all variables
# For ellipses plot, put n the view vector that points towards you, for example for a view from east 
# to west, n should be [1,0,0]. In classical Map view with y=North, x=East, z=Upward, put n=[0,0,1]
# Don't forget that function proj_xyz output semi_major, semi_minor (so that's why we multiply by 2 for GMT plot) and teta is given in degrees
# from horizontal. In the case of map view we use option -SE (so that it understand axes are in km) but have to change angle CCW from horizontal
# to CW from North, therefore we do a 90-teta.

###############################################################
#### Source config file

source $1

############# Define functions ##########

### Function to transform Aki files into RGB files for plotting focal mechanism
sdr2color(){
cat << END > tmp/focal.cpt
0       255       0      0     1.5    255       0       0
1.5      0       255     0     2.5     0       255      0
2.5      0        0     255    3.5     0        0      255
B       0       0       0
F       255     255     255
N       128     128     128
END
file1=$1
awk '{
if ($6 >= 45 && $6 <= 135) 
{$3="1";print $0;} 
else if ($6 >= -135 && $6 <= -45)
{$3="3";print $0;} 
else 
{$3="2";print $0;} 
}' $file1
}

cat << END > tmp/wedge.txt 
27 C
END

###############################################################
#### Define math parameter
pi=`echo "4*a(1)" | bc -l`
deg2rad=`echo "($pi/180)" | bc -l`

###############################################################
##### Check if USGS.cpt present in eq attributes to plot scale
#
#flag_scale=0
#printf -v var "%s\n" "${eq_attributes[@]}"
#if [[ "$var" == *-C* ]]
#then
#	flag_scale=1;
#fi
#
################################################################
###### Check if -Z option activated in foc attributes to plot scale
#
#flag_scale_foc=0
#printf -v var "%s\n" "${foc_attributes[@]}"
#if [[ "$var" == *-Z* ]]
#then
#	flag_scale_foc=1;
#fi
#
###############################################################
##### Control inputs

num_color=${#color_stations[@]}
num_stat=${#stations[@]}
if [ $num_color != 1 -a $num_color != $num_stat ] ; then
	echo 'number of colors for station network should be equal to number of networks'
	exit
fi

###############################################################
#### Define GMT parameters

gmtdefaults -D > .gmtdefaults4
gmtset FONT_TITLE 15p
gmtset FONT_LABEL 14p
gmtset FONT_ANNOT_PRIMARY 10p
gmtset COLOR_FOREGROUND 128/0/0
gmtset PS_PAGE_ORIENTATION portrait
gmtset MAP_FRAME_TYPE fancy
gmtset COLOR_NAN 200/200/200 

###############################################################
#### Create tmp directory

if [ ! -d tmp ]; then
mkdir tmp
fi

###############################################################
#### Create figures directory

if [ ! -d $figure_dir ]; then
mkdir $figure_dir
fi

###############################################################
#### Create gradient and contour file for further plotting

grdgradient $bathy -A45 -Nt1.25 -Ggradients.grd
grdclip $bathy -Gtmp/mask_bathy.grd -Sa-1/0 -Sb-1/1
grdmath gradients.grd tmp/mask_bathy.grd MUL = tmp/test.grd

###############################################################
#### First Define basemap and plot bathy/trench/stations on map.ps

rm -f map.ps
rm -f map.pdf
psbasemap -Jm$scalem -R$range -B$map_grid:."$title":WesN -K -Xc -Yc > map.ps 

if [ $intensity == "0" ];then
	pscoast -Df -Jm$scalem $map_attributes -R$range -W0.5p -K -O >> map.ps
fi

if [ $intensity == "1" ];then
	#grdimage $bathy -J -R -Itmp/test.grd -C$bathy_cpt -K -O >> map.ps
	grdimage $bathy -J -R -Igradients.grd -C$bathy_cpt -K -O >> map.ps
	pscoast -Df -Ir/0.2p,blue -Na/0.5p,black -J -R -K -O >> map.ps
fi

i=0
for tren in ${trench[@]} ; do
	psxy $tren -W0.5p ${trench_symbol[$i]} -J -R -O -K >> map.ps
	i=$(( $i + 1 ))
done

###### Plot stations
	
jj=0
for station in ${stations[@]} ; do
	psxy $station -Jm$scalem -R$range ${color_stations[$jj]} -O -K >> map.ps
	if [ $num_color != 1 ] ; then
		jj=$(( $jj + 1 ))
	fi
done


##### Second plot boxes



k=0

for center in ${centers[@]} ; do
	make_box_sc.py ${rotations[k]} ${centers[k]} ${length_left[k]} ${length_right[k]} ${widths[k]} tmp/box.xy tmp/text.txt $(( $k + 1 ))
	rm -f track.xy
	psxy tmp/box.xy -Jm$scalem -R$range -A -O -K -L >> map.ps
	IFS='/' read -ra ADDR <<< "$center"
	echo $center | awk -F'/' '{print $1,$2}' | psxy -Jm$scalem -R$range -Sc0.2c -Gblack -O -K >> map.ps
	pstext tmp/text.txt -J -R -O -K -Gwhite -Wblack,O >> map.ps
	k=$(( $k + 1 ))
done

##### Plot scales if required

for color_scale in "${color_scales[@]}"; do
	psscale $color_scale -O -K >> map.ps
done

###############################################################
#### Start loop over files 

flag_frame=1 # flag frame will be used to define if we need to replot bathy/stations....
i=0
focal_counter=0
eq_counter=0
grid_counter=0
text_counter=0

for filename in ${files[@]} ; do

	### Define flag_colors
	
	flag_color=0
	flag_color_foc=0

	#### Plot Map

	if [ ${flag_ellipse[$i]} == '1' ]; then
		n='[0,0,1]'
		python -c "from proj_xyz import *; proj_xyz($n,'$filename','tmp/data.xyzcov','Zdown')"
		 awk -v pi=$pi '{print $1, $2, 90-$4, 2*$5, 2*$6}' tmp/data.xyzcov | psxy -Jm$scalem -R$range -SE -W1p,black -O -K >> map.ps
		
	#### Plot focal mechanisms if any
	
	elif [ ${flag_ellipse[$i]} == "F" ]; then 
		if [[ "${foc_attributes[$i]}" == *-Z* ]]
		then
			  flag_color_foc=1
		fi
		psmeca $filename -Jm$scalem -R$range ${foc_attributes[$focal_counter]} -O -K >> map.ps
		
	elif [ ${flag_ellipse[$i]} == "A" ]; then
		### A stands for axes, its meant to plot Principal axes the file is the same as the meca file except the last two lines contain Plunge and azimut of P/T axis
		### extract the last two columns of the file
		
		awk '{print 1,$(NF-1),$NF}' $filename > tmp/tmp_focaxis.txt
		python -c "from base_rotation import *; focaxis2cartesian('tmp/tmp_focaxis.txt','tmp/tmp_focaxis_cart.txt',0)"
		paste <(awk '{print $1,$2}' $filename) <(awk '{print $1,$2}' tmp/tmp_focaxis_cart.txt ) | awk  '{print $0,0,0,0}' > tmp/axis_plot_1.xyz
		paste <(awk '{print $1,$2}' $filename) <(awk '{print -$1,-$2}' tmp/tmp_focaxis_cart.txt ) | awk  '{print $0,0,0,0}' > tmp/axis_plot_2.xyz
		psvelo tmp/axis_plot_1.xyz -Jm$scalem -R$range -Se$half_foc_length/0.95/0 -A1p/0/0 -O -K >> map.ps
		psvelo tmp/axis_plot_2.xyz -Jm$scalem -R$range -Se$half_foc_length/0.95/0 -A1p/0/0 -O -K >> map.ps
		awk '{print $1,$2}' $filename | psxy -Jm$scalem -R$range -Sc0.05c -Gblack -O -K >> map.ps
		#-A0.5p/0/0 
		
	#### Plot focal mechanisms with RGB convention if any
	
	elif [ ${flag_ellipse[$i]} == "Fa" ]; then 
		sdr2color $filename > tmp/focal.xyz
		psmeca tmp/focal.xyz -Jm$scalem -R$range ${foc_attributes[$focal_counter]} -Ztmp/focal.cpt -O -K >> map.ps
		
	#### Plot text if any
	
	elif [ ${flag_ellipse[$i]} == "T" ]; then 
		pstext $filename -Jm$scalem -R$range ${text_attributes[$text_counter]}  -O -K >> map.ps
		
	elif [ ${flag_ellipse[$i]} == "L" ]; then 
		psxy $filename -Jm$scalem -R$range ${eq_attributes[$eq_counter]} -O -K >> map.ps
	
	#### Plot Grid if any
	
 	elif [ ${flag_ellipse[$i]} == "G" ]; then 
 		grid2contour.sh $filename -Gtmp/contour_grid.txt -Jm$scalem -R$range -I1k -Fg20 -D1
 		grdgradient $filename -A0 -Nt -Ggradients.grd
 		psclip tmp/contour_grid.txt -Jm$scalem -R$range -O -K >> map.ps
 		grdimage $filename -Jm$scalem -R$range -Igradients.grd ${grid_attributes[$grid_counter]} -K -O >> map.ps
 		#grdview $filename -Jm$scalem -R$range ${grid_attributes[$grid_counter]} -O -K -Qi >> map.ps
 		#grdcontour $filename -Jm$scalem -R$range ${contour_attributes[$grid_counter]} -O -K >> map.ps
 		#grdcontour $filename -Jm$scalem -Wc0.1p -R$range -C10 -S50 -A20+g -Wa1p,black -O -K >> map.ps
 		
 		#grdcontour $mask_grid -Jm$scalem -Wc2p,red -R$range -C27 -L15/28 -S50 -O -K >> map.ps
 		psclip -C -Jm$scalem -R$range -O -K >> map.ps
 		rm -f tmp/contour_grid.txt
 		#echo $filename
 		#grdgradient $filename -A0 -Nt -Ggradients.grd
 		#echo 'j'
 		#grdclip $filename -Gtmp/test.grd -Sa-100/NaN
 		#grdimage $filename -Jm$scalem -R$range -Igradients.grd ${grid_attributes[$grid_counter]} -Qc -K -O >> map.ps
 		
	#### Plot Epicenters
	else
		if [[ "${eq_attributes[$i]}" == *-C* ]]
		then
		  flag_color=1
		fi
		#sed '/-999/d' $filename > tmp/data.xyzv
		cat $filename > tmp/data.xyzv
		if [[ $flag_color -eq 1 ]];then
			echo 'hello'
			awk -v scale_mag=$scale_mag '{print $1,$2,$3,scale_mag*2.5^$4}' tmp/data.xyzv | psxy -Jm$scalem -R$range ${eq_attributes[$eq_counter]} -O -K >> map.ps
		else
			awk -v scale_mag=$scale_mag '{print $1,$2,scale_mag*2.5^$4}' tmp/data.xyzv | psxy -Jm$scalem -R$range ${eq_attributes[$eq_counter]} -O -K >> map.ps
		fi

	fi


	if [ $i -eq 0 ]; then
		flag_frame=1
	else
		flag_frame=0
	fi

	#### Loop over profiles
		
	j=0

	for center in ${centers[@]} ; do

		profile_num=$(( $j + 1 ))
		profile_name='tmp/profile_'$profile_num'.ps'
		title_prof='Profile '$profile_num
		cen=${centers[j]}
		rot=${rotations[j]}
		len=${lengths[j]}
		wid=${widths[j]}
		half_len1=${length_left[j]}
		half_len2=${length_right[j]}
		half_wid=$(echo "$wid/2" | bc -l)

		range_p="-Jx$scalepx/-$scalepy -R-$half_len1/$half_len2/0/$depth"
		
		###############################################################
		#### Compute view n
		rad=`echo "$rot*$deg2rad" | bc -l`
		n1=`echo "c($rad)" | bc -l`
		n2=`echo "-s($rad)" | bc -l`
		n3=0
		
		n="[$n1,$n2,$n3]"
		if [ $flag_frame -eq 1 ] ; then
			make_box_sc.py $rot $cen $half_len1 $half_len2 $wid tmp/box.xy 
			
			###############################################################
			### Plot frame/stations/bathy...
		
			psbasemap $range_p -B$profile_prop:."$title_prof":WesN -K -Xc -Yc > $profile_name
		
			###############################################################
			##### Bathy
		
			grdtrack track.xy -G$bathy > tmp/scr1.txt
			project tmp/scr1.txt -C$cen -A$rot -L-$half_len1/$half_len2 -W-5/5 -Fpz -Qk > tmp/scr2.txt
			awk '{print $1,-$2/1000}' tmp/scr2.txt | sort -k1 -n | psxy -J -R-$half_len1/$half_len2/-6/$depth -W1p,black -O -K >> $profile_name
			
			### Trench 
				
			if [[ ! -z "$trench" ]];then
			awk '{print $1,$2,$3}' $trench | project -C$cen -A$rot -L-$half_len1/$half_len2 -W-10/10 -Fpqrs -Qk > tmp/scr3.txt
			minmax tmp/scr3.txt -EL1 | awk '{print $3,$4}' > tmp/point.txt
			grdtrack tmp/point.txt -G$bathy > tmp/scr4.txt
			project tmp/scr4.txt -C$cen -A$rot -Fpz -Qk > tmp/trench.txt
			awk '{print $1,-$2/1000}' tmp/trench.txt | psxy $range_p -Sx0.5c -W1p,black -O -K >> $profile_name
			fi
			
			### Plane
			
			if [[ ! -z "$sub_plane" ]];then
				for sub in ${sub_plane[@]};do
					project $sub -S -C$cen -A$rot -L-$half_len1/$half_len2 -W-1/1 -Fpz -Qk > tmp/scr1.txt
					if [[ ! -s tmp/scr1.txt ]]; then  # Continue to next iteration if plane is not on profile
						continue
					fi
					filter1d tmp/scr1.txt -D5k -Fb10 > tmp/scr2.txt
					awk '{print $1,$2}' tmp/scr2.txt | psxy $range_p -W2p,black -O -K >> $profile_name
				done			
			fi
		    
			### Stations
		
			k=0
			for station in ${stations[@]} ; do
				project $station -C$cen -A$rot -W-$half_wid/$half_wid -Fpz -Qk > tmp/station.txt
				awk '{print $1,-$2}' tmp/station.txt | psxy -J -R-$half_len1/$half_len2/-10/$depth ${color_stations[$k]} -O -K >> $profile_name
				if [ $num_color != 1 ] ; then
					k=$(( $k + 1 ))
				fi
			done
		fi
		
		### Data
		
		
		if [ ${flag_ellipse[$i]} == '1' ]; then
			python -c "from proj_xyz import *; proj_xyz($n,'$filename','tmp/data.xyzcov','Zdown')"
			project tmp/data.xyzcov -C$cen -A$rot -L-$half_len1/$half_len2 -W-$half_wid/$half_wid -Fpz -Qk > tmp/data.pzm
			awk -v scalex=$scalepx -v scaley=$scalepy '{print $1, $2, $3, 2*$4*scalex, 2*$5*scaley}' tmp/data.pzm | psxy  $range_p -Sec -W1p,black -O -K >> $profile_name
		
		###### Plot Grid projection if any
		
		elif [ ${flag_ellipse[$i]} == "G" ]; then 
			
			grd2xyz $filename | sed '/NaN/d' > tmp/plane_1.xyz
			project tmp/plane_1.xyz -C$cen -A$rot -S -L-$half_len1/$half_len2 -W-$half_wid/$half_wid -Fpz -Qk | awk '{print $0,100}' > tmp/plane_2.xyz
			xyz2grd tmp/plane_2.xyz -I0.5 -NNaN -Gtmp/proj.grd -R-$half_len1/$half_len2/0/$depth
			grdfilter tmp/proj.grd -Gtmp/proj2.grd -I0.5/0.5 -Fg5/5 -D0
            grid2contour.sh tmp/proj2.grd -Gtmp/new_count_proj2.txt -Jx$scalepx/-$scalepy -I1 -Fg20 -D0
			psxy tmp/new_count_proj2.txt $range_p -W1p,black -O -K >> $profile_name
			
		###### Plot focal mechanisms if any
		
		elif [ ${flag_ellipse[$i]} == "F" ]; then 
			
			#### Retrieve projection attributes as syntax is quite different from project
			#echo "-Ab$cen/$rot/$half_len2/90/$half_wid/0/500"
			#echo ${foc_attributes[$focal_counter]}
			#echo $filename
			pscoupe $filename $range_p ${foc_attributes[$focal_counter]} -Ab$cen/$rot/$half_len2/90/$half_wid/0/500 -O -K >> $profile_name
			
			### Remove file generated by pscoupe
			rm -f Ab*
			
	    ###### Plot focal mechanisms in RGB if any
		
		elif [ ${flag_ellipse[$i]} == "Fa" ]; then 
			
			#### Retrieve projection attributes as syntax is quite different from project
			#echo "-Ab$cen/$rot/$half_len2/90/$half_wid/0/500"
			#echo ${foc_attributes[$focal_counter]}
			#echo {{foc_attributes[$focal_counter]}/-Z*cpt/ }
			scratch_attributes=$(echo ${foc_attributes[$focal_counter]})
			new_attrib=${scratch_attributes/-Z*cpt/ }
			awk '{if ($6 >= 45 && $6 <= 135) print $0}' $filename \
			| pscoupe $range_p $new_attrib -Gred -Ab$cen/$rot/$half_len2/90/$half_wid/0/500 -O -K >> $profile_name
			awk '{if ($6 >= -135 && $6 <= -45) print $0}' $filename \
			| pscoupe $range_p -Gblue $new_attrib -Ab$cen/$rot/$half_len2/90/$half_wid/0/500 -O -K >> $profile_name
			awk '{if ($6 >= 135 || $6 <= -135 || ($6<45 && $6>-45 )) print $0}' $filename \
			| pscoupe $range_p -Ggreen $new_attrib -Ab$cen/$rot/$half_len2/90/$half_wid/0/500 -O -K >> $profile_name
	
			#sdr2color $filename > tmp/focal.xyz
			#pscoupe tmp/focal.xyz $range_p ${foc_attributes[$focal_counter]} -Ztmp/focal.cpt -Ab$cen/$rot/$half_len2/90/$half_wid/0/500 -O -K >> $profile_name
			
		#### Plot Tensor Principal axis if any
		
		elif [ ${flag_ellipse[$i]} == "A" ]; then 
			
			new_rot=$(echo "90 - $rot" | bc )
			awk '{print 1,$(NF-1),$NF}' $filename > tmp/tmp_focaxis.txt
			python -c "from base_rotation import *; focaxis2cartesian('tmp/tmp_focaxis.txt','tmp/tmp_focaxis_cart.txt',$new_rot)"
			paste <(awk '{print $1,$2,$3}' $filename) <(awk '{print $1,$2,$3}' tmp/tmp_focaxis_cart.txt ) > tmp/tmp_axis_scratch1.txt
			project tmp/tmp_axis_scratch1.txt -C$cen -A$rot -L-$half_len1/$half_len2 -W-$half_wid/$half_wid -Fpz -Qk > tmp/tmp_axis_scratch2.txt
			awk '{print $1,$2,$3,-$5,0,0,0}' tmp/tmp_axis_scratch2.txt |
			psvelo $range_p -Se$half_foc_length/0.95/0 -A1p/0/0 -O -K >>  $profile_name
			awk '{print $1,$2,-$3,$5,0,0,0}' tmp/tmp_axis_scratch2.txt |
			psvelo $range_p -Se$half_foc_length/0.95/0 -A1p/0/0 -O -K >>  $profile_name
	
			
		#### Plot epicenters if any
		elif [ ${flag_ellipse[$i]} == '0' ];then
			project tmp/data.xyzv -C$cen -A$rot -L-$half_len1/$half_len2 -W-$half_wid/$half_wid -Fpz -Qk > tmp/data.pzm
			if [[ $flag_color -eq 1 ]];then
				awk -v scale_mag=$scale_mag '{print $1,$2,$2,scale_mag*2.5^$3}' tmp/data.pzm | psxy $range_p ${eq_attributes[$eq_counter]} -K -O >> $profile_name
			else
				awk -v scale_mag=$scale_mag '{print $1,$2,scale_mag*2.5^$3}' tmp/data.pzm | psxy $range_p ${eq_attributes[$eq_counter]} -K -O >> $profile_name
			fi
			k=0
			for station in ${stations[@]} ; do
				project $station -C$cen -A$rot -W-$half_wid/$half_wid -Fpz -Qk > tmp/station.txt
				awk '{print $1,-$2}' tmp/station.txt | psxy -Jx$scalepx/-$scalepy -R-$half_len1/$half_len2/-3/$depth ${color_stations[$k]} -O -K >> $profile_name
				if [ $num_color != 1 ] ; then
					k=$(( $k + 1 ))
				fi	
			done
		fi
		
		j=$(( $j + 1 ))
		
	done
	
	### Set counters properly 
	
	if [[ ${flag_ellipse[$i]} == "F" || ${flag_ellipse[$i]} == "Fa" && ${#foc_attributes[@]} -gt 1 ]]; then 
			focal_counter=$(( $focal_counter + 1 ))
	fi	
	if [[ ${flag_ellipse[$i]} == "0" || ${flag_ellipse[$i]} == "1" ]]; then
		eq_counter=$(( $eq_counter + 1 ))
	fi
	if [[ ${flag_ellipse[$i]} == "G" ]]; then
		grid_counter=$(( $grid_counter + 1 ))
	fi
	if [[ ${flag_ellipse[$i]} == "T" ]]; then
		text_counter=$(( $text_counter + 1 ))
	fi
	
	i=$(( $i + 1 ))
done

###### Add Special overlay

if [ $intensity == "0" ];then
	pscoast -Df -Jm$scalem -R$range -W0.5p -K -O >> map.ps
elif [ $intensity == "NC" ];then
	:
else
    grdcontour $bathy -Jm$scalem -R$range -W0.3p -C0.1 -L0/0.19 -S1 -K -O >> map.ps
fi


i=0

for tren in ${trench[@]} ; do
	psxy $tren -W1p ${trench_symbol[$i]} -Gblack -Jm$scalem -R$range -O -K >> map.ps
	i=$(( $i + 1 ))
done


i=0
for station in ${stations[@]} ; do
	psxy $station -J -R ${color_stations[$i]} -O -K >> map.ps
	if [ $num_color != 1 ] ; then
		i=$(( $i + 1 ))
	fi
	awk '{print $1+0.05,$2,$4}' $station | pstext -Jm$scalem -R$range -F+f10p,Helvetica-Bold,black+jLB -O -K >> map.ps
done

##### Second plot boxes

k=0

for center in ${centers[@]} ; do
	make_box_sc.py ${rotations[k]} ${centers[k]} ${length_left[k]} ${length_right[k]} ${widths[k]} tmp/box.xy tmp/text.txt $(( $k + 1 ))
	rm -f track.xy
	psxy tmp/box.xy -Jm$scalem -R$range -A -O -K -L >> map.ps
	IFS='/' read -ra ADDR <<< "$center"
	echo $center | awk -F'/' '{print $1,$2}' | psxy -Jm$scalem -R$range -Sc0.2c -Gblack -O -K >> map.ps
	pstext tmp/text.txt -J -R -O -K -Gwhite -Wblack,O >> map.ps
	k=$(( $k + 1 ))
done


#########################
####  Add scale

psbasemap $km_scale_pos -Jm$scalem -R$range -O >> map.ps 

###############################################################
#### Convert to pdf

ps2pdf map.ps $figure_dir/map.pdf
$pdfpreview $figure_dir/map.pdf

j=1
for center in ${centers[@]} ; do
	ps2pdf 'tmp/profile_'$j'.ps' $figure_dir/'profile_'$j'.pdf'
	open $figure_dir/'profile_'$j'.pdf'
	j=$(( $j + 1 ))
done
