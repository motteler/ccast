%
% NAME
%   igm2spec - take interferograms to uncalibrated spectra
%
% SYNOPSIS
%   spec = igm2spec(igm, inst);
%
% INPUTS
%   igm   - nchan x 9 x nobs interferograms
%   inst  - instrument interferometric specs
% 
% OUTPUTS
%   spec  - nchan x 9 x nobs count spectra
%
% DISCUSSION
%   the input array actually has nchan+2 points in the first
%   dimension, but the first and last are "guard points" are
%   simply dropped here.
%
%   derived from readspecX and the ccast function ifg2spectra.m
%   with parameter calc's split off into inst_params.m
%
%   needs to be updated to use matlab fftshift w/ proper dimension
%   parameter
%
% AUTHOR
%   H. Motteler, 10 Apr 2012
%

function spec = igm2spec(igm, inst)

band = upper(inst.band);

% shape of input data
[m,n,nifg] = size(igm);

% instrument params
npts = inst.npts;
cind = inst.cind;

% use tind in place of the built-in fftshift, as we don't want 
% a true 2D fft shift, just a shift of all columns in an array
% tind = [npts/2+1 : npts, 1 : npts/2]';

% fix tind so it mimics fftshift for odd-sized point sets
tind = [ceil(npts/2)+1 : npts, 1 : ceil(npts/2)]';

% initialize the output array
spec = zeros(npts, 9, nifg);

% drop the guard points before the FFT
itmp = igm(2:npts+1, :, :);

% do an FFT of shifted data.
stmp = fft(itmp(tind, :, :));

% permute the spectra to match the frequency scale
spec = stmp(cind, :, :);
