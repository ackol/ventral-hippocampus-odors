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
% Script last updated: March 30, 2026
% Version 1.1.

clc
clear vars

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, pathMice] = uigetfile('*.mat','Select miceToAnalyze.mat file');
load(fullfile(pathMice,file),"mice","nMice","probeIDs","nProbes","uniqueProbeIDs");

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

% Load in channel region assignments for these mice
% USER INPUT (4): Use UI to select folder containing region assignments for
% each contact
pathToRegionLabels = uigetdir("Select folder containing contact region assignments for all mice");
files = dir(fullfile(pathToRegionLabels,'*.mat'));
if ~(length(files) == nMice)
    error("Contact region assignments are missing for some mice.")
end
clear probeRegionsTable
for iMouse = 1:nMice
    % load region assignments for each mouse
    load(fullfile(files(iMouse).folder,files(iMouse).name),"mouse","probeID","contactRegionIDs");

    if strcmp(mouse,mice{iMouse})
        if strcmp(probeID,probeIDs{iMouse})
            if iMouse == 1
                probeRegionsTable = table(mouse,probeID,{contactRegionIDs},'VariableNames',{'mouse','probeID','contactRegionIDs'});
            
            else
                probeRegionsTable.mouse(iMouse,1) = mouse;
                probeRegionsTable.probeID(iMouse,1) = probeID;
                probeRegionsTable.contactRegionIDs(iMouse,1) = {contactRegionIDs};
            end
        else
            error("Probe types are not defined consistently for mouse " + mouse + ".")
        end
    else
        error("Mouse names are not defined consistently.")
    end
end


%% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save channel to anatomy mappings to.");
% Export variables in .mat file format
save(saveDir + "\" + "brainRegions", "brainRegions","nRegions",'-v7.3');

