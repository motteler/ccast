%
% NAME
%   ccast_main -- wrapper to process matlab RDR to SDR data
%
% SYNOPSIS
%   ccast_main(doy, year)
%
% INPUTS
%   day   - integer day of year
%   year  - integer year, default is 2013
%
% DISCUSSION
%   This is a wrapper script to set paths, files, and options to
%   process matlab RDR to SDR files.  It can be edited as needed     
%   to change options and paths.  The actual processing is done by
%   rdr2sdr.m
%
%   ccast_main is the last of several processing steps, and uses
%   matlab RDR files and geo daily summary data from scripts such 
%   as rdr2mat.m and geo_daily.m
%

function ccast_main(doy, year)

% year and day-of-year as strings
ystr = sprintf('%d', year);
dstr = sprintf('%0.3d', doy);

%-------------------------
% set paths and get files 
%-------------------------

% search source, then davet
addpath ../davet
addpath ../source

% path to matlab RDR input files
rhome = '/asl/data/cris/ccast/rdr60';
rdir = fullfile(rhome, ystr, dstr);
flist = dir(fullfile(rdir, 'RDR*.mat'));
% flist = flist(61:64);

% path to matlab SDR output files
shome = '/asl/data/cris/ccast/sdr60';
sdir = fullfile(shome, ystr, dstr);
unix(['mkdir -p ', sdir]);

% path to geo data, allgeo<yyyymmdd>.mat
ghome = '/asl/data/cris/ccast/daily';
tmp = datestr(datenum(year,1,1) + doy - 1, 30);
geofile = fullfile(ghome, ystr, ['allgeo', tmp(1:8), '.mat']);

%----------------------------
% set opts struct parameters
%----------------------------

opts = struct;            % initialize opts
opts.cal_fun = 'e5';      % calibration function
opts.version = 'snpp';    % current active CrIS
opts.inst_res = 'lowres'; % low resolution sensor grid
opts.user_res = 'lowres'; % low resolution user grid
opts.geofile = geofile;   % geo filename for this doy
opts.mvspan = 4;          % moving avg span is 2*mvspan + 1

% low-res SA inverse files
opts.LW_sfile = '../inst_data/SAinv_LR_Pn_ag_LW.mat';
opts.MW_sfile = '../inst_data/SAinv_LR_Pn_ag_MW.mat';
opts.SW_sfile = '../inst_data/SAinv_LR_Pn_ag_SW.mat';

% time-domain FIR filter 
opts.NF_file = '../inst_data/FIR_19_Mar_2012.txt';

% NEdN principal component filter
opts.nedn_filt = '../inst_data/nedn_filt_LR.mat';

% 2016 UMBC a2 values
  opts.a2LW = [0.0175 0.0122 0.0137 0.0219 0.0114 0.0164 0.0124 0.0164 0.0305];
  opts.a2MW = [0.0016 0.0173 0.0263 0.0079 0.0093 0.0015 0.0963 0.0410 0.0016];

% 2016 UW values via Yong Chen
% opts.a2MW = [0.0033 0.0178 0.0271 0.0073 0.0104 0.0024 0.0936 0.0434 0.0026];

% current default a2 values (from eng and inst params)
% opts.a2LW = [0.0194 0.0143 0.0161 0.0219 0.0134 0.0164 0.0146 0.0173 0.0305];
% opts.a2MW = [0.0053 0.0216 0.0292 0.0121 0.0143 0.0037 0.1070 0.0456 0.0026];

%--------------------------------
% process matlab RDR to SDR data 
%--------------------------------

% profile clear
% profile on

rdr2sdr(flist, rdir, sdir, opts);

% profile viewer

