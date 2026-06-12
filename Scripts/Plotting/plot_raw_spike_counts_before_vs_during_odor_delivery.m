% plot_raw_spike_counts_before_vs_during_odor_delivery.m - This script saves N png 
% figures, where N is the number of units recorded for a given mouse. Each 
% figure features M subplots showing the count of spikes occuring immediately 
% before an odorant trial to the count of spikes during the odorant presentation
% (where M is the number of odorants on the panel). 
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_spikes_grouped_by_odor_trial.mat
%       (4) output path for figures
%
%   Outputs:
%       (N) n PNG images (where n = # of units recorded in that animal)
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: September 13, 2024 (originally part of 
% align_sorted_spikes_to_odor_delivery.m from Versions 1.0-4.0)
% Script last updated: June 12, 2026
% Version 6.0.

%% PART ONE: Load data and get parameters

clear all
clc

% USER PARAMETER: IN-LINE
dataType = "simulated"; % options: "simulated" or "recorded"

if strcmp(dataType,"recorded")
    % Manually specify Mouse ID
    mouseLabel = inputdlg('Enter animal ID','User input');
    % select base directory from which to navigate
    baseDir = uigetdir('',"Select base directory for this animal.");
elseif strcmp(dataType,"simulated")
    mouseLabel = inputdlg('Enter region ID (CA1, CA3, or DG):','User input');
    % select base directory from which to navigate
    baseDir = uigetdir('',"Select base directory for simulated data.");
end

% load spikes_grouped_by_odor_trial.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_spikes_grouped_by_odor_trial.mat file for " + mouseLabel + ".",baseDir);
tic
disp("Loading spikes grouped by odor trial data structure...")
load(fullfile(path,file),"spikeRaster","mouseLabel","timeBefore","timeDuring","timeAfter","sampFreq","nUnits","unitInfo","nOdors","nTrialsPerOdor","odorIdentities"); % note: took <3 mins
pointsBefore = timeBefore*sampFreq; 
pointsDuring = timeDuring*sampFreq;
pointsAfter = timeAfter*sampFreq;
toc

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
savedirRawCounts = baseOutputPath + "\" + "3 - raw spike counts";
% make new folder if it does not already exist
if ~exist(savedirRawCounts,'dir')
    mkdir(savedirRawCounts);
end

disp("Completed PART ONE.")

%% PART TWO: Compute spike counts before and during odor delivery

disp("Computing spike counts before and during odor delivery.")

tic

% Preallocate memory for new data structure
beforeCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity
duringCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity

startIndex = pointsBefore-pointsDuring; % start counting spikes from 2 seconds in to trial, 
onsetIndex = startIndex + pointsDuring;
endIndex = onsetIndex + pointsDuring;

for iUnit = 1:nUnits
    disp("Processing unit #" + num2str(iUnit))
    for iOdorant = 1:nOdors
        for iTrial = 1:nTrialsPerOdor
            beforeCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,startIndex:(onsetIndex-1)));
            duringCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,onsetIndex:endIndex));
        end
    end
end
toc

disp("Finished computing before and during spike counts. PART TWO complete.")

%% PART THREE: Plot raw spike counts before and during odor delivery

disp("Plotting raw spike counts before and during odor delivery...")

nRows = 4;

tic
for iUnit = 1:nUnits

    disp("-----Processing unit #" + num2str(iUnit) + "-----")

    f = figure('visible','off');
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    if strcmp(dataType,"recorded")
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
        sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + iUnit, "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    elseif strcmp(dataType,"simulated")
        sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + iUnit + ", " + thisAnatomicalRegion})
    end
    set(gcf,'Position',[550 50 700 1300])

    minY = 0;
    maxY = 0;
    for iOdorant = 1:nOdors
        
        subplot(nRows,nOdors/nRows,iOdorant)

        x = [1 2];
        beforeCountThisOdorant = nan(1,nTrialsPerOdor);
        duringCountThisOdorant = nan(1,nTrialsPerOdor);

        for iTrial = 1:nTrialsPerOdor
            beforeCountThisOdorant(1,iTrial) = beforeCount(iOdorant, iTrial, iUnit);
            duringCountThisOdorant(1,iTrial) = duringCount(iOdorant, iTrial, iUnit);
            y = [beforeCount(iOdorant, iTrial, iUnit) duringCount(iOdorant, iTrial, iUnit)];
            if max(y) > maxY; maxY = max(y);end
            if min(y) < minY; minY = min(y); end
            plot(x,y,'-k.')
            hold on
        end

        % Perform statistical test to evaluate this unit's response to
        % this odorant
        wilcoxanSignedRankTestPValue = signrank(beforeCountThisOdorant, duringCountThisOdorant);   

        % Set plotting parameters
        xlim([0.5 2.5])
        xlabel({'time period relative to', 'odorant delivery'})
        ylabel('spike count')
        xticks([1 2])
        xticklabels({'before','during'})
        title({odorIdentities{iOdorant}, "WSR p-value: " + sprintf('%.3f',wilcoxanSignedRankTestPValue)})
        hold off

    end

    for iOdorant = 1:nOdors
        subplot(nRows,nOdors/nRows,iOdorant)
        ylim([0 maxY*1.05])
    end

    saveas(f, savedirRawCounts + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_rawspikecounts.png")

end

disp("Finished plotting raw spike counts.")