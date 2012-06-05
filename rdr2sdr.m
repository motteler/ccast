%
% NAME
%   rdr2sdr -- process RDR mat files to SDR mat files
%
% SYNOPSIS
%   [slist, msc] = rdr2sdr(flist, rdir, sdir, opts)
%
% INPUTS
%   flist  - list of RDR mat files
%   rdir   - directory for RDR input files
%   sdir   - directory for SDR output files
%   opts   - for now, everything else
%
% opts fields
%   avgdir   - directory for moving averages
%   mvspan   - span for local moving averages
%   sfileLW, MW, SW  - SRF matrix file by band
%   
% OUTPUTS
%   slist  - list of SDR mat files
%   msc    - optional output struct
%
% DISCUSSION
%
% rdr2sdr is the main function for RDR to SDR processing.
%
% major processing steps are
%   checkRDR   - validate the RDR data
%   scipack    - process sci and eng packets
%   readspec   - take igms to count spectra
%   scanorder  - group data into scans
%   movavg_app - calculate or load moving averages
%   calmain[n] - radiometric and spectral calibration
%
% rdr2sdr is part of a processing chain in which the major steps
% communicate by files, with the following naming scheme
%
%   RDR_<rid>.mat  -- RDR mat files, from rdr2mat
%   avg_<rid>.mat  -- moving average files, from movavg_pre
%   SDR_<rid>.mat  -- SDR mat files, from this procedure
%
% where <rid> is a string of the form tYYYYMMDD_dHHMMSSS taken
% from the original RDR HDF5 file.
%
% rdr2sdr does not directly load the filenames in flist, it builds
% the expected names from <rid> and tries to load that.  The idea is
% that anything that fails to conform to the naming scheme should be
% a fatal error.
%
% If we find pre-calculated moving average files in avgdir, we use
% those instead of locally calculated values
%
% AUTHOR
%  H. Motteler, 20 Feb 2012
%

function [slist, msc] = rdr2sdr(flist, rdir, sdir, opts);

% number of RDR files to process
nfile = length(flist);

% moving average span is 2 * mvspan + 1
mvspan = 4;

% initialize sci and eng packet struct's
eng1 = struct([]);
allsci = struct([]);

% initialize output structs
msc = struct;
slist = struct([]);
nout = 0;

% load geo data, defines structs allgeo, allgid
if exist(opts.geofile, 'file')
  load(opts.geofile)
else
  fprintf(1, 'rdr2sdr: no geo file %s\n', opts.geofile)
  return
end

% -------------------------
% loop on MIT RDR mat files
% -------------------------

for fi = 1 : nfile

  % --------------------------
  % load and validate MIT data
  % --------------------------

  % MIT matlab RDR data file
  rid = flist(fi).name(5:22);
  rtmp = ['RDR_', rid, '.mat'];
  rfile = fullfile(rdir, rtmp);

  % our matlab SDR output file
  stmp = ['SDR_', rid, '.mat'];
  sfile = fullfile(sdir, stmp);

  % moving average filenames
  atmp = ['AVG_', rid, '.mat'];
  afile = fullfile(opts.avgdir, atmp);

  % print a short status message
  if exist(rfile, 'file')
    fprintf(1, 'rdr2sdr: processing index %d file %s\n', fi, rid)
  else
    % skip processing if no matlab RDR file
    fprintf(1, 'rdr2sdr: RDR file missing, index %d file %s\n', fi, rid)
    continue
  end

  % load the RDR data, defines structures d1 and m1
  load(rfile)

  % RDR validation.  checkRDR returns data as nchan x 9 x nobs
  % arrays, ordered by time
  [igmLW, igmMW, igmSW, igmTime, igmFOR, igmSDR] = checkRDRf(d1, rid);

  if isempty(igmTime)
    fprintf(1, 'rdr2sdr: no valid data, skipping file %s\n', rid)
    continue
  end

  % process sci and eng packets
  [sci, eng] = scipack(d1, eng1);

  % this frees up a big chunk of memory
  clear d1

  % skip to next file if we don't have any science packets
  if isempty(sci)
    fprintf(1, 'rdr2sdr: no science packets, skipping file %s\n', rid)
    continue
  end

  % get wlaser from the eng packet data
  wlaser = metlaser(eng.NeonCal);

  % get instrument and user grid parameters
  [instLW, userLW] = inst_params('LW', wlaser);
  [instMW, userMW] = inst_params('MW', wlaser);
  [instSW, userSW] = inst_params('SW', wlaser);

  % -----------------
  % get count spectra
  % -----------------

  rcLW = igm2spec(igmLW, instLW);
  rcMW = igm2spec(igmMW, instMW);
  rcSW = igm2spec(igmSW, instSW);

  [nchLW, m, n] = size(rcLW);
  [nchMW, m, n] = size(rcMW);
  [nchSW, m, n] = size(rcSW);

  clear igmLW igmMW igmSW

  % ---------------------
  % group data into scans
  % ---------------------

  % Move obs to an nchan x 9 x 34 x nscan array, with gaps filled
  % with NaNs.  In the 3rd dim, indices 1:30 are ES data, 31:32 SP,
  % and 33:34 IT.  The time and FOR outputs are 34 x nscan arrays.  
  % Note that if the data from checkRDR has no time or FOR gaps and
  % starts with FOR 1, this is just a reshape.

  [scLW, scMW, scSW, scTime, scFOR] = ...
           scanorder(rcLW, rcMW, rcSW, igmTime, igmFOR, igmSDR, rid);

  [m, n, k, nscan] = size(scLW);

  clear rcLW rcMW rcSW

  % match geo data to scanorder grid
  geo = geo_match(allgeo, scTime);

  % ----------------------------------------------
  % get moving averages of SP and IT count spectra
  % ----------------------------------------------

  if exist(afile) == 2
    load(afile)
  else
    [avgLWSP, avgLWIT] = movavg_app(scLW(:, :, 31:34, :), mvspan);
    [avgMWSP, avgMWIT] = movavg_app(scMW(:, :, 31:34, :), mvspan);
    [avgSWSP, avgSWIT] = movavg_app(scSW(:, :, 31:34, :), mvspan);
  end

  % -----------------------
  % radiometric calibration
  % -----------------------
  
  [rLW, vLW] = calmain4(instLW, userLW, scLW, scTime, ...
                        avgLWIT, avgLWSP, sci, eng, geo, opts);

  [rMW, vMW] = calmain4(instMW, userMW, scMW, scTime, ...
                        avgMWIT, avgMWSP, sci, eng, geo, opts);

  [rSW, vSW] = calmain4(instSW, userSW, scSW, scTime, ...
                        avgSWIT, avgSWSP, sci, eng, geo, opts);

  % save data as an SDR mat file
  save(sfile, ...
       'instLW', 'instMW', 'instSW', 'userLW', 'userMW', 'userSW', ...
       'rLW', 'vLW', 'rMW', 'vMW', 'rSW', 'vSW', 'scTime', ...
       'sci', 'eng', 'geo', 'rid')
  
  % keep a list of the SDR files
  nout = nout + 1;
  slist(nout).file = sfile;

end

