%
% SDR_options -- wrapper to process L1a to SDR data
%
% SYNOPSIS
%   SDR_options(doy, year)
%
% INPUTS
%   day   - integer day of year
%   year  - integer year, default is 2013
%
% DISCUSSION
%   wrapper script to set paths, files, and options for L1a_to_SDR,
%   to process ccast L1a to SDR files.  It can be edited as needed
%   to change options and paths.
%

function L1a_options(doy, year)

% search paths
addpath ../source
addpath ../davet
addpath ../motmsc/time

%-------------------
% data path options
%-------------------

cvers = 'npp';  % CrIS version
nscanSC = 45;   % scans per file

% data home directories
Lhome = '/asl/data/cris/ccast';  % L1a data
Shome = '/asl/data/cris/ccast';  % SDR data

% L1a and SDR directory names
Ldir = sprintf('L1a%02d_%s_H4', nscanSC, cvers);
Sdir = sprintf('sdr%02d_%s_HR', nscanSC, cvers);

% full L1a and SDR paths
dstr = sprintf('%03d', doy);
ystr = sprintf('%d', year);
Lfull = fullfile(Lhome, Ldir, ystr, dstr);
Sfull = fullfile(Shome, Sdir, ystr, dstr);

% L1a file list
s1 = sprintf('CrIS_L1a_%s_s%02d_*.mat', cvers, nscanSC);
flist = dir(fullfile(Lfull, s1));

% create the output path, if needed
unix(['mkdir -p ', Sfull]);

%-------------------------------
% calibration algorithm options
%-------------------------------

opts = struct;            % initialize opts
opts.cal_fun = 'e7';      % calibration algorithm
opts.cvers = cvers;       % current active CrIS
opts.inst_res = 'hires3'; % npp extended res mode
opts.user_res = 'hires';  % high resolution user grid
opts.mvspan = 4;          % moving avg span is 2*mvspan + 1
opts.resamp = 4;          % resampling algorithm
opts.neonWL = 703.44835;  % override eng Neon value

% high-res SA inverse files
opts.LW_sfile = '../inst_data/SAinv_HR3_Pn_LW.mat';
opts.MW_sfile = '../inst_data/SAinv_HR3_Pn_MW.mat';
opts.SW_sfile = '../inst_data/SAinv_HR3_Pn_SW.mat';

% time-domain FIR filter 
opts.NF_file = '../inst_data/FIR_19_Mar_2012.txt';

% NEdN principal component filter
opts.nedn_filt = '../inst_data/nedn_filt_HR.mat';

% 2016 UMBC a2 values
opts.a2LW = [0.0175 0.0122 0.0137 0.0219 0.0114 0.0164 0.0124 0.0164 0.0305];
opts.a2MW = [0.0016 0.0173 0.0263 0.0079 0.0093 0.0015 0.0963 0.0410 0.0016];

%---------------------------------
% take ccast L1a to L1b/SDR files
%---------------------------------

% check that we have some data
if isempty(flist)
  fprintf(1, 'SDR_options: empty L1a file list\n')
  fprintf(1, fullfile(Lfull, s1))
  return
end

% profile clear
% profile on

L1a_to_SDR(flist, Sfull, opts)

% profile report

