function [h,I,z]=dem(x,y,z,varargin)
%DEM Shaded relief image plot
%
%	DEM(X,Y,Z) plots the Digital Elevation Model defined by X and Y 
%	coordinate vectors and elevation matrix Z, as a lighted image using
%	specific "landcolor" and "seacolor" colormaps. DEM uses IMAGESC 
%	function which is much faster than SURFL when dealing with large 
%	high-resolution DEM. It produces also high-quality and moderate-size 
%	Postscript image adapted for publication.
%
%	[H,I] = DEM(...); returns graphic handle H and illuminated image as I, 
%	an MxNx3 matrix (if Z is MxN and DECIM is 1).
%
%	DEM(X,Y,Z,'Param1',Value1,'Param2',Value2,...) specifies options or
%	parameter/value couple (case insensitive):
%
%
%	--- Lighting options ---
%
%	'Azimuth',A
%		Light azimuth in degrees clockwise relative to North. Default is
%		A = -45 for	a natural northwestern illumination.
%
%	'Contrast',C
%		Light contrast, as the exponent of the gradient value:
%			C = 1 for linear contrast (default),
%			C = 0 to remove lighting,
%			C = 0.5 for moderate lighting,
%			C = 2 or more for strong contrast.
%
%	'LCut',LC
%		Lighting scale saturation cut with a median-style filter in % of 
%	    elements, such as LC% of maximum gradient values are ignored:
%			LC = 0.2 is default, 
%			LC = 0 for full scale gradient.
%
%	'km'
%		Stands that X and Y coordinates are in km instead of m (default).
%		This allows correct lighting. Ignored if LATLON option is used.
%
%
%	--- Elevation colorscale options ---
%
%	'ZLim',[ZMIN,ZMAX]
%		Fixes min and max elevation values for colormap. Use NaN to keep 
%		real min and/or max data values.
%
%	'ZCut',ZC
%		Median-style filter to cut extremes values of Z (in % of elements),
%		such that ZC% of most min/max elevation values are ignored in the
%		colormap application:
%			ZC = 0.5 is default, 
%			ZC = 0 for full scale.
%
%
%	--- "No Value" elevation options ---
%
%	'NoValue',NOVALUE
%		Defines the values that will be replaced by NaN. Note that values 
%		equal to minimum of Z class are automatically detected as NaN 
%		(e.g., -32768 for int16 class).
%
%	'NaNColor',[R,G,B]
%		Sets the RGB color for NaN/NoValue pixels (default is a dark gray).
%		Note that your must specify a valid 3-scalar vector (between 0 and
%		1);	color characters like 'w' or 'k' are not allowed, use [1,1,1]
%		or [0,0,0] instead.
%
%	'Interp'
%		Interpolates linearly all NaN values (fills the gaps using linear 
%		triangulation), using an optimized algorithm.
%
%
%	--- Colormap options ---
%
%	'LandColor',LMAP
%		Uses LMAP colormap instead of default (landcolor, if exists or 
%		jet) for Z > 0 elevations.
%
%	'SeaColor',SMAP
%		Sets the colormap used for Z <= 0 elevations. Default is seacolor 
%		(if exists) or single color [0.7,0.9,1] (a light cyan) to simulate
%		sea color.
%
%	'ColorMap',CMAP
%		Uses CMAP colormap for full range of elevations, instead of default 
%		land/sea. This option overwrites LANDCOLOR/SEACOLOR options.
%
%	'Lake'
%		Detects automaticaly flat areas different from sea level (non-zero 
%		elevations) and colors them as lake surfaces.
%
%	'Watermark',N
%		Makes the whole image lighter by a factor of N.
%
%
%	--- Basemap and scale options ---
%
%	'Cartesian'
%		Plots classic basemap-style axis, considering coordinates X and Y 
%		as cartesian in meters. Use parameter "km' for X/Y in km.
%
%	'LatLon'
%		Plots geographic basemap-style axis in deg/min/sec, considering 
%		coordinates X as longitude and Y as latitude. Axis aspect ratio 
%		will be adjusted to approximatively preserve distances (this is  
%		not a real projection!). This overwrites ZRatio option.
%
%	'Legend'
%		Adds legends to the right of graph: elevation scale (colorbar)
%		and a distance scale (in km).
%
%	'FontSize',FS
%		Font size for X and Y tick labels. Default is FS = 10.
%
%	'BorderWidth',BW
%		Border width of the basemap axis, in % of axis height. Must be used
%		together with CARTESIAN or LATLON options. Default is BW = 1%.
%
%
%	--- Decimation options ---
%
%	For optimization purpose, DEM will automatically decimate data to limit
%	to a total of 1500x1500 pixels images. To avoid this, use following
%	options, but be aware that large grids may require huge computer 
%	ressources or induce disk swap or memory errors.
%
%	'Decim',N
%		Decimates matrix Z at 1/N times of the original sampling.
%
%	'NoDecim'
%		Forces full resolution of Z, no decimation.
%
%
%	--- Informations ---
%
%	Colormaps are Mx3 RGB matrix so it is easy to modify saturation 
%	(CMAP.^N), set darker (CMAP/N), lighter (1 - 1/N + CMAP/N), inverse
%	it (flipud(CMAP)), etc...
%
%	To get free worldwide topographic data (SRTM), see READHGT function.
%
%	For backward compatibility, the former syntax is still accepted:
%	DEM(X,Y,Z,OPT,CMAP,NOVALUE,SEACOLOR) where OPT = [A,C,LC,ZMIN,ZMAX,ZC],
%	also option aliases DEC, DMS and SCALE, but there is no argument 
%	checking. Please prefer the param/value syntax.
%
%	Author: François Beauducel <beauducel@ipgp.fr>
%	Created: 2007-05-17
%	Updated: 2013-03-10

%	Copyright (c) 2013, François Beauducel, covered by BSD License.
%	All rights reserved.
%
%	Redistribution and use in source and binary forms, with or without 
%	modification, are permitted provided that the following conditions are 
%	met:
%
%	   * Redistributions of source code must retain the above copyright 
%	     notice, this list of conditions and the following disclaimer.
%	   * Redistributions in binary form must reproduce the above copyright 
%	     notice, this list of conditions and the following disclaimer in 
%	     the documentation and/or other materials provided with the distribution
%	                           
%	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%	POSSIBILITY OF SUCH DAMAGE.

if nargin < 3
	error('Not enough input arguments.');
end

degkm = 6378*pi/180; % one latitude degree in km
sea_color = [.7,.9,1]; % default sea color (light cyan)
grey = 0.2*[1,1,1]; % a dark gray


% -------------------------------------------------------------------------
% --- Manage input arguments

% number of arguments param/value
nargs = 0;

if ~isnumeric(x) | ~isnumeric(y) | ~isnumeric(z)
	error('X,Y and Z must be numeric.')
end

if all(size(x) ~= 1) | all(size(y) ~= 1)
	error('X and Y must be vectors, not matrix.')
end

if length(x) ~= size(z,2) | length(y) ~= size(z,1)
	error('If Z has a size of [M,N], X must have a length of N, and Y a length of M.')
end

% OPTIONS and PARAM/VALUE arguments
			
% AZIMUTH param/value
[s,az] = checkparam(varargin,'azimuth','isscalar');
if s
	nargs = nargs + s;
else
	az = -45; % default
end

% ELEVATION param/value
[s,el] = checkparam(varargin,'elevation','isscalar');
if s
	nargs = nargs + s;
else
	el = 0; % default
end

% CONTRAST param/value
[s,ct] = checkparam(varargin,'contrast','isscalar');
if s
	ct = abs(ct);
	nargs = nargs + s;
else
	ct = 1; % default
end

% LCUT param/value
[s,lcut] = checkparam(varargin,'lcut','isperc');
if s
	nargs = nargs + s;
else
	lcut = .2; % default
end

% NOVALUE param/value
[s,novalue] = checkparam(varargin,'novalue','isscalar');
if s
	nargs = nargs + s;
else
	% default: min value for integer class / NaN for float
	S = whos('z');
	if strfind(S.class,'int')
		novalue = intmin(S.class);
	else
		novalue = NaN;
	end
end

% NANCOLOR param/value
[s,novalue_color] = checkparam(varargin,'nancolor','isrgb');
if s
	nargs = nargs + s;
else
	novalue_color = grey; % default
end

% LANDCOLOR param/value
[s,cland] = checkparam(varargin,'landcolor','isrgb');
if s
	nargs = nargs + s;
else
	% default: landcolor or jet
	if exist('landcolor','file')
		cland = landcolor.^1.3;
	else
		cland = jet(256);
	end
end

% SEACOLOR param/value
[s,csea] = checkparam(varargin,'seacolor','isrgb');
if s
	nargs = nargs + s;
else
	% default: seacolor or single color
	if exist('seacolor','file')
		csea = seacolor;
	else
		csea = sea_color;
	end
end

% COLORMAP param/value
[s,cmap] = checkparam(varargin,'colormap','isrgb');
if s
	cland = [];
	csea = [];
	nargs = nargs + s;
else
	% default
	cmap = cland;
end

% ZLIM param/value
[s,zmm] = checkparam(varargin,'zlim','isvec');
if s
	nargs = nargs + s;
	zmin = min(zmm);
	zmax = max(zmm);
else
	zmin = NaN; % default
	zmax = NaN; % default
end

% ZCUT param/value
[s,zcut] = checkparam(varargin,'zcut','isperc');
if s
	nargs = nargs + s;
else
	zcut = .5; % default
end

% WATERMARK param/value
[s,wmark] = checkparam(varargin,'watermark','isscalar');
if s
	wmark = abs(wmark);
	nargs = nargs + s;
else
	wmark = 0; % default
end

% DECIM param/value and NODECIM option
[s,decim] = checkparam(varargin,'decim','isscalar');
if s
	decim = round(decim);
	nargs = nargs + s;
else
	decim = any(strcmpi(varargin,'nodecim')); % default
	nargs = nargs + 1;
end

% FONTSIZE param/value
[s,fs] = checkparam(varargin,'fontsize','isscalar');
if s
	nargs = nargs + s;
else
	fs = 10; % default
end

% BORDERWIDTH param/value
[s,bw] = checkparam(varargin,'borderwidth','isperc');
if s
	nargs = nargs + s;
else
	bw = 1; % default
end

% options without argument value
km = any(strcmpi(varargin,'km'));
dec = any(strcmpi(varargin,'cartesian') | strcmpi(varargin,'dec'));
dms = any(strcmpi(varargin,'latlon') | strcmpi(varargin,'dms'));
scale = any(strcmpi(varargin,'legend') | strcmpi(varargin,'scale'));
inter = any(strcmpi(varargin,'interp'));
lake = any(strcmpi(varargin,'lake'));

% for backward compatibility (former syntax)...
nargs = nargs + dec + dms + scale + lake + inter + km;

if (nargin - nargs) > 3 & ~isempty(varargin{1})
	opt = varargin{1};
	if ~isnumeric(opt)
		error('OPT = [A,C,S,ZMIN,ZMAX,ZCUT] argument must be numeric.');
	end
	if ~isempty(opt)
		az = opt(1);
	end
	if length(opt) > 1
		ct = opt(2);
	end
	if length(opt) > 2
		lcut = opt(3);
	end
	if length(opt) > 4
		zmin = opt(4);
		zmax = opt(5);
	end
	if length(opt) > 5
		zcut = opt(6);
	end
end

if (nargin - nargs) > 4 & ~isempty(varargin{2})
	cmap = varargin{2};
	csea = [];
end

if (nargin - nargs) > 5 & ~isempty(varargin{3})
	novalue = varargin{3};
end

if (nargin - nargs) > 6 & ~isempty(varargin{4})
	csea = varargin{4};
end


% further test of input arguments
if dms & any(abs(y) > 91)
	error('With LATLON option Y must be in valid latitudes interval (decimal degrees).')
end

if km
	zratio = 1000;
else
	zratio = 1;
end


% -------------------------------------------------------------------------
% --- Pre-process DEM data

% decimates data to avoid disk swap/out of memory...
nmax = 1500;
if decim
	n = decim;
else
	n = ceil(sqrt(numel(z))/nmax);
end
if n > 1
	x = x(1:n:end);
	y = y(1:n:end);
	z = z(1:n:end,1:n:end);
	fprintf('DEM: on the plot data has been decimated by a factor of %d...\n',n);
end

z = double(z); % necessary for most of the following calculations...
z(z==novalue) = NaN;

if inter
	z = fillgap(x,y,z);
end

if isempty(csea)
	k = (z~=0 & ~isnan(z));
else
	k = ~isnan(z);
end

if isnan(zmin)
	zmin = nmedian(z(k),zcut/100);
end
if isnan(zmax)
	zmax = nmedian(z(k),1 - zcut/100);
end
dz = zmax - zmin;


% -------------------------------------------------------------------------
% --- Process lighting

if dz > 0
	% builds the colormap: concatenates seacolor and landcolor around 0
	if ~isempty(csea)
		l = size(csea,1);
		if zmin < 0 & zmax > 0
			r = size(cland,1)*abs(zmin)/zmax/l;
			cmap = cat(1,interp1(1:l,csea,linspace(1,l,round(l*r)),'*linear'),cland);
		elseif zmax <=0
			cmap = csea;
		end
	end
	
	% normalisation of Z using CMAP and convertion to RGB
	I = ind2rgb(uint16((z - zmin)*(size(cmap,1)/dz)),cmap);
	
	if ct > 0
		% computes lighting from elevation gradient
		%[fx,fy] = gradient(z,x,y);
		if dms
			ryz = degkm*1000;
			rxz = degkm*1000*cosd(mean(y));
		else
			rxz = zratio;
			ryz = zratio;
		end
		[xx,yy] = meshgrid(x*rxz,y*ryz);
		[fx,fy,fz] = surfnorm(xx,yy,z);
		[ux,uy,uz] = sph2cart((90-az)*pi/180,el*pi/180,1);
		fxy = fx*ux + fy*uy + fz*uz;
		clear xx yy fx fy fz	% free some memory...
		
		fxy(isnan(fxy)) = 0;

		% computes maximum absolute gradient (median-style), normalizes,
		% saturates and duplicates in 3-D matrix
		li = 1 - abs(sind(el)); % light amplitude (experimental)
		r = repmat(max(min(li*fxy/nmedian(abs(fxy),1 - lcut/100),1),-1),[1,1,3]);
		rp = (1 - abs(r)).^ct;
	
		% applies contrast using exponent
		I = I.*rp;
	
		% lighter for positive gradient
		I(r>0) = I(r>0) + (1 - rp(r>0));
				
	end

	% set novalues / NaN to nancolor
	[i,j] = find(isnan(z));
	if ~isempty(i)
		I(sub2ind(size(I),repmat(i,1,3),repmat(j,1,3),repmat(1:3,size(i,1),1))) = repmat(novalue_color,size(i,1),1);
	end
	
	% lake option
	if lake
		klake = islake(z);
	else
		klake = 0;
	end
	
	% set the seacolor for 0 values
	if ~isempty(csea)
		[i,j] = find(z==0 | klake);
		if ~isempty(i)
			I(sub2ind(size(I),repmat(i,1,3),repmat(j,1,3),repmat(1:3,size(i,1),1))) = repmat(csea(end,:),size(i,1),1);
		end
	end

	if wmark
		I = watermark(I,wmark);
	end
	
	hh = imagesc(x,y,I);
	
else
	
	hh = imagesc(x,y,repmat(shiftdim(sea_color,-1),size(z)));
	text(mean(x),mean(y),'SPLASH!','Color',sea_color/4, ...
		'FontWeight','bold','HorizontalAlignment','center')
	cmap = repmat(sea_color,[256,1]);
	
end

orient tall
axis xy, axis equal, axis tight

xlim = [min(x),max(x)];
ylim = [min(y),max(y)];
zlim = [min([z(z(:) ~= novalue);zmin]),max([z(z(:) ~= novalue);zmax])];

if dms
	% approximates X-Y aspect ratio for this latitude (< 20-m precision for 1x1° grid)
	xyr = cos(mean(y)*pi/180);
else
	xyr = 1;
end

bwy = bw*diff(ylim)/100; % Y border width = 1%
bwx = bwy/xyr; % border width (in degree of longitude)

% axis basemap style
if dec | dms
	axis off

	if diff(xlim) <= diff(ylim)*xyr
		set(gca,'DataAspectRatio',[1,xyr,1])
	else
		set(gca,'DataAspectRatio',[1/xyr,1,1])
	end

	% transparent borders
	patch([xlim(1)-bwx,xlim(2)+bwx,xlim(2)+bwx,xlim(1)-bwx],ylim(1) - bwy*[0,0,1,1],'k','FaceColor','none','clipping','off')
	patch([xlim(1)-bwx,xlim(2)+bwx,xlim(2)+bwx,xlim(1)-bwx],ylim(2) + bwy*[0,0,1,1],'k','FaceColor','none','clipping','off')
	patch(xlim(1) - bwx*[0,0,1,1],[ylim(1)-bwy,ylim(2)+bwy,ylim(2)+bwy,ylim(1)-bwy],'k','FaceColor','none','clipping','off')
	patch(xlim(2) + bwx*[0,0,1,1],[ylim(1)-bwy,ylim(2)+bwy,ylim(2)+bwy,ylim(1)-bwy],'k','FaceColor','none','clipping','off')

	dlon = {'E','W'};
	dlat = {'N','S'};

	if dec
		ddx = dtick(diff(xlim));
		ddy = dtick(diff(ylim));
	else
		ddx = dtick(diff(xlim),1);
		ddy = dtick(diff(ylim),1);
	end

	xtick = (ddx*ceil(xlim(1)/ddx)):ddx:xlim(2);
	for xt = xtick(1:2:end)
		dt = ddx - max(0,xt + ddx - xlim(2));
		patch(repmat(xt + dt*[0,1,1,0]',[1,2]),[ylim(1) - bwy*[0,0,1,1];ylim(2) + bwy*[0,0,1,1]]','k','clipping','off')
		text(xt,ylim(1) - 1.2*bwy,deg2dms(xt,dlon,dec),'FontSize',fs, ...
			'HorizontalAlignment','center','VerticalAlignment','top');
	end

	ytick = (ddy*ceil(ylim(1)/ddy)):ddy:ylim(2);
	for yt = ytick(1:2:end)
		dt = ddy - max(0,yt + ddy - ylim(2));
		patch([xlim(1) - bwx*[0,0,1,1];xlim(2) + bwx*[0,0,1,1]]',repmat(yt + dt*[0,1,1,0]',[1,2]),'k','clipping','off')
		text(xlim(1) - 1.2*bwx,yt,deg2dms(yt,dlat,dec),'FontSize',fs, ...
			'HorizontalAlignment','center','VerticalAlignment','bottom','rotation',90);
		%	'HorizontalAlignment','right','VerticalAlignment','middle');
	end
end

% scale legend
if scale
	%wsc = diff(xlim)*0.01;
	wsc = bwx;
	xsc = xlim(2) + wsc*4;

	if wmark
		cmap = watermark(cmap,wmark);
	end

	% elevation scale (colorbar)
	%zscale = linspace(zlim(1),zlim(2),length(cmap));
	zscale = linspace(zmin,zmax,length(cmap));
	yscale = linspace(0,diff(ylim)/2,length(cmap));
	ysc = ylim(1);
	ddz = dtick(dz*max(0.5*xyr*diff(xlim)/yscale(end),1));
	ztick = (ddz*ceil(zscale(1)/ddz)):ddz:zscale(end);
	patch(xsc + repmat(wsc*[-1;1;1;-1],[1,length(cmap)]), ...
		ysc + [repmat(yscale,[2,1]);repmat(yscale + diff(yscale(1:2)),[2,1])], ...
		repmat(zscale,[4,1]), ...
		'EdgeColor','flat','LineWidth',.1,'FaceColor','flat','clipping','off')
	colormap(cmap)
	caxis([zmin,zmax])
	patch(xsc + wsc*[-1,1,1,-1],ysc + yscale(end)*[0,0,1,1],'k','FaceColor','none','Clipping','off')
	text(xsc + 2*wsc + zeros(size(ztick)),ysc + (ztick - zscale(1))*0.5*diff(ylim)/diff(zscale([1,end])),num2str(ztick'), ...
		'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',8)
	% indicates min and max Z values
	text(xsc,ysc - bwy/2,sprintf('%g m',roundsd(zlim(1),3)),'FontWeight','bold', ...
		'HorizontalAlignment','left','VerticalAlignment','top','FontSize',8)
	text(xsc,ysc + .5*diff(ylim) + bwy/2,sprintf('%g m',roundsd(zlim(2),3)),'FontWeight','bold', ...
		'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',8)
	
	% distance scale
	if dms
		fsc = degkm;
	else
		fsc = zratio/1e3;
	end
	dkm = dtick(diff(ylim)*fsc);
	ysc = ylim(2) - 0.5*dkm/fsc;
	patch(xsc + wsc*[-1,-1,0,0],ysc + dkm*0.5*[-1,1,1,-1]/fsc,'k','FaceColor',grey,'clipping','off')
	if dkm > 1
		skm = sprintf('%g km',dkm);
	else
		skm = sprintf('%g m',dkm*1000);
	end
	text(xsc,ysc,skm,'rotation',-90,'HorizontalAlignment','center','VerticalAlignment','bottom', ...
			'Color',grey,'FontWeight','bold')
end


if nargout > 0
	h = hh;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y = nmedian(x,n)
%NMEDIAN Generalized median filter
%	NMEDIAN(X,N) sorts elemets of X and returns N-th value (N normalized).
%	So:
%	   N = 0 is minimum value
%	   N = 0.5 is median value
%	   N = 1 is maximum value

if nargin < 2
	n = 0.5;
end
y = sort(x(:));
y = interp1(sort(y),n*(length(y)-1) + 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dd = dtick(dlim,deg)
%DTICK Tick intervals

if nargin < 2
	deg = 0;
end

if deg & dlim <= 2/60
	% less than 2 minutes: base 36
	m = 10^floor(log10(dlim*36))/36;
elseif deg & dlim <= 2
	% less than 2 degrees: base 6
	m = 10^floor(log10(dlim*6))/6;
else
	% more than few degrees or not degrees: decimal rules
	m = 10^floor(log10(dlim));
end
p = ceil(dlim/m);
if p <= 1
	dd = .1*m;
elseif p == 2
	dd = .2*m;
elseif p <= 5
	dd = .5*m;
else
	dd = m;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = deg2dms(x,ll,dec)
%DEG2DMS Degree/minute/second display

if dec
	s = sprintf('%7.7g',x);
else
	xa = abs(x) + 1/360000;
	sd = sprintf('%d%c',floor(xa),176);	% ASCII char 176 is the degree sign
	sm = '';
	ss = '';
	if mod(x,1)
		sm = sprintf('%02d''',floor(mod(60*xa,60)));
		sa = floor(mod(3600*xa,60));
		if sa
			ss = sprintf('%02d"',sa);
		else
			if strcmp(sm,'00''')
				sm = '';
			end
		end
	end
	s = [sd,sm,ss,ll{1+int8(x<0)}];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function z = fillgap(x,y,z)
% GRIDDATA is not efficient for large arrays, but has great advantage to be
% included in Matlab's core functions! To optimize interpolation, we
% reduce the amount of relevant data by building a mask of all surrounding
% pixels of novalue areas... playing with linear index!

sz = size(z);
k = find(isnan(z));
k(k == 1 | k == numel(z)) = []; % removes first and last index (if exist)
if ~isempty(k)
	[xx,yy] = meshgrid(x,y);
	mask = zeros(sz,'int8');
	k2 = ind90(sz,k); % k2 is linear index in the row order
	% sets to 1 every previous and next index, both in column and row order
	mask([k-1;k+1;ind90(fliplr(sz),[k2-1;k2+1])]) = 1; 
	mask(k) = 0; % removes the novalue index
	kb = find(mask); % keeps only border values
	z(k) = griddata(xx(kb),yy(kb),z(kb),xx(k),yy(k));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function k2 = ind90(sz,k)

[i,j] = ind2sub(sz,k);
k2 = sub2ind(fliplr(sz),j,i); % switched i and j: k2 is linear index in row order


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function k = islake(z)
% ISLAKE mask of zero gradient on 3x3 tiles
% We use diff matrix in row and column directions, and shift it to build
% a single vectorized test of surrounding pixels. To do this we must
% concatenate unit vectors in different combinations...

dx = diff(z,1,2);	% differences in X direction
dy = diff(z,1,1);	% differences in Y direction
u1 = ones(size(z,1),1);	% row unit vector 
u2 = ones(1,size(z,2));	% column unit vector
u2r = u2(2:end);

% index of the tiles center pixel
k = ( ...
	[u2;dy] == 0 & [dy;u2] == 0 & ...
	[u1,dx] == 0 & [dx,u1] == 0 & ...
	[u1,[dx(2:end,:);u2r]] == 0 & [[dx(2:end,:);u2r],u1] == 0 & ...
	[u1,[u2r;dx(1:end-1,:)]] == 0 & [[u2r;dx(1:end-1,:)],u1] == 0 ...
);

% now extends it to surrounding pixels
k(1:end-1,:) = (k(1:end-1,:) | k(2:end,:));
k(2:end,:) = (k(2:end,:) | k(1:end-1,:));
k(:,1:end-1) = (k(:,1:end-1) | k(:,2:end));
k(:,2:end) = (k(:,2:end) | k(:,1:end-1));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = isrgb(x,n)

if nargin < 2
	n = 0;
end
if isnumeric(x) & (n == 1 & all(size(x) == [1,3]) | n == 0 & size(x,2) == 3) ...
		& all(x(:) >= 0 & x(:) <= 1)
	s = 1;
else
	s = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = isperc(x)

if isnumeric(x) & isscalar(x) & x >= 0 & x <= 100
	s = 1;
else
	s = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = isvec(x,n)

if nargin < 2
	n = 2;
end
if isnumeric(x) & numel(x) == n
	s = 1;
else
	s = 0;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y=roundsd(x,n)

og = 10.^(floor(log10(abs(x)) - n + 1));
y = round(x./og).*og;
y(x==0) = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y = watermark(x,n)

if nargin < 2
	n = 2;
end

if n == 0
    y = x;
else
    y = (x/n + 1 - 1/n);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s,v] = checkparam(arg,nam,typ)

switch typ
	case 'isscalar'
		mes = 'scalar value';
	case 'isperc'
		mes = 'percentage scalar value';
	case 'isvec'
		mes = '2-element vector';
	case 'isrgb'
		mes = '[R,G,B] vector with 0.0 to 1.0 values';
	otherwise
		mes = 'value';
end

s = 0;
v = [];
k = find(strcmpi(arg,nam));
if ~isempty(k)
	if (k + 1) <= length(arg) & isnumeric(arg{k+1}) & feval(typ,arg{k+1})
		v = arg{k+1};
		s = s + 2;
	else
		error('%s option must be followed by a valid %s.',upper(nam),mes)
	end
end
