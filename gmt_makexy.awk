BEGIN{base=2.5; FS=" "}
{
	lon=$1;lat=$2;depth=$3;mag=$5;
	size=scale*(base^mag);
	print lon, lat, depth,size,mag
}