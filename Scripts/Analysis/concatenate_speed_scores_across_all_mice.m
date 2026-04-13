% concatenate_speed_scores_across_all_mice.m - This code is designed to plot two
% histograms, one of the null distribution (produced via circularly
% shuffling the speed vector) and one of the observed speed scores in the
% entire population of units that was recorded
%
%   Inputs:
%       [variable] - ...
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
% Script first created: March 12, 2026
% Script last updated: March 12, 2026
% Version 1.0. 

%% PART ONE: Read in and concatenate data

% Select directory containing observed speed scores for each animal AND
% null shuffled speed score matrices
sourceDir = uigetdir('',"Select source directory for all animals' speed scores.");
files = dir(fullfile(sourceDir, "*.mat"));
nFiles = length(files);

% Concatenate the observed speed score tables
observedSpeedScoresAll = table();
% Concatenate the null speed score matrices
nullSpeedScoresAll = [];
for iFile = 1:nFiles
    load(fullfile(sourceDir, files(iFile).name));

    % If it's an observed speed score file
    if endsWith(files(iFile).name, "_observed_speed_score_data.mat")
        observedSpeedScoresAll = [observedSpeedScoresAll; speedScores];
    elseif endsWith(files(iFile).name, "_null_speed_score_data.mat")
        nullSpeedScoresAll = [nullSpeedScoresAll; nullSpeedScores];
    end
end


%% PART TWO: Save compiled data for future use

saveDir = uigetdir('',"Select destination directory for compiled speed score data structure.");
save(saveDir + "\allSpeedScoreInfo.mat","observedSpeedScoresAll","nullSpeedScoresAll","nShuffles","minimumShiftSec",'-v7.3')    