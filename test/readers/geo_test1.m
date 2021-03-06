
addpath ../source

g4dir = '/asl/data/cris2/CrIS-SDR-GEO/20180105';
g4dat = 'GCRSO_j01_d20180105_t1012249_e1012547_b00682_c20180105105310704599_noac_ops.h5';

g60dir = '/asl/data/cris/geo60_npp/2018/002';
g60dat = 'GCRSO_npp_d20180102_t1248319_e1256297_b32037_c20180102185629592831_noac_ops.h5';

g4file = fullfile(g4dir, g4dat);
g60file = fullfile(g60dir, g60dat);

[g4, a4, b4] = read_GCRSO(g4file);

[g60, a60, b60] = read_GCRSO(g60file);

attr4 = b60;
attr4 = b4;

atmp = ones(4,1) * single([attr4(:).N_Beginning_Orbit_Number]);
Orbit_Number = atmp(:);

atmp = ones(4,1) * single([attr4(:).Ascending_Descending_Indicator]);
Asc_Desc_Flag = atmp(:);

whos Orbit_Number Asc_Desc_Flag

