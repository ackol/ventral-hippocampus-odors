% create_list_of_brain_regions_to_include_in_analysis.m - This script saves 
% a list of the brain regions in which probes contacts were located.
% This ensures that brain region names follow a uniform spelling across
% analyses.
%
%   Inputs:
%       
%       USER MUST SPECIFY IN-LINE:
%       (1) list of brain regions
%
%       USER MUST SPECIFY VIA UI:
%       (2) directory within which to save the brain region list
%
%   Outputs:
%
%       (1) brainRegionIDs.mat - contains two variables:
%               brainRegions - a cell array containing the brain region
%               IDs (in row 1), brain region names (in row 2), and 
%               corresponding brain region abbreviations (in row 3)
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: March 24, 2026 (Version 1.0)
% Script last updated: March 24, 2026
% Version 1.0.

% USER INPUT (1): Manually specify the brain region names in-line
brainRegions(2,:) = {"dorsal CA1", "intermediate CA1", "ventral CA1", "CA2", ...
    "CA3","dentate gyrus","basolateral amygdalar nucleus, posterior part",...
    "endopiriform nucleus, ventral part","postpiriform transition area",...
    "subiculum", "primary visual area, layer 1"};
nRegions = length(brainRegions);
brainRegions(3,:) = {"dCA1", "iCA1", "vCA1", "CA2", "CA3","DG","BLAp","EPv","TR","SUB","V1"};
brainRegions(1,:) = num2cell(1:1:nRegions);

% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save brain region list to.");
% Export variables in .mat file format
save(saveDir + "\" + "brainRegions", "brainRegions","nRegions",'-v7.3');

