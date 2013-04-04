
% compare bcast and IDPS spectra.  
%
% specify a bcast SDR file and scan index, find the corresponding
% IDPS file and scan, and compare selected spectra.  This is simple
% because the bcast SDR files include the gid string from the GCRSO
% file, which is also an identifier for the IDPS SDR files.

addpath /home/motteler/cris/bcast/motmsc/asl

% IDPS SDR channel frequencies
wn_lw = linspace(650-0.625*2,1095+0.625*2,717)';
wn_mw = linspace(1210-1.25*2,1750+1.25*2,437)';
wn_sw = linspace(2155-2.50*2,2550+2.50*2,163)';

% select day-of-the-year
% doy = '054';  % high-res 2nd day
% doy = '136';  % may 15 focus day
% doy = '228';      % includes new geo
doy = '159';      % includes new geo

% get a list of files for this day
byear = '/home/motteler/cris/data/2012';  
bdir  = fullfile(byear, doy);
blist = dir(fullfile(bdir, 'SDR*.mat'));

% choose and load particular file
fi = 40;
bfile = fullfile(bdir, blist(fi).name);
load(bfile)

% select a bcast scan index
bi = 31;

% find the corresponding IDPS SDR file time and scan index
gid = geo.sdr_gid(bi, :);
si = geo.sdr_ind(bi, :);  

% get the IDPS SDR path and filename
syear = '/asl/data/cris/sdr60/hdf/2012';
sdir  = fullfile(syear, doy);
slist = dir(fullfile(sdir, ['SCRIS_npp_', gid, '*.h5']));
sfile = fullfile(sdir, slist(end).name);

% read the IDPS SDR file
pd = readsdr_rawpd(sfile);

% ------------------------
% LW single FOV comparison
% ------------------------

j = 1;   % select a FOV
k = 15;  % select a FOR

% bcast spectra
x1 = vSW';
y1 = real(rad2bt(x1, rSW(:, j, k, bi)));

% IDPS spectra
x2 = wn_sw;
y2 = real(rad2bt(x2, pd.ES_RealSW(:, j, k, si)));

% match frequency grids (IDPS is a subset of bcast)
ix = interp1(x1, 1:length(x1), x2, 'nearest');
x1 = x1(ix);
y1 = y1(ix);

rms(y2 - y1)

% comparison plot
figure (1)
subplot(2,1,1)
plot(x1, y1, x2, y2)
title('bcast and IDPS spectra')
legend('bcast', 'IDPS', 'location', 'best')
grid

subplot(2,1,2)
plot(x1, y1 - y2)
title('bcast - IDPS')
grid

% ------------------------
% LW all 9 FOVs comparison
% ------------------------

k = 15;   % select a FOR

% bcast spectra
x1 = vSW';
y1 = real(rad2bt(x1, rSW(:, :, k, bi)));

% IDPS spectra
x2 = wn_sw;
y2 = real(rad2bt(x2, pd.ES_RealSW(:, :, k, si)));

% match frequency grids (IDPS is a subset of bcast)
ix = interp1(x1, 1:length(x1), x2, 'nearest');
x1 = x1(ix);
y1 = y1(ix, :);

fovnames = {'FOV 1','FOV 2','FOV 3',...
            'FOV 4','FOV 5','FOV 6',...
            'FOV 7','FOV 8','FOV 9'};

% bcast, all 9 fovs
figure (2)
subplot(2,1,1)
plot(x1, y1)
title('bcast, all 9 FOVs')
legend(fovnames, 'location', 'best')
grid

subplot(2,1,2)
plot(x2, y2)
title('IDPS, all 9 FOVs')
legend(fovnames, 'location', 'best')
grid

return  % TEMPORARY

% ----------------
% SW fitting tests
% -----------------

j = 1;   % select a FOV
k = 15;  % select a FOR

% bcast spectra
x1 = vSW;
y1 = real(rad2bt(x1, rSW(:, j, k, bi)));

% IDPS spectra
x2 = wn_sw;
y2 = real(rad2bt(x2, pd.ES_RealSW(:, j, k, si + ds)));

% match frequency grids (IDPS is a subset of bcast)
ix = interp1(x1, 1:length(x1), x2, 'nearest');
x1 = x1(ix);
y1 = y1(ix);

rms(y2 - y1)

% comparison plot
figure (2)
plot(x1, y1, x2, y2)
title('bcast and IDPS spectra')
legend('bcast', 'IDPS', 'location', 'best')
grid
zoom on
