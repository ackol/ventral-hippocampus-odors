% extract_unit_data_by_brain_regions_of_interest.m - This code is designed 
% to output one data structure per brain region of interest containing all
% of the units recorded from that brain region
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) allUnitData.mat
%       (2) output path for data structures
%
%      USER MUST SPECIFY IN-LINE:
%       (1) abbreviations of brain regions to extract
%
%
%   Outputs:
%       (1) CA1UnitData.mat
%       (2) CA3UnitData.mat
%       (3) DGUnitData.mat
%       
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: May 22, 2026 (Version 1.0)
% Script last updated: May 22, 2026
% Version 1.0

%% STEP ONE: Load data and get parameters

clc
clear all

% USER INPUT (1): Use UI to select file containing data from all recorded
% units
[file, path] = uigetfile('*.mat','Select allUnitData.mat file');
tic
disp("Loading allUnitData.mat variables...")
load(fullfile(path,file),"allUnitData","totalUnits");
toc

% USER INPUT (2): Select output directory to save extracted data
outputDir = uigetdir(path,"Select output directory to save extracted data:");

% USER INPUT (3): Define in-line which regions to extract
regionsOfInterest = ["CA1","CA3","DG"];
% Define file and variable names
outputFileNames = ["CA1UnitData.mat","CA3UnitData.mat","DGUnitData.mat"];
outputStructVarNames = ["CA1UnitData","CA3UnitData","DGUnitData"];
mainStructVarName = "allUnitData";


%% STEP TWO: Extract unit data from each brain region

% Initialize an empty structure in memory to hold all combined units. This
% structure will be built up in RAM.
CA1UnitData = struct();
CA3UnitData = struct();
DGUnitData = struct();

% Initialize a counter for the UNIT field to facilitate unique naming
globalUnitCounter = 0;
CA1UnitCounter = 0;
CA3UnitCounter = 0;
DGUnitCounter = 0;

% Loop through all the units and save units to the corresponding brain
% region data structure (when applicable)
for iUnit = 1:totalUnits
    globalUnitCounter = globalUnitCounter + 1; % Increment the global unit counter
    oldUnitName = "UNIT" + num2str(iUnit, "%.3d");
    region = allUnitData.(oldUnitName).info.anatomicAbbrev;
    if strcmp(region,"CA1") || strcmp(region,"iCA1") || strcmp(region,"vCA1")
        CA1UnitCounter = CA1UnitCounter + 1;
        newUnitName = "UNIT" + num2str(CA1UnitCounter, "%.3d");
        % Assign the contents of the current unit to the output structure
        CA1UnitData.(newUnitName) = allUnitData.(oldUnitName);
    elseif strcmp(region,"CA3") || strcmp(region,"iCA3") || strcmp(region,"vCA3")
        CA3UnitCounter = CA3UnitCounter + 1;
        newUnitName = "UNIT" + num2str(CA3UnitCounter, "%.3d");
        % Assign the contents of the current unit to the output structure
        CA3UnitData.(newUnitName) = allUnitData.(oldUnitName);
    elseif strcmp(region,"DG")
        DGUnitCounter = DGUnitCounter + 1;
        newUnitName = "UNIT" + num2str(DGUnitCounter, "%.3d");
        % Assign the contents of the current unit to the output structure
        DGUnitData.(newUnitName) = allUnitData.(oldUnitName);
    end

end
totalCA1Units = CA1UnitCounter;
totalCA3Units = CA3UnitCounter;
totalDGUnits = DGUnitCounter;

% Transfer the quality parameter settings to each new data structure
qualityMetrics = allUnitData.qualityMetricSettings;
CA1UnitData.qualityMetricSettings = qualityMetrics;
CA3UnitData.qualityMetricSettings = qualityMetrics;
DGUnitData.qualityMetricSettings = qualityMetrics;


%% PART THREE: Save compiled data for future use

disp("Saving extracted CA1 unit data structure to .mat file...")
tic
save(outputDir + "\CA1UnitData.mat","CA1UnitData","totalCA1Units",'-v7.3')    
toc
disp("Saving extracted CA3 unit data structure to .mat file...")
tic
save(outputDir + "\CA3UnitData.mat","CA3UnitData","totalCA3Units",'-v7.3')    
toc
disp("Saving extracted DG unit data structure to .mat file...")
tic
save(outputDir + "\DGUnitData.mat","DGUnitData","totalDGUnits",'-v7.3')    
toc
disp("Finished saving data structures to .mat file.")
disp("END OF SCRIPT.")