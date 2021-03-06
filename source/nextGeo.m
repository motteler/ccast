%
% nextGeo - read successive GCRSO files
%
% SYNOPSIS
%  [geo, geoTime, timeOK, gi] = nextGeo(glist, gi)
%
% INPUTS
%   glist   - NOAA GCRSO geo file list
%   gi      - previous file index in glist
%
% OUTPUTS
%   geo     - NOAA format 30 x nscan geo struct
%   geoTime - 34 * nscan ES, SP, and IT obs times
%   timeOK  - geoTime valid flags
%   gi      - current file index in glist
%
% DISCUSSION
%   mainly just a wrapper for read_GCRSO
%   geoTime is geo.FORTime extended with SP and IT times
%
% scan times
%   200 200 ...  200  200  200 200 200  200  200 200 200  200  200  200
%   ES1 ES2 ... ES29 ES30 slew SP1 SP2 slew slew IT1 IT2 slew slew slew
%    1   2        29   30   31  32  33   34   35  36  37   38   39   40
%
% sweep times in ms
%   ts = (0:39) * 200;
%   tES = ts(1:30);
%   tSP = ts(32:33);
%   tIT = ts(36:37);
%
% extension of geo.FORTime row 30 to include ES and IT times using
% offsets tcal = [400, 600, 1200, 1400] * 1e3;
%
%     1  2 ... n-1  n
%   1 ---- ... ------ 
%   2 |             |
%   : :     tx      :   tx = double(geo.FORTime); 
%  29 |             |
%  30 ---- ... ------
%   1 ---- ... ------
%   : :     ty      :   ty = ones(4,1) * tx(30,:) + tcal' * ones(1,n);
%   4 ---- ... ------ 
%
%   geoTime = [tx; ty];
%   geoTime = geoTime(:);
%
% QC for individual obs 
%   timeOK = ~isnan(geoTime) & tmin <= geoTime & geoTime <= tmax; 
%
% QC for the current file
%   if sum(timeOK) == 0 or geoTime != unique(geoTime)), skip this
%   file and continue
%

function [geo, geoTime, timeOK, gi] = nextGeo(glist, gi)

% time offsets for calibration looks
tcal = [400, 600, 1200, 1400] * 1e3;

% crude time range checks
tmin = 1.7e15;  % 14-Nov-2011
tmax = 2.4e15;  % 19-Jan-2034

% initialize outputs
geo = struct([]);
geoTime = [];
timeOK = [];

% the following is for timing tests, "if false" skips.  See fakeTime
% parameters and edit as needed.
if false
  if gi < length(glist), 
    gi = gi + 1;
    t0 = dnum2iet(datenum('1 jan 2017 12:00:00'));
%   t0 = t0 + 3 * 8e6;   % 3 scans
%   t0 = t0 + 2.1e3;     % timing error
%   ns = 60; % number of scans per file
    ns = 4; % number of scans per file
    k = 0;   % obs index shift, 0-34 
    geoTime = fakeTime(t0, ns, gi, 0);
    geo.FORtime = reshape(geoTime, 34, ns);
%   timeOK = rand(1, length(geoTime)) > 0;
    timeOK = rand(1, length(geoTime)) > 0.05;
  end
  return % skip the regular nextGeo code
end

% loop on geo file list
no_data = true;
while no_data && gi < length(glist)

  % read the next file
  gi = gi + 1;
  gid = glist(gi).name(11:28);  
  fprintf(1, 'nextGeo: reading geo index %d file %s\n', gi, gid)
  gfile = fullfile(glist(gi).folder, glist(gi).name); 
  try 
    [geo, agatt, attr4] = read_GCRSO(gfile);
  catch
    fprintf(1, 'nextGeo: error reading %s\n', gfile)
    fprintf(1, 'continuing with the next file...\n')
    continue
  end

  % fix geo data missing 1 Jul 2012 leap second for 3 days
  tref = geo.FORTime(1);
  ht0 = dnum2iet(datenum('1 Jul 2012 00:00:00'));
  ht1 = dnum2iet(datenum('3 Jul 2012 18:00:00'));
  if ht0 <= tref & tref < ht1
    geo.FORTime = geo.FORTime + 1e6;
  end

  % add selected attributes to the geo struct
  atmp = ones(4,1) * single([attr4(:).N_Beginning_Orbit_Number]);
  geo.Orbit_Number = atmp(:);
  atmp = ones(4,1) * single([attr4(:).Ascending_Descending_Indicator]);
  geo.Asc_Desc_Flag = atmp(:);

  % geoTime extends geo.FORTime ES times with IT and SP times
  [~, nscanGeo] = size(geo.FORTime);
  tx = double(geo.FORTime);
  ty = ones(4,1) * tx(30, :) + tcal' * ones(1, nscanGeo);
  geoTime = [tx; ty];
  geoTime = geoTime(:);

  % Geo time QC
  timeOK = ~isnan(geoTime) & tmin <= geoTime & geoTime <= tmax;
  if sum(timeOK) == 0 || ~isequal(geoTime(timeOK), unique(geoTime(timeOK)))
    fprintf(1, 'nextGeo: unfixable time errors, skipping file %d\n', gi)
    geo = struct([]);
    geoTime = [];
    geoTimeOK = [];
    continue
  end

  % bad value count as a warning
  nbad = length(timeOK) - sum(timeOK);
  if nbad > 0
    fprintf(1, 'nextGeo: skipping %d bad geo values, file %d\n', nbad, gi)
  end

  % we got someting
  no_data = false;
end

