%
% opts_L1a_npp_H2 - wrapper to process NOAA RDR to ccast L1a files
%
% SYNOPSIS
%   opts_L1a_npp_H2(year, doy)
%
% INPUTS
%   year  - integer year
%   doy   - integer day of year
%
% DISCUSSION
%   wrapper to set paths, files, and options to process NOAA RDR to
%   ccast L1a files.  It can be edited as needed to change options
%   and paths.  Processing is done by RDR_to_L1a.
%

function opts_L1a_npp_H2(year, doy)

% search paths
addpath ../source
addpath ../davet
addpath ../motmsc/time
addpath ../readers/MITreader380b
addpath ../readers/MITreader380b/CrIS

%------------------------
% data paths and options
%------------------------

% scans per file
nscanRDR = 60;  % used for initial file selection
nscanGeo = 60;  % used for initial file selection
nscanSC = 45;   % used to define the SC granule format

% NOAA RDR and GCRSO homes
ghome = '/asl/cris/geo60_npp';
rhome = '/asl/cris/rdr60_npp';

% get a CCSDS temp filename
ctmp = ccsds_tmpfile;

% RDR_to_L1a options struct
opts = struct;
opts.cvers = 'npp';
opts.cctag = '20a';
opts.ctmp = ctmp;

% load an initial eng packet 
load('../inst_data/npp_eng_v36_H2')
opts.eng = eng;

%------------------
% build file lists
%------------------

% get previous day
[y0, d0] = prev_doy(year, doy);
ys0 = sprintf('%d', y0);
ds0 = sprintf('%03d', d0);
ys1 = sprintf('%d', year);
ds1 = sprintf('%03d', doy);

% RDR file list
rdir0 = fullfile(rhome, ys0, ds0);
rdir1 = fullfile(rhome, ys1, ds1);
rlist = flist_wrap(rdir0, rdir1, 'RCRIS', nscanRDR);

% Geo file list
gdir0 = fullfile(ghome, ys0, ds0);
gdir1 = fullfile(ghome, ys1, ds1);
glist = flist_wrap(gdir0, gdir1, 'GCRSO', nscanGeo);

% L1a output home
Lhome = '/asl/cris/ccast';
Ldir = sprintf('L1a%02d_%s_H2', nscanSC, opts.cvers);
Lfull = fullfile(Lhome, Ldir, ys1, ds1);

% create the output path, if needed
if exist(Lfull) ~= 7, mkdir(Lfull), end

%-----------------------------------------
% take RDR and Geo to ccast L1b/SDR files
%-----------------------------------------

if isempty(rlist)
  fprintf(1, 'L1a_options: no RDR files found\n')
  return
end

if isempty(glist)
  fprintf(1, 'L1a_options: no Geo files found\n')
  return
end

RDR_to_L1a(rlist, glist, Lfull, opts)

