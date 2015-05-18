%
% NAME
%   igm2spec - take interferograms to uncalibrated spectra
%
% SYNOPSIS
%   spec = igm2spec(igm, inst);
%
% INPUTS
%   igm   - nchan x 9 x 34 x nscan interferograms
%   inst  - instrument interferometric specs
% 
% OUTPUTS
%   spec  - nchan x 9 x 34 x nscan count spectra
%
% DISCUSSION
%   works for both inst.npts = nchan and inst.npts + 2 = nchan
%
%   could be updated to use matlab fftshift w/ proper dimension
%   parameter
%
% AUTHOR
%   H. Motteler, 10 Apr 2012
%

function spec = igm2spec(igm, inst)

band = upper(inst.band);

% get number of scans
[m,n,k,nscan] = size(igm);

% instrument params
npts = inst.npts;
cind = inst.cind;

% check if we should drop guard points
if npts + 2 == m
 igm = igm(2:npts+1, :, :, :);
end

% do an FFT of shifted data.
spec = fft(fftshift(igm, 1));

% permute the spectra to match the frequency scale
spec = spec(cind, :, :, :);

