%% assign_region_IDs_to_contacts_for_AK014.m 
% This script allows the user to manually specify the brain region ID for 
% each contact recorded in mouse AK014, based on the results of
% histological imaging. 
% 
% Dependencies:
%       create_list_of_brain_regions_to_include_in_analysis.m - this script
%       defines the mapping from region name to region ID
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: March 30, 2026 (Version 1.0)
% Script last updated: March 30, 2026
% Version 1.0.

mouse = "AK014";

probeID = "NeuroNexusA4x16";

% USER INPUT (1): inline assignment of contact region IDs

% Note: Shank #1 has some ambiguities---need to look more closely at atlas
% (specifically, figure out how to plot the ABA MRI reference atlas)
contactRegionIDs = [ ...
     4 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     8 3 3 3;
     8 3 3 3;
     8 3 3 3;
     8 3 3 3;
     8 8 8 3;
     7 8 8 3;
     7 7 8 3;
     7 7 8 8;
     7 7 9 8;
     7 7 9 9];

% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save electrode contact region assignments to.");
% Export variables in .mat file format
save(saveDir + "\" + "contactToRegionIDmap_" + mouse, "mouse","probeID","contactRegionIDs",'-v7.3');