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
% Script last updated: March 24, 2026
% Version 1.0.

clc
clear vars

% Load in list of animals

% Load in all probe_config files relevant to this experiment
% USER INPUT (1): Use UI to select files containing probe configurations
getMoreFiles = true;
nFile = 1;
while getMoreFiles
    if nFile == 1
        [file, path] = uigetfile('*.mat','Select probe_config file');
    else
        [file, path] = uigetfile('*.mat','Select probe_config file',path);
    end

    % If user cancels
    if isequal(file,0)
        break;
    end

    % Store full 
    disp("Loading " + file + "...")
    % load probe_config
    load(fullfile(path,file),"probeID","probeLayout");

    if nFile == 1
        probeConfigurationsTable = table(probeID,{probeLayout},'VariableNames',{'probeID','probeLayout'});
    else
        probeConfigurationsTable.probeID(nFile,1) = probeID;
        probeConfigurationsTable.probeLayout{nFile,1} = probeLayout;
    end

    nFile = nFile + 1;
end

%% USER INPUT (1): Manually specify the brain region names in-line
brainRegions(2,:) = {"dorsal CA1", "intermediate CA1", "ventral CA1", "CA2", ...
    "CA3","dentate gyrus","basolateral amygdalar nucleus, posterior part",...
    "endopiriform nucleus, ventral part","postpiriform transition area",...
    "subiculum", "primary visual area, layer 1"};
nRegions = length(brainRegions);
brainRegions(3,:) = {"dCA1", "iCA1", "vCA1", "CA2", "CA3","DG","BLAp","EPv","TR","SUB","V1"};
brainRegions(1,:) = num2cell(1:1:nRegions);



%% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save brain region list to.");
% Export variables in .mat file format
save(saveDir + "\" + "brainRegions", "brainRegions","nRegions",'-v7.3');

