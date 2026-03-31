% add_anatomical_regions_to_quality_unit_data_structs.m - This script adds 
% the name of the anatomical location to the qualityUnitDataStruct for 
% each animal.
%
%   Inputs:
%       
%       USER MUST SPECIFY VIA UI:
%       (1) miceToAnalyze.mat
%       (2) brainRegions.mat
%       (3) one probe_config .mat file per probe used in experiment
%       (4) folder containing [AK0xx]_D[x]_quality_phy_unit_data.mat files for all mice
%       (5) folder containing contact region assignments  (e.g.
%       contactToRegionIDmap_[AK0xx].mat) for all mice
%
%   Outputs:
%
%       (1) [AK0xx]_aligned_phy_unit_data.mat - one per mouse, containing
%       anatomicLocation and anatomicAbbrev fields within the info field of
%       each unit structure
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: March 24, 2026 (Version 1.0; originally titled "create_channel_to_anatomy_mappings.m")
% Script last updated: March 31, 2026
% Version 2.0.

clc
clear vars
tic

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, pathMice] = uigetfile('*.mat','Select miceToAnalyze.mat file');
load(fullfile(pathMice,file),"mice","nMice","probeIDs","nProbes","uniqueProbeIDs");
% Alternatively, if you want to only re-run this for a specific mouse,
% select that mouse here:


% Load in list of brain regions
% USER INPUT (2): Use UI to select .mat file containing numbered brain
% regions
[file, path] = uigetfile('*.mat',"Select brainRegions.mat file");
load(fullfile(path,file),"brainRegions");

% Set address of folder containing [AK0xx]_D[x]_quality_phy_unit_data.mat
% files for all mice
pathToQualityUnits = uigetdir('',"Select folder containing [AK0xx]_D[x]_quality_phy_unit_data.mat for all mice");
unitFiles = dir(fullfile(pathToQualityUnits,'*.mat'));
if ~(length(unitFiles) == nMice)
    error("Quality Phy Unit Data are missing for some mice.")
end
% extract mouse ID and save it to a field within the files struct
filenames = {unitFiles.name};
mouseIDs = string(extractBefore(filenames,"_"));
for iFile = 1:numel(unitFiles)
    unitFiles(iFile).mouseID = mouseIDs(iFile);
end

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
pathToRegionLabels = uigetdir('',"Select folder containing contact region assignments for all mice");
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


% Create aligned unit folder if it doesn't already exist
if ~isfolder(pathToQualityUnits + "\aligned_phy_unit_data")
    mkdir(pathToQualityUnits + "\aligned_phy_unit_data");
end
saveDir = pathToQualityUnits + "\aligned_phy_unit_data";

clear file path files iFile iMouse iProbe mouse probeID probeLayout

%% For each mouse, append the region label to the info field for each unit,
% and save the quality unit with anatomy data structure 

% Iterate through the mice in 'mice'
for iMouse = 1:nMice

    mouse = mice{iMouse};

    % Load in the quality unit data structure for this mouse
    rowNum = find([unitFiles.mouseID] == mouse);
    path = unitFiles(rowNum).folder;
    file = unitFiles(rowNum).name;
    disp("Loading unit data for " + mouse + "...")
    load(fullfile(path,file),"qualityUnitDataStruct");

    nUnits = numel(fieldnames(qualityUnitDataStruct))-1;
    thisProbeID = probeRegionsTable{probeRegionsTable.mouse == mouse,"probeID"};
    thisProbeLayout = probeConfigurationsTable{probeConfigurationsTable.probeID == thisProbeID,"probeLayout"}{1};
    thisProbeLayout = num2cell(thisProbeLayout);
    thisMouseRegionMap = probeRegionsTable{probeRegionsTable.mouse==mouse,"contactRegionIDs"}{1};

    % for all units associated with this mouse
    for iUnit = 1:nUnits

        thisContact = qualityUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;
        index = find(cellfun(@(x) isequal(x,thisContact), thisProbeLayout));

        if strcmp(thisProbeID,"NeuroNexusA4x16")
            thisRegionID = thisMouseRegionMap(index); %<-- this is where the difference is!!
        elseif strcmp(thisProbeID,"NeuroNexusBuzsaki64spL")
            thisRegionID = thisMouseRegionMap{index}; %<-- this is where the difference is!!
        else
            error("Mismatched probe type!")
        end
        thisRegionName = brainRegions{2,thisRegionID+1}; % Need to add one because the indexing of region names starts at 0.
        thisRegionAbbrev = brainRegions{3,thisRegionID+1}; % Need to add one because the indexing of region names starts at 0.

        qualityUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation = thisRegionName;
        qualityUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev = thisRegionAbbrev;

    end

    alignedUnitDataStruct = qualityUnitDataStruct;

    % Save to a data structure for future use
    saveName = replace(file,"quality","aligned");
    % Export variables in .mat file format
    disp("Saving aligned unit data for " + mouse + "...")
    save(saveDir + "\" + saveName, "alignedUnitDataStruct",'-v7.3');

end

toc