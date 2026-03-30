%% assign_region_IDs_to_contacts_for_AK013.m 
% This script allows the user to manually specify the brain region ID for 
% each contact recorded in mouse AK013, based on the results of
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

mouse = "AK013";

probeID = "NeuroNexusA4x16";

% USER INPUT (1): inline assignment of contact region IDs
% Note: the delineation between iCA1 and vCA1 here is not clear. I made a
% guess.
contactRegionIDs = [ ...
     2 2 2 2;
     2 2 2 2;
     4 2 2 2;
     4 2 2 2;
     4 2 2 2;
     5 2 2 2;
     5 2 2 2;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3;
     5 3 3 3];

% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save electrode contact region assignments to.");
% Export variables in .mat file format
save(saveDir + "\" + "contactToRegionIDmap_" + mouse, "mouse","probeID","contactRegionIDs",'-v7.3');