%
% L1a_npp - ccast RDR to L1a with task ID as day-of-year
%
% SYNOPSIS
%   L1a_npp(year)
%

function L1a_npp(year)

more off
addpath ../source

procid = str2num(getenv('SLURM_PROCID'));
nprocs = str2num(getenv('SLURM_NPROCS'));
nodeid = sscanf(getenv('SLURMD_NODENAME'), '%s');
taskid = str2num(getenv('SLURM_ARRAY_TASK_ID'));

fprintf(1, 'L1a_npp: processing day %d, year %d, node %s\n', ...
            taskid, year, nodeid);

opts_npp_L1a(year, taskid)

