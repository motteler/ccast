%
% place-holder for high-res non-linearity correction
%

function [nlcorr_cxs, extra] = ...
    nlc(band, iFov, v, scene_cxs, space_cxs, PGA_Gain, control)

if strcmp(upper(band), 'SW')
  nlcorr_cxs = scene_cxs;
  extra = struct;
else
  [nlcorr_cxs, extra] = ...
     nlc_tmp(band, iFov, v, scene_cxs, space_cxs, PGA_Gain, control);
end

