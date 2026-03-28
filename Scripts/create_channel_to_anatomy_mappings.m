% create_channel_to_anatomy_mappings.m - This script manually defines which 
% brain region each electrode contact is located in, and saves the
% channelToAnatomyTable for each animal. 
%
%   Inputs:
%       
%       USER MUST SPECIFY IN-LINE:
%       (1) brain region assignments for each animal
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
% Script last updated: March 28, 2026
% Version 1.0.

clc
clear vars

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, path] = uigetfile('*.mat','Select miceToAnalyze.mat file');
load(fullfile(path,file),"mice","nMice","probeIDs","nProbes","uniqueProbeIDs");

% Load in list of brain regions
% USER INPUT (2): Use UI to select .mat file containing numbered brain
% regions

% Load in all probe_config files relevant to this experiment
% USER INPUT (3): Use UI to select files containing probe configurations
for iProbe = 1:nProbes
    if iProbe == 1
        [file, path] = uigetfile('*.mat',"Select probe_config file for " + uniqueProbeIDs(iProbe));
    else
        [file, path] = uigetfile('*.mat',"Select probe_config file for " + uniqueProbeIDs(iProbe),path);
    end

    % Store full 
    disp("Loading " + file + "...")
    % load probe_config
    load(fullfile(path,file),"probeID","probeLayout");

    if iProbe == 1
        probeConfigurationsTable = table(probeID,{probeLayout},'VariableNames',{'probeID','probeLayout'});
    else
        probeConfigurationsTable.probeID(iProbe,1) = probeID;
        probeConfigurationsTable.probeLayout{iProbe,1} = probeLayout;
    end

end

%% USER INPUT (3): Manually specify the brain region names in-line

% Note: these assignments are relatively straightforward based on coronal
% histology.
AK012contacts = [ ...
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10;
     3 3 11 10];

% Note: the delineation between iCA1 and vCA1 here is not clear. I made a
% guess.
AK013contacts = [ ...
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

% Note: Shank #1 has some ambiguities---need to look more closely at atlas
% (specifically, figure out how to plot the ABA MRI reference atlas)
AK014contacts = [ ...
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

% Note: 0 means not assigned a region (region undefined)
% Need to get the allen atlas line outline to assess ventral portion of
% these probes
AK015contacts = [ ...
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     3 3 3 3;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0];

% Note: Some of the dentate gyrus contacts on shanks 1 and 2 are in the
% granule cell layer, while the rest are in the molecular layer
AK024contacts = [ ...
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0;
     6 6 6 0];

AK025contacts = [ ...
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     0 0 0 0;
     3 0 0 0;
     3 0 0 0;
     3 0 0 0;
     3 0 0 0;
     3 3 0 0;
     3 3 0 0;
     3 3 0 0;
     3 3 0 0;
     3 3 0 0;
     3 3 0 0;
     3 3 0 0];

% Note: 
AK026contacts = {
    [], [], [],  1, [], [];
    [], [], [],  1, [], [];
    [], [], [],  4, [], [];
    [], [], [], 13, [], [];
    0,  14,  4,  4,  0,  0;
    0,  14,  4,  3,  0,  0;
    0,  14,  4,  3,  0,  0;
    0,  14,  4,  3,  0,  0;
    0,  14,  4,  3,  0,  0;
    0,  14,  3,  3,  0,  0;
    0,  14,  3,  3,  0,  0;
    0,  14,  3,  3,  0,  0;
    0,  14,  3,  3,  0,  0;
    0,   4,  3,  3,  0,  0};

% Note: Feel relatively confident about these, but wouldn't be bad to
% double check if I get the Allen CCF approach working.
AK027contacts = {
    [], [], [], 12, [], [];
    [], [], [],  1, [], [];
    [], [], [],  6, [], [];
    [], [], [], 15, [], [];
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13;
    15, 13, 13, 13, 15, 13};


%% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save channel to anatomy mappings to.");
% Export variables in .mat file format
save(saveDir + "\" + "brainRegions", "brainRegions","nRegions",'-v7.3');

