% consolidate_unit_info_across_all_mice.m - This code is designed to import 
% the data already processed from a single full recording after spike sorting (with
% manual curation and anatomical alignment already applied) and align the 
% spiking activity with odor delivery.
% % Run this script once. --> save significantResults and mice variables to
% "signficantResultsAllMice.mat" file for future use.
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_spikes_grouped_by_odor_trial.mat -- for all mice
%       (4) output path for data structures
%
%
%   Outputs:
%       (1) allUnitInfo.mat
%       
%
%   Dependencies:
%       ...
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: October 1, 2024 (Version 1.0)
% Script last updated: April 01, 2026
% Version 4.0
% (Note: Version 1.0 was titled
% "generate_figures_for_talk_sfn_2024_populationvariability.m"; 
% Version 2.0 was titled
% "generate_figures_for_poster_achems_2025_populationvariability_v2.m";
% Version 3.0 was titled
% generate_figures_for_talk_sfn_2025_populationvariability.m)


%% PART ONE: Load data and get parameters

clear all
clc

baseDir = uigetdir('',"Select base directory from which to navigate.");

mice = ["AK012", "AK013", "AK014", "AK015", "AK024", "AK025", "AK026", "AK027"];
nMice = length(mice);

%% PART TWO: Compile unit information across all animals

% Load and concatenate unit information across all animals
allUnitInfo = struct();
totalUnits = 0;
for i = 1:nMice
    mouse = mice(i);
    
    % load unitInfo from spikes_grouped_by_odor_trial.mat variable file
    [file, path] = uigetfile(".mat","Select [AK0xx]_spikes_grouped_by_odor_trial.mat file for " + mouse + ".",baseDir);
    tic
    disp("Loading unitInfo from spikes grouped by odor trial data structure...")
    load(fullfile(path,file),"mouseLabel","nUnits","unitInfo"); % note: took <3 mins
    toc
    
    fields = fieldnames(unitInfo);
    for iUnit = 1:nUnits
        totalUnits = totalUnits + 1;
        allUnitInfo.("UNIT" + num2str(totalUnits, "%.3d")) = unitInfo.("UNIT" + num2str(iUnit, "%.3d"));
        allUnitInfo.("UNIT" + num2str(totalUnits, "%.3d")).info.mouse = mouse;
    end
end


%% PART THREE: Save compiled data for future use

save(baseDir + "\allUnitInfo.mat","allUnitInfo","totalUnits","mice","nMice",'-v7.3')    