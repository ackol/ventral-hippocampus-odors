% consolidate_velocity_info_across_all_mice.m - This script merges the
% trial-aligned velocity data for all mice into a single table
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) base directory
%       (2) [AK0xx]_effect_of_odor_on_velocity.mat
%       (3) unitLocationsAllMice.mat
%       (4) output path for figure
%
%   Outputs:
%       (1) heatmap showing median change in velocity for all odorants,
%       duplicated for each unit and aligned based on which mouse each unit
%       came from
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 14, 2026
% Script last updated: April 14, 2026 (by Anna C. Kolstad)
% Version 1.0.

%% PART 1: Load in data

clear vars
clc

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for all animals.");

% Load in list of animals
% USER INPUT (1): Use UI to select file containing information about mice
% used in experiment
[file, pathMice] = uigetfile('*.mat','Select miceToAnalyze.mat file',baseDir);
load(fullfile(pathMice,file),"mice","nMice");

% Load in unit location info for all mice
[file, pathMice] = uigetfile('*.mat','Select unitLocationsAllMice.mat file',baseDir);
load(fullfile(pathMice,file));

% select path for data structure
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
saveDir = baseDir;
% make new folder if it does not already exist
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

% Load all velocity test results from each mouse and append together
allVelocityTestResultsTable = table();
for i = 1:nMice
    mouseLabel = mice{i};

    % select [AKxxx]_effect_of_odor_on_velocity.mat variable file
    [file, path] = uigetfile(".mat","Select [AK0xx]_effect_of_odor_on_velocity.mat file for " + mouseLabel + ".",baseDir);
    % load [AKxxx]_effect_of_odor_on_velocity.mat variable file
    disp("Loading effect of odor on velocity data structure...")
    load(fullfile(path,file),"velocityTestResultsTable");

    allVelocityTestResultsTable = [allVelocityTestResultsTable; velocityTestResultsTable];

end

% Save allVelocityTestResultsTable data structure
save(saveDir + "\" + "allVelocityTestResults", "allVelocityTestResultsTable",'-v7.3');



