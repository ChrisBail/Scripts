function [X,I] = rdmseed(f,ef,wo,rl)

% Modifications made by Christian Baillard:

%  line 521 because sometimes D.NumberSamples>length(dd)
%         if D.NumberSamples>length(dd)
%             D.d = cumsum([x0;dd(2:end)]);
%         else
            
%RDMSEED Read miniSEED format file.
%	X = RDMSEED(F) reads file F and returns an M-by-1 structure X containing
%	the M data records of a miniSEED file with header, blockettes, and data
%	in dedicated fields, in particular:
%		- X(i).t = time vector (Matlab datenum format)
%		- X(i).d = data vector
%
%	X = RDMSEED(F,ENCODINGFORMAT,WORDORDER,RECORDLENGTH), when file F does 
%	not include the Blockette 1000, specifies:
%		- ENCODINGFORMAT: FDSN code (see below); default is 10 = Steim-1;
%		- WORDORDER: 1 = big-endian (default), 0 = little-endian;
%		- RECORDLENGTH: must be a power of 2, at least 256 (default is 4096).
%	If the file contains Blockette 1000, these 3 arguments are ignored.
%
%	X = RDMSEED without input argument opens user interface to select the 
%	file from disk.
%
%	[X,I] = RDMSEED(...) returns a structure I with following fields
%		NormalizedRecordInterval: vector of time intervals between each data
%		                          records, normalized to sampling period, i.e.:
%		                           = 1 in perfect case
%		                           < 1 tends to overlapping
%		                           > 1 tends to gapping
%		      OverlapRecordIndex: index of records (into X) having a significant 
%		                          overlap with previous record (less than 
%		                          0.5 sampling period).
%		             OverlapTime: time vector of overlapped blocks (DATENUM format).
%		          GapRecordIndex: index of records (into X) having a significant 
%		                          gap with previous record (more than 1.5 
%		                          sampling period).
%		               I.GapTime: time vector of gapped blocks (DATENUM format).
%
%	RDMSEED(...) with no output argument plots the imported signal by 
%	concatenating all the data records, in one single plot if single channel
%	is detected, or subplots for multi-channels file.
%
%	Some instructions for usage of the returned structure:
%	
%	- to plot concatenated data from a single-channel data file:
%		X = rdmseed(f);
%		plot(cat(1,X.t),cat(1,X.d))
%		datetick('x')
%
%	- to extract a station component 'STAZ' from a multi-channel file:
%		X = rdmseed(f);
%		k = find(strcmp(cellstr(cat(1,D.StationIdentifierCode)),'STAZ'));
%		plot(cat(1,X(k).t),cat(1,X(k).d))
%		datetick('x')
%
%	Known encoding formats are the following FDSN codes:
%		 0: ASCII (untested)
%		 1: 16-bit integer
%		 2: 24-bit integer (untested)
%		 3: 32-bit integer
%		 4: IEEE float
%		 5: IEEE double (untested)
%		10: Steim-1
%		11: Steim-2
%		12: GEOSCOPE 24-bit (untested)
%		13: GEOSCOPE 16/3-bit gain ranged
%		14: GEOSCOPE 16/4-bit gain ranged (untested)
%
%	Author: François Beauducel <beauducel@ipgp.fr>
%		Institut de Physique du Globe de Paris
%	Created: 2010-09-17
%	Updated: 2010-10-02
%
%	References:
%		SEED Reference Manual: SEED Format Version 2.4, May 2010, IFDSN/
%		  IRIS/USGS, http://www.iris.edu
%		libmseed: the Mini-SEED library, Chad Trabant / IRIS DMC, 2010.
%
%	Aknowledgments:
%		Ljupco Jordanovski for his functions, tests and comments.

%	History:
%		[2010-10-02]
%			- Add the input formats for GEOSCOPE multiplexed old data files
%			- Additional output argument with gap and overlap analysis
%			- Create a plot when no output argument are specified
%			- Optimize script coding (30 times faster STEIM decoding!)
%
%		[2010-09-28]
%			- Correction of a problem with STEIM-1 nibble 3 decoding (one 
%			  32-bit difference)
%			- Add reading of files without blockette 1000 with additional
%			  input arguments (like Seismic Handler output files).
%			- Uses warning() function instead of fprintf().
%
%	Copyright (c) 2010, François Beauducel, covered by BSD License.
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

error(nargchk(0,4,nargin))

if nargin < 1
	[filename,pathname] = uigetfile('*');
	f = fullfile(pathname,filename);
end

if ~ischar(f) | ~exist(f,'file')
	error('File %s does not exist.',f);
end

if nargin > 1
	if ~isnumeric(ef) | ~any(ef==[0:5,10:19,30:33])
		error('Argument ENCODINGFORMAT must be a valid FDSN code value.');
	end
else
	ef = 10;
end

if nargin > 2
	if ~isnumeric(wo) | (wo ~= 0 & wo ~= 1)
		error('Argument WORDORDER must be 0 or 1.');
	end
else
	wo = 1;
end

if nargin > 3
	if ~isnumeric(rl) | rl < 256 | rem(log(rl)/log(2),1) ~= 0
		error('Argument RECORDLENGTH must be a power of 2 and greater or equal to 256.');
	end
else
	rl = 2^12;
end

% maximum number of channels for plotting y-labels
max_channel_label = 6;

LittleEndian = 0;

fid = fopen(f,'rb','ieee-be');
header = fread(fid,20,'*char');

% --- tests if the header is mini-SEED
% the 7th character must be one of the "data header/quality indicator", usually 'D'
if isempty(findstr(header(7),'DRMQ'))
	if ~isempty(findstr(header(7),'VAST'))
		s = ' (seems to be a SEED Volume)';
	else
		s = '';
	end
	error('File is not a mini-SEED "data-only"%s. Cannot read it.',s);
end

% --- tests little-endian or big-endian
% if the 2-byte year is greater than 2056, file is probably little-endian
% (Note: idea taken from Ljupco Jordanovski scripts. Thanks!)
Year = fread(fid,1,'uint16');
if Year < 2056
	fseek(fid,0,'bof');
else
	LittleEndian = 1;
	fclose(fid);
	fid = fopen(f,'rb','ieee-le');
end

i = 1;
FileOffset = 0;

while ~feof(fid)
	X(i) = read_data_record(fid,FileOffset,LittleEndian,ef,wo,rl);
	FileOffset = ftell(fid);
	i = i + 1;
	fread(fid,1,'char');	% this is to force EOF=1 on last record.
end

fclose(fid);

% --- analyses data
if nargout > 1
	I.NormalizedRecordInterval = ([diff(cat(1,X.RecordStartTimeMATLAB));NaN]*86400 - cat(1,X.NumberSamples)./cat(1,X.SampleRate))./cat(1,X.SampleRate);
	I.OverlapRecordIndex = find(round(I.NormalizedRecordInterval) < 1) + 1;
	I.OverlapTime = cat(1,X(I.OverlapRecordIndex).RecordStartTimeMATLAB);
	I.GapRecordIndex = find(round(I.NormalizedRecordInterval) > 0) + 1;
	I.GapTime = cat(1,X(I.GapRecordIndex).RecordStartTimeMATLAB);
end


% --- plots the data when no output argument is specified
if nargout == 0

	figure
	
	xlim = [min(cat(1,X.t)),max(cat(1,X.t))];

	% test if all data records have the same sampling rate
	sr = unique(cat(1,X.SampleRate));
	if numel(sr) == 1
		sr_text = sprintf('%g Hz samp.',sr);
	else
		sr_text = sprintf('%d different samp. rates',numel(sr));
	end
	
	% test if all data records have the same encoding format
	ef = unique(cellstr(cat(1,X.EncodingFormatName)));
	if numel(ef) == 1
		ef_text = sprintf('%s',ef{:});
	else
		ef_text = sprintf('%d different encod. formats',numel(ef));
	end
	
	% test if the file is multiplexed or a single channel
	un = unique(cellstr(cat(1,X.ChannelFullName)));
	nc = numel(un);
	
	ns = numel(cat(1,X.d));
	
	if nc == 1
		plot(cat(1,X.t),cat(1,X.d))
		set(gca,'XLim',xlim)
		datetick('x','keeplimits')
		grid on
		xlabel(sprintf('Time\n(%s to %s)',datestr(xlim(1)),datestr(xlim(2))))
		ylabel('Counts')
		title(sprintf('mini-SEED file "%s"\n%s (%d records - %g data - %s - %s)', ...
			f,un{1},length(X),ns,sr_text,ef_text),'Interpreter','none')
	else
		for i = 1:nc
			subplot(nc*2,1,i*2 + (-1:0))
			k = find(strcmp(cellstr(cat(1,X.ChannelFullName)),un{i}));
			plot(cat(1,X(k).t),cat(1,X(k).d))
			set(gca,'XLim',xlim,'FontSize',8)
			if nc > max_channel_label
				set(gca,'YTick',[])
			else
				ylabel(un{i},'Interpreter','none')
			end
			datetick('x','keeplimits')
			set(gca,'XTickLabel',[])
			grid on
			if i == 1
				title(sprintf('mini-SEED file "%s"\n%d channels (%d records - %g data - %s - %s)', ...
					f,length(un),length(X),ns,sr_text,ef_text),'Interpreter','none')
			end
			if i == nc
				datetick('x','keeplimits')
				xlabel(sprintf('Time\n(%s to %s)',datestr(xlim(1)),datestr(xlim(2))))
			end
		end
	end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function D = read_data_record(fid,offset,le,ef,wo,rl)
% read_data_record(FID,OFFSET,LE,EF,WO,RL) reads the data record starting
%	at byte OFFSET (from begining of the open file FID), using parameters
%	LE (=1 for litte-endian file encoding), and default parameters if no
%	Blockette 1000 will be found: EF = encoding format, WO = word order, 
%	and RL = record length.
%	Returns a structure D.

fseek(fid,offset,'bof');

% --- read fixed section of Data Header (48 bytes)
D.SequenceNumber		= fread(fid,6,'*char')';
D.DataQualityIndicator	= fread(fid,1,'*char');
D.ReservedByte			= fread(fid,1,'*char');
D.StationIdentifierCode = fread(fid,5,'*char')';
D.LocationIdentifier	= fread(fid,2,'*char')';
D.ChannelIdentifier		= fread(fid,3,'*char')';
D.NetworkCode			= fread(fid,2,'*char')';
D.ChannelFullName = sprintf('%s:%s:%s',D.NetworkCode,D.StationIdentifierCode,D.ChannelIdentifier);

% Start Time decoding
Year					= fread(fid,1,'uint16');
DayOfYear				= fread(fid,1,'uint16');
Hours					= fread(fid,1,'uint8');
Minutes					= fread(fid,1,'uint8');
Seconds					= fread(fid,1,'uint8=>double');
unused					= fread(fid,1,'uint8');
Seconds0001				= fread(fid,1,'uint16=>double');
D.RecordStartTimeISO = sprintf('%4d-%03d %02d:%02d:%07.4f',Year,DayOfYear,Hours,Minutes,Seconds + Seconds0001/1e4);
D.RecordStartTimeMATLAB = datenum(Year,0,DayOfYear,Hours,Minutes,Seconds + Seconds0001/1e4);

D.NumberSamples			= fread(fid,1,'uint16');

% Sample Rate decoding
SampleRateFactor		= fread(fid,1,'int16=>double');
SampleRateMultiplier	= fread(fid,1,'int16=>double');
if SampleRateFactor > 0
	if SampleRateMultiplier >= 0
		D.SampleRate = SampleRateFactor*SampleRateMultiplier;
	else
		D.SampleRate = -1*SampleRateFactor/SampleRateMultiplier;
	end
else
	if SampleRateMultiplier >= 0
		D.SampleRate = -1*SampleRateMultiplier/SampleRateFactor;
	else
		D.SampleRate = 1/(SampleRateFactor*SampleRateMultiplier);
	end
end

D.ActivityFlags			= fread(fid,1,'uint8');
D.IOFlags				= fread(fid,1,'uint8');
D.DataQualityFlags		= fread(fid,1,'uint8');
D.NumberBlockettesFollow = fread(fid,1,'uint8');
D.TimeCorrection		= fread(fid,1,'float32');
D.OffsetBeginData		= fread(fid,1,'uint16');
D.OffsetFirstBlockette	= fread(fid,1,'uint16');

% --- read the blockettes
OffsetNextBlockette = D.OffsetFirstBlockette;

for i = 1:D.NumberBlockettesFollow
	fseek(fid,offset + OffsetNextBlockette,'bof');
	BlocketteType = fread(fid,1,'uint16');
	
	switch BlocketteType
		
		case 1000
			% BLOCKETTE 1000 = Data Only SEED (8 bytes)
			OffsetNextBlockette = fread(fid,1,'uint16');
            D.BLOCKETTE1000.EncodingFormat = fread(fid,1,'uint8');
			D.BLOCKETTE1000.WordOrder = fread(fid,1,'uint8');
			D.BLOCKETTE1000.DataRecordLength = fread(fid,1,'uint8');
			D.BLOCKETTE1000.Reserved = fread(fid,1,'uint8');
			
		case 1001
			% BLOCKETTE 1001 = Data Extension (8 bytes)
			OffsetNextBlockette = fread(fid,1,'uint16');
			D.BLOCKETTE1001.TimingQuality = fread(fid,1,'uint8');
			D.BLOCKETTE1001.Micro_sec = fread(fid,1,'int8');
			D.BLOCKETTE1001.Reserved = fread(fid,1,'uint8');
			D.BLOCKETTE1001.FrameCount = fread(fid,1,'uint8');
			
		case 100
			% BLOCKETTE 100 = Sample Rate (12 bytes)
			OffsetNextBlockette = fread(fid,1,'uint16');
			D.BLOCKETTE100.ActualSampleRate = fread(fid,1,'float32');
			D.BLOCKETTE100.Flags = fread(fid,1,'uint8');
			D.BLOCKETTE100.Reserved = fread(fid,1,'uint8');
		
		otherwise
			OffsetNextBlockette = fread(fid,1,'uint16');
			warning('Unknown Blockette number %d !\n',BlocketteType);
	end
end

% --- read the data stream
fseek(fid,offset + D.OffsetBeginData,'bof');

if isfield(D,'BLOCKETTE1000')
	EncodingFormat = D.BLOCKETTE1000.EncodingFormat;
	WordOrder = D.BLOCKETTE1000.WordOrder;
	D.DataRecordSize = 2^D.BLOCKETTE1000.DataRecordLength;
else
	EncodingFormat = ef;
	WordOrder = wo;
	D.DataRecordSize = rl;
end

uncoded = 0;

switch EncodingFormat
	
	case 0
		% --- decoding format: ASCII text
		D.EncodingFormatName = 'ASCII';
		D.d = fread(fid,D.DataRecordSize - D.OffsetBeginData,'*char');

	case 1
		% --- decoding format: 16-bit integers
		D.EncodingFormatName = 'INT16';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/2,'*int16');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);
		
	case 2
		% --- decoding format: 24-bit integers
		D.EncodingFormatName = 'INT24';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/3,'bit24=>int32');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);
		
	case 3
		% --- decoding format: 32-bit integers
		D.EncodingFormatName = 'INT32';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/4,'*int32');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);
		
	case 4
		% --- decoding format: IEEE floating point
		D.EncodingFormatName = 'FLOAT32';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/4,'*float');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);
		
	case 5
		% --- decoding format: IEEE double precision floating point
		D.EncodingFormatName = 'FLOAT64';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/8,'*double');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);

	case {10,11}
		% --- decoding formats: STEIM-1 and STEIM-2 compression (c) Dr Joseph Steim
		D.EncodingFormatName = sprintf('STEIM%d',EncodingFormat - 9);
		
		% Steim-1/2 decoding strategy optimized for Matlab
		% -- by F. Beauducel, October 2010 --
		%
		%	1. loads all data into a single 16xM uint32 array
		%	2. gets all nibbles from the first row splitted into 2-bit values
		%	3. for each possible nibble value, selects (find) and decodes
		%	   (bitsplit) all the corresponding words, and stores results
		%	   in a 4xN (STEIM1) or 7xN (STEIM2) array previously filled with
		%	   NaN's. For STEIM2 with nibbles 2 or 3, decodes also dnib values
		%	   (first 2-bit of the word)
		%	5. reduces this array with non-NaN values only
		%	6. integrates with cumsum
		%
		% This method is about 30 times faster than a 'C-like' loops coding...
		
		frame32 = fread(fid,[16,(D.DataRecordSize - D.OffsetBeginData)/64],'*uint32');
		if xor(~WordOrder,le)
			frame32 = swapbytes(frame32);
		end
		x0 = signednbit(frame32(2,1),32);	% forward integration constant
		xn = signednbit(frame32(3,1),32);	% reverse integration constant
		% nibbles is an array of the same size as frame32...
		nibbles = bitand(bitshift(repmat(frame32(1,:),16,1),repmat(-30:2:0,size(frame32,2),1)'),bitcmp(0,2));
		
		if EncodingFormat == 10

			% STEIM-1: 3 cases following the nibbles
			ddd = NaN*ones(4,numel(frame32));	% initiates array with NaN
			k = find(nibbles == 1);				% nibble = 1 : four 8-bit differences
			if ~isempty(k)
				ddd(1:4,k) = bitsplit(frame32(k),32,8);
			end
			k = find(nibbles == 2);				% nibble = 2 : two 16-bit differences
			if ~isempty(k)
				ddd(1:2,k) = bitsplit(frame32(k),32,16);
			end
			k = find(nibbles == 3);				% nibble = 3 : one 32-bit difference
			if ~isempty(k)
				ddd(1,k) = bitsplit(frame32(k),32,32);
			end

		else
		
			% STEIM-2: 7 cases following the nibbles and dnib
			ddd = NaN*ones(7,numel(frame32));	% initiates array with NaN
			k = find(nibbles == 1);				% nibble = 1 : four 8-bit differences
			if ~isempty(k)
				ddd(1:4,k) = bitsplit(frame32(k),32,8);
			end
			k = find(nibbles == 2);				% nibble = 2 : must look in dnib
			if ~isempty(k)
				dnib = bitshift(frame32(k),-30);
				kk = k(dnib == 1);		% dnib = 1 : one 30-bit difference
				if ~isempty(kk)
					ddd(1,kk) = bitsplit(frame32(kk),30,30);
				end
				kk = k(dnib == 2);		% dnib = 2 : two 15-bit differences
				if ~isempty(kk)
					ddd(1:2,kk) = bitsplit(frame32(kk),30,15);
				end
				kk = k(dnib == 3);		% dnib = 3 : three 10-bit differences
				if ~isempty(kk)
					ddd(1:3,kk) = bitsplit(frame32(kk),30,10);
				end
			end
			k = find(nibbles == 3);				% nibble = 3 : must look in dnib
			if ~isempty(k)
				dnib = bitshift(frame32(k),-30);
				kk = k(dnib == 0);		% dnib = 0 : five 6-bit difference
				if ~isempty(kk)
					ddd(1:5,kk) = bitsplit(frame32(kk),30,6);
				end
				kk = k(dnib == 1);		% dnib = 1 : six 5-bit differences
				if ~isempty(kk)
					ddd(1:6,kk) = bitsplit(frame32(kk),30,5);
				end
				kk = k(dnib == 2);		% dnib = 2 : seven 4-bit differences (28 bits!)
				if ~isempty(kk)
					ddd(1:7,kk) = bitsplit(frame32(kk),28,4);
				end
			end
		end
		dd = ddd(~isnan(ddd));		% dd is non-NaN values of ddd
		% rebuilds the data vector by integrating the differences
        if D.NumberSamples>length(dd)
            D.d = cumsum([x0;dd(2:end)]);
        else
            D.d = cumsum([x0;dd(2:D.NumberSamples)]);
        end
		% controlling data integrity...
		if D.d(end) ~= xn
			warning('Problem in %s sequence number %s [%s] : reverse integration not respected.\n',D.EncodingFormatName,D.SequenceNumber,D.RecordStartTimeISO);
		end
		if numel(dd) ~= D.NumberSamples
			fprintf('Problem in %s sequence number %s [%s] : found extra data.\n',D.EncodingFormatName,D.SequenceNumber,D.RecordStartTimeISO);
		end

	case 12
		% --- decoding format: GEOSCOPE multiplexed 24-bit integer
		D.EncodingFormatName = 'GEOSCOPE24';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/3,'bit24=>double');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		D.d = dd(1:D.NumberSamples);
		
	case 13
		% --- decoding format: GEOSCOPE multiplexed 16/3-bit gain ranged
		%	bit 15 = unused
		%	bits 14-12 = 3-bit gain exponent (positive)
		%	bits 11-0 = 12-bit mantissa (positive)
		%	=> data = (mantissa - 2048) / 2^gain
		D.EncodingFormatName = 'GEOSCOPE16-3';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/2,'*uint16');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		dd = (double(bitand(dd,bitcmp(0,12)))-2^11)./2.^double(bitand(bitshift(dd,-12),bitcmp(0,3)));
		D.d = dd(1:D.NumberSamples);
		
	case 14
		% --- decoding format: GEOSCOPE multiplexed 16/4-bit gain ranged
		%	bits 15-12 = 4-bit gain exponent (positive)
		%	bits 11-0 = 12-bit mantissa (positive)
		%	=> data = (mantissa - 2048) / 2^gain
		D.EncodingFormatName = 'GEOSCOPE16-4';
		dd = fread(fid,(D.DataRecordSize - D.OffsetBeginData)/2,'*uint16');
		if xor(~WordOrder,le)
			dd = swapbytes(dd);
		end
		dd = (double(bitand(dd,bitcmp(0,12)))-2^11)./2.^double(bitand(bitshift(dd,-12),bitcmp(0,4)));
		D.d = dd(1:D.NumberSamples);
		
	case 15
		% --- decoding format: US National Network compression
		D.EncodingFormatName = 'USNN';
		uncoded = 1;
		
	case 16
		% --- decoding format: CDSN 16-bit gain ranged
		D.EncodingFormatName = 'CDSN';
		uncoded = 1;
		
	case 17
		% --- decoding format: Graefenberg 16-bit gain ranged
		D.EncodingFormatName = 'GRAEFENBERG';
		uncoded = 1;
		
	case 18
		% --- decoding format: IPG - Strasbourg 16-bit gain ranged
		D.EncodingFormatName = 'IPGS';
		uncoded = 1;
		
	case 19
		% --- decoding format: STEIM-3 compression
		D.EncodingFormatName = 'STEIM3';
		uncoded = 1;
	
	case 30
		% --- decoding format: SRO format
		D.EncodingFormatName = 'SRO';
		uncoded = 1;
		
	case 31
		% --- decoding format: HGLP format
		D.EncodingFormatName = 'HGLP';
		uncoded = 1;
		
	case 32
		% --- decoding format: DWWSSN gain ranged format
		D.EncodingFormatName = 'DWWSSN';
		uncoded = 1;
		
	case 33
		% --- decoding format: RSTN 16-bit gain ranged
		D.EncodingFormatName = 'RSTN';
		uncoded = 1;
		
	otherwise
		D.EncodingFormatName = sprintf('** Unknown encoding format %d **',EncodingFormat);
		uncoded = 1;
		
end

if uncoded
	error('Sorry, the format "%s" is not yet implemented.',D.EncodingFormatName);
end

% makes the time vector
D.t = D.RecordStartTimeMATLAB + (0:(D.NumberSamples-1))'/(D.SampleRate*86400);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d = bitsplit(x,b,n)
% bitsplit(X,B,N) splits the B-bit number X into signed N-bit array
%	X must be uint32 class
%	N ranges from 1 to B
%	B ranges from 1 to 32 and is a multiple of N

sign = repmat((b:-n:n)',1,size(x,1));
x = repmat(x',b/n,1);
d = double(bitand(bitshift(x,flipud(sign-b)),bitcmp(0,n))) ...
	- double(bitget(x,sign))*2^n;

% --- below the former formula for scalar value of X (3 times more efficient)

%d = double(bitand(bitshift(x,(n-b):n:0),bitcmp(0,n))) - double(bitget(x,b:-n:n))*2^n;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function d = signednbit(x,n)
% signednbit(X,N) returns signed N-bit value from unsigned N-bit number X.

d = double(bitand(x,bitcmp(0,n))) - double(bitget(x,n)).*2^n;
