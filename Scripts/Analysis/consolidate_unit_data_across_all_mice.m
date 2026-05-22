% consolidate_unit_data_across_all_mice.m - This code is designed to import 
% the data already processed from a single full recording after spike sorting (with
% manual curation and anatomical alignment already applied) and save all 
% units to a single data structure.
% % Run this script once. --> 
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) miceToAnalyze.mat
%       (2) directory containing [AK0xx]_[Dx]_aligned_phy_unit_data.mat for all mice
%       (3) output path for data structure
%       (4) 
%
%
%   Outputs:
%       (1) allUnitData.mat
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
tic

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, pathMice] = uigetfile('*.mat','Select miceToAnalyze.mat file');
load(fullfile(pathMice,file),"mice","nMice");

% USER INPUT (2): Select directory containing [AK0xx]_[Dx]_aligned_phy_unit_data.mat for all mice 
inputDir = uigetdir('',"Select directory containing [AK0xx]_[Dx]_aligned_phy_unit_data.mat for all mice.");

% USER INPUT (3): Select output directory to save concatenated data
outputDir = uigetdir(inputDir,"Select output directory to save concatenated data:");

% Define file and variable names
outputFileName = "allUnitData.mat";
outputStructVarName = 'allUnitData';
mainStructVarName = "alignedUnitDataStruct";

%% STEP TWO: Compile unit data across all animals

% Initialize an empty structure in memory to hold all combined units. This
% structure will be built up in RAM.
allUnitData = struct();
% Initialize a counter for the UNIT field to facilitate unique naming
unitCounter = 0;

for i = 1:nMice
    mouse = mice(i);

    disp("Loading units obtained from " + mouse)
        
    % Load unit data from this mouse
    % define file name
    pattern = mouse + "_D?_aligned_phy_unit_data.mat";
    % get matching file
    files = dir(fullfile(inputDir,pattern));
    % check results
    if isempty(files)
        error("No matching file found for "+ mouse)
    elseif numel(files) > 1
        error("Multiple matching files found.")
    end
    % load the file
    tic
    fileData = load(fullfile(inputDir, files(1).name),mainStructVarName); %,"mouseLabel","nUnits","unitInfo"); % note: took <3 mins
    toc
    
    currentStruct = fileData.(mainStructVarName);
    
    fields = fieldnames(currentStruct);
    nUnits = length(fields)-1;
    for iUnit = 1:nUnits
        unitCounter = unitCounter + 1; % Increment the global unit counter
        oldUnitName = "UNIT" + num2str(iUnit, "%.3d");
        newUnitName = "UNIT" + num2str(unitCounter, "%.3d");

        % Assign the mouse ID as a subfield in the current unit
        currentStruct.(oldUnitName).info.mouse = string(mouse);

        % Assign the current unit's ID in a subfield in the current unit
        currentStruct.(oldUnitName).info.mouseUnitNumber = iUnit;

        % Check that the quality parameters used were identical across
        % animals
        theseMetrics = currentStruct.qualityMetricSettings;
        if iUnit > 1
            sameProcessing = isequaln(theseMetrics,previousMetrics);
            if ~sameProcessing
                error("The units were not processed identically across animals during the quality control step.")
            end
        end
        previousMetrics = theseMetrics;

        % Assign the contents of the current unit to the output structure
        allUnitData.(newUnitName) = currentStruct.(oldUnitName);

        % Save the global unit ID in a subfield of the new unit
        allUnitData.(newUnitName).info.globalUnitNumber = unitCounter;
    end
end
totalUnits = unitCounter;
allUnitData.qualityMetricSettings = theseMetrics;

%% PART THREE: Save compiled data for future use

disp("Saving concatenated data structure to .mat file...")
tic
save(outputDir + "\allUnitData.mat","allUnitData","totalUnits","mice","nMice",'-v7.3')    
toc
disp("Finished saving data structure to .mat file.")
disp("END OF SCRIPT.")