% create_unitLocationsAllMice_table.m - This code is designed
% to ...
%
%   Inputs:
%       ...
%
%   Outputs:
%       ...
%
%   Dependencies:
%       ...
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: November 14, 2025
% Script last updated: April 12, 2026
% Version 2.0.
% Note: Version 1.0 of this script was originally titled
% "create_unitLocationsAllMice_table.m"

%% Create unitLocationsAllMice table

clear mice nMice baseDir unitLocationsAllMice unitCounter i mouse file path

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, pathMice] = uigetfile('*.mat','Select miceToAnalyze.mat file');
load(fullfile(pathMice,file),"mice","nMice");
% Alternatively, if you want to only re-run this for a specific mouse,
% select that mouse here:
%mice = ["AK012"];
% mice = ["AK012", "AK013", "AK014", "AK015", "AK024", "AK025", "AK026", "AK027"];
% nMice = length(mice);

baseDir = uigetdir('',"Select base directory from which to navigate.");

unitLocationsAllMice = table([],strings(0,1),strings(0,1),strings(0,1),'VariableNames',{'unit','anatomical location','anatomical abbreviation','mouse'});

unitCounter = 0; 
for i = 1:nMice
    mouse = mice{i};

    % load spike variable (including contact number)
    [file, path] = uigetfile(".mat","Select .mat file containing goodUnitDataStruct variable for " + mouse + ".", baseDir);
    tic
    disp("Loading good units data structure...")
    load(fullfile(path,file),"goodUnitDataStruct");
    toc
    
    % load anatomical labels for probe contacts
    [file, path] = uigetfile(".mat","Select .mat file containing channelToAnatomyTable variable for " + mouse + ".", baseDir);
    tic
    disp("Loading channelToAnatomyTable structure...")
    load(fullfile(path,file),"channelToAnatomyTable");
    toc
    
    % load mapping between contact number and anatomical location
    [file, path] = uigetfile(".mat","Select .mat file containing all p values of WSR test for " + mouse + ".",baseDir);
    tic
    disp("Loading WSR test p-values...")
    load(fullfile(path,file),"getContactNumber"); 
    toc

    nUnits = numel(fieldnames(goodUnitDataStruct));
    for iUnit = 1:nUnits
        unitCounter = unitCounter + 1;
        unitLocationsAllMice.('unit')(unitCounter) = iUnit;
        unitLocationsAllMice.('mouse')(unitCounter) = mouse;
        
        thisContactNum = getContactNumber(iUnit);
        unitLocationsAllMice.('anatomical location')(unitCounter) = channelToAnatomyTable.('Anatomical Region')(channelToAnatomyTable.Channel==thisContactNum);
    end

end

%% THEN NEED TO MANUALLY CLEAN THE CAPITALIZATION AND ANY TYPOS IN THE ANATOMICAL LOCATION NAMES