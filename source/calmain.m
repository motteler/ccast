%
% NAME
%   calmain - wrapper to select a calibration algorithm
%
% SYNOPSIS
%   [rcal, vcal, nedn] = ...
%      calmain(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts);
%
% DISCUSSION
%   uses opts.cal_fun to specify the calibration algorithm
%

function [rcal, vcal, nedn] = ...
     calmain(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts)

switch opts.cal_fun
  case 'c6'
    [rcal, vcal, nedn] = ...
       calmain_c6(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts);
  case 'd2'
    [rcal, vcal, nedn] = ...
       calmain_d2(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts);
  case 'e5'
    [rcal, vcal, nedn] = ...
       calmain_e5(inst, user, rcnt, stime, avgIT, avgSP, sci, eng, geo, opts);
  otherwise
    error(sprintf('unknow calibration function %s', opts.cal_fun))
end

