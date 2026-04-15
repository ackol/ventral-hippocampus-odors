% compare_locomotion_and_odor_tuning.m - This 
% script saves ... 
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) allSpeedScoreInfo.mat
%       (2) significantResultsAllMice.mat
%       (3) allUnitInfo.mat
%   Outputs:
%       (1) display in the command window the fraction of units that are
%       tuned to both speed and odors
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 13, 2026
% Script last updated: April 13, 2026
% Version 1.0.

%% PART 1: Load in Data

clear all
clc

% Load in tested speed scores
[file, path] = uigetfile(".mat","Select testedSpeedScoreInfo.mat file for all mice.");
disp("Loading tested speed scores...")
load(fullfile(path,file)); 

% Load in WSR significant odor tunings
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file.",path);
disp("Loading odor tuned neurons...")
load(fullfile(path,file)); 
nTunedOdorUnitPairs = height(significantResults);

% Load in allUnitInfo
[file, path] = uigetfile(".mat","Select allUnitInfo.mat file.",path);
disp("Loading unit information...")
load(fullfile(path,file)); 

%% PART 2: Assess overlap

% Create lookup table for region based on (mouse ID + unit ID)
allUnits = testedSpeedScores.Mouse + "-" + testedSpeedScores.("Unit #");
assignedRegions = testedSpeedScores.("Anatomical Abbreviation");
allUnits = [allUnits assignedRegions];

% Get list of odor tuned units (mouse ID + unit ID)
odorTunedUnits = significantResults.Mouse + "-" + significantResults.("Unit #");
odorTunedUnits = unique(odorTunedUnits);
nOdorTunedUnits = height(odorTunedUnits);
% Append region
for i = 1:nOdorTunedUnits
    odorTunedUnits(i,2) = allUnits(find(strcmp(allUnits(:,1),odorTunedUnits(i,1))),2);
end

% Get list of speed tuned units (mouse ID + unit ID)
speedTunedUnitsTable = [testedSpeedScores(testedSpeedScores.Classification == "positive speed cell",:); testedSpeedScores(testedSpeedScores.Classification == "negative speed cell",:)];
speedTunedUnits = speedTunedUnitsTable.Mouse + "-" + speedTunedUnitsTable.("Unit #");
nSpeedTunedUnits = height(speedTunedUnits);
% Append region
for i = 1:nSpeedTunedUnits
    speedTunedUnits(i,2) = allUnits(find(strcmp(allUnits(:,1),speedTunedUnits(i,1))),2);
end

% Assess what fraction of speed tuned cells also respond to odors
overlap = intersect(odorTunedUnits(:,1),speedTunedUnits(:,1));
nBoth = length(overlap); % List of units that are tuned to both odor and speed
% Append region
for i = 1:nBoth
    overlap(i,2) = allUnits(find(strcmp(allUnits(:,1),overlap(i,1))),2);
end

disp("Fraction of odor tuned neurons that are speed tuned: " + nBoth/nOdorTunedUnits)
disp("Fraction of speed tuned neurons that are odor tuned: " + nBoth/nSpeedTunedUnits)

% Assess CA1 only
odorTunedUnitsCA1 = [odorTunedUnits(strcmp(odorTunedUnits(:,2),"vCA1"),:); odorTunedUnits(strcmp(odorTunedUnits(:,2),"iCA1"),:)];
nOdorTunedUnitsCA1 = length(odorTunedUnitsCA1);
speedTunedUnitsCA1 = [speedTunedUnits(strcmp(speedTunedUnits(:,2),"vCA1"),:); speedTunedUnits(strcmp(speedTunedUnits(:,2),"iCA1"),:)];
nSpeedTunedUnitsCA1 = length(speedTunedUnitsCA1);
overlapCA1 = [overlap(strcmp(overlap(:,2),"vCA1"),:); overlap(strcmp(overlap(:,2),"iCA1"),:)];
nBothCA1 = length(overlapCA1);

disp("Fraction of odor tuned CA1 neurons that are speed tuned: " + nBothCA1/nOdorTunedUnitsCA1)
disp("Fraction of speed tuned CA1 neurons that are odor tuned: " + nBothCA1/nSpeedTunedUnitsCA1)


% % Assess CA3 only -- not enough speed tuned neurons to be meaningful
% odorTunedUnitsCA3 = [odorTunedUnits(strcmp(odorTunedUnits(:,2),"vCA3"),:); odorTunedUnits(strcmp(odorTunedUnits(:,2),"iCA3"),:)];
% nOdorTunedUnitsCA3 = length(odorTunedUnitsCA3);
% speedTunedUnitsCA3 = [speedTunedUnits(strcmp(speedTunedUnits(:,2),"vCA3"),:); speedTunedUnits(strcmp(speedTunedUnits(:,2),"iCA3"),:)];
% nSpeedTunedUnitsCA3 = length(speedTunedUnitsCA3);
% overlapCA3 = [overlap(strcmp(overlap(:,2),"vCA3"),:); overlap(strcmp(overlap(:,2),"iCA3"),:)];
% nBothCA3 = length(overlapCA3);
% 
% disp("Fraction of odor tuned CA3 neurons that are speed tuned: " + nBothCA3/nOdorTunedUnitsCA3)
% disp("Fraction of speed tuned CA3 neurons that are odor tuned: " + nBothCA3/nSpeedTunedUnitsCA3)

speedAndOdorTunedCells = overlap;
% Save speedAndOdorTunedCells data structure
save(path + "\" + "speedAndOdorTunedCells", "speedAndOdorTunedCells",'-v7.3');