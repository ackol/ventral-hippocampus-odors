% consolidate_WSR_results_across_all_mice.m - This code is designed to import 
% the data already processed from a single full recording after spike sorting (with
% manual curation and anatomical alignment already applied) and align the 
% spiking activity with odor delivery.
% % Run this script once. --> save significantResults and mice variables to
% "signficantResultsAllMice.mat" file for future use.
%
%   Inputs:
%       (1) ...
%
%
%   Outputs:
%       (1) significantResultsAllMice.mat - contains the following
%       variables:
%               significantResults
%               mice
%       (2) medianDeltaRateAllMice.mat, contains the following variables:
%               medianChangeInRateConcat
%               medianDeltaRate
%               nUnitsPerMouse
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

%% PART TWO: Compile results of WSR statistical testing

% Load and concatenate significant WSR odor-unit pairs across all animals
significantResults = table;
for i = 1:nMice
    mouse = mice(i);
    % load results of wilcoxan signed rank test
    [file, path] = uigetfile(".mat","Select .mat file containing significant results with anatomical locations of WSR test for " + mouse + ".",baseDir);
    tic
    disp("Loading WSR test significant results...")
    load(fullfile(path,file),"wsrTestSignificant"); 
    wsrTestSignificant.Mouse = repmat(mouse,[height(wsrTestSignificant),1]);
    % if there are any signficant modulations from this mouse, concatenate
    % data:
    if height(wsrTestSignificant) > 0
        significantResults = vertcat(significantResults,wsrTestSignificant);
    end
    toc
end

% Load and concatenate median modulations across all unit-odor pairs (significant and not significant)
clear medianChangeInRateConcat medianDeltaRate nUnitsPerMouse totalUnits
medianChangeInRateConcat = [];
medianDeltaRate = struct();
nUnitsPerMouse = [];
for i = 1:nMice
    mouse = mice(i);
    [file, path] = uigetfile(".mat","Select [AK0##]_sortedspikes_curated_medianchangeinrate.mat file containing medianChangeInRate variable for " + mouse + ".",baseDir);
    disp("Loading median change in rate variables...")
    load(fullfile(path,file),"medianChangeInRate"); 

    % Only process data from panel C
    medianChangeInRateConcat = [medianChangeInRateConcat ; medianChangeInRate(:,1:12)];
    medianDeltaRate.(mouse) = medianChangeInRate(:,1:12);
    nUnitsPerMouse = [nUnitsPerMouse, height(medianChangeInRate)];

end

%% PART THREE: Save compiled data for future use

save(baseDir + "\significantResultsAllMice.mat","significantResults","mice",'-v7.3')
save(baseDir + "\medianDeltaRateAllMice.mat","medianChangeInRateConcat","medianDeltaRate","nUnitsPerMouse",'-v7.3')
    