%
% NAME
%   calmain - main calibration procedure
%
% SYNOPSIS
%   [rcal, vcal, msc] = ...
%      calmain(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts);
%
% INPUTS
%   inst    - instrument params struct
%   user    - user grid params struct
%   rcnt    - nchan x 9 x 34 x nscan, rad counts
%   stime   - 34 x nscan, rad count times
%   avgIT   - nchan x 9 x 2 x nscan, moving avg IT rad count
%   avgSP   - nchan x 9 x 2 x nscan, moving avg SP rad count
%   sci     - struct array, data from 8-sec science packets
%   eng     - struct, most recent engineering packet
%   geo     - struct, GCRSO fields from geo_match
%   opts    - for now, everything else
%
% OUTPUTS
%   rcal    - nchan x 9 x 30 x nscan, calibrated radiance
%   vcal    - nchan x 1 frequency grid
%   msc     - optional returned parameters
%
% DISCUSSION
%   The calibration equation is
%
%     r_obs = F * r_ict * f * SA-1 * f * (ES-SP)/(ICT-SP)
%
%   r_obs - calibrated radiance at the user grid
%   F     - fourier interpolation to the user grid
%   r_ict - expected ICT radiance at the sensor grid
%   f     - raised-cosine bandpass filter
%   SA-1  - inverse of the ILS matrix
%   ES    - earth-scene count spectra
%   IT    - calibration target count spectra
%   SP    - space-look count spectra
%
% AUTHOR
%   H. Motteler, 26 Apr 2012
%

function [rcal, vcal, msc] = ...
     calmain(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts)

% get the spectral space numeric filter
inst.sNF = specNF(inst, opts.specNF_file);

% get key dimensions
[nchan, n, k, nscan] = size(rcnt);

% initialize the output array
rcal = ones(nchan, 9, 30, nscan) * NaN;

% initialize working arrays
es_nlc = ones(nchan, 9) * NaN;
sp_nlc = ones(nchan, 9, 2) * NaN;
it_nlc = ones(nchan, 9, 2) * NaN;

% select band-specific options
switch inst.band
  case 'LW', sfile = opts.LW_sfile;
  case 'MW', sfile = opts.MW_sfile;
  case 'SW', sfile = opts.SW_sfile;
end

% get SRF matrix for the current wlaser
Smat = getSRFwl(inst.wlaser, sfile);

% take the inverse after interpolation
Sinv = zeros(nchan, nchan, 9);
for i = 1 : 9
  Sinv(:,:,i) = inv(squeeze(Smat(:,:,i)));
end

% loop on scans
for si = 1 : nscan 
 
  % check that this row has some ES's
  if isnan(max(stime(1:30, si)))
    continue
  end

  % get index of the closest sci record, 
  dt = abs(max(stime(:, si)) - [sci.time]);
  ix = find(dt == min(dt));

  % compute ICT temperature
  T_ICT = (sci(ix).T_PRT1 + sci(ix).T_PRT2) / 2;

  % Compute predicted radiance from ICT
  B = ICTradModel(inst.band, inst.freq, T_ICT, sci(ix), eng.ICT_Param, ...
                  1, NaN, 1, NaN);

  % copy rIT across 30 columns
  rIT = B.total(:) * ones(1, 30);

  % loop on sweep directions
  for k = 1 : 2

    % do the SP and IT nonlinearity corrections
    sp_nlc(:, :, k) = nlc_vec(inst, avgSP(:, :, k, si), ...
                                    avgSP(:, :, k, si), eng);

    it_nlc(:, :, k) = nlc_vec(inst, avgIT(:, :, k, si), ...
                                    avgSP(:, :, k, si), eng);
  end

  % loop on earth-scenes
  for iES = 1 : 30

    % the ES and calibration indices have opposite parity
    k = mod(iES, 2) + 1;

    % do the ES nonlinearity correction
    es_nlc = nlc_vec(inst, rcnt(:, :, iES, si), ...
                          avgSP(:, :,  k,  si), eng);   

    % calculate (ES-SP)/(ICT-SP), accounting for sweep direction
    rcal(:, :, iES, si) = ...
      (es_nlc - sp_nlc(:,:,k)) ./ (it_nlc(:,:,k) - sp_nlc(:,:,k));

  end

  % loop on FOVs, apply the bandpass and SA-1 transforms
  % note we are vectorizing in chunks of size nchan x 30 here
  for fi = 1 : 9

    rtmp = squeeze(rcal(:,fi,:,si));  

    rtmp = bandpass(inst.freq, rtmp, user.v1, user.v2, user.vr);

    rtmp = rIT .* (Sinv(:,:,fi) * rtmp);

    rtmp = bandpass(inst.freq, rtmp, user.v1, user.v2, user.vr);

    [rtmp, vcal] = finterp(rtmp, inst.freq, user.dv);

    rtmp = bandpass(vcal, rtmp, user.v1, user.v2, user.vr);

    % save the current nchan x 30 chunk
    [n,k] = size(rtmp);
    n = min(n, nchan);
    rcal(1:n,fi,:,si) = rtmp(1:n, :);

  end      % loop on FOVs
end        % loop on scans

% trim to interpolated channel set
vcal = vcal(1:n);
rcal = rcal(1:n, :, :, :);
msc = struct;

