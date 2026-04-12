% plot_spike_rasters_for_all_odorants_all_trials.m - This script saves N png 
% figures, where N is the number of units recorded for a given mouse. Each 
% figure features M subplots showing the spike rasters organized by odorant 
% trial (where M is the number of odorants on the panel). 
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_spikes_grouped_by_odor_trial.mat
%       (4) output path for figures
%
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
% Script last updated: March 31, 2026
% Version 5.0.

%% PART ONE: Load data and get parameters

clear all
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% load spikes_grouped_by_odor_trial.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_spikes_grouped_by_odor_trial.mat file for " + mouseLabel + ".",baseDir);
tic
disp("Loading spikes grouped by odor trial data structure...")
load(fullfile(path,file),"spikeRaster","mouseLabel","timeBefore","timeDuring","timeAfter","sampFreq","nUnits","unitInfo","nOdors","nTrialsPerOdor","odorIdentities"); % note: took <3 mins
toc

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
savedirSpikeRasters = baseOutputPath + "\" + "1 - peristimulus spike rasters";
% make new folders if they do not already exist
if ~exist(savedirSpikeRasters,'dir')
    mkdir(savedirSpikeRasters);
end

disp("Completed PART ONE.")

%% PART 4.1: Plot spike rasters for each electrode channel for each odorant across trials
clear iUnit f iOdorant data yPoints xPoints xPointsSec 

nRows = 4;
tic
for iUnit = 1:nUnits
    disp("-----Processing unit #" + num2str(iUnit) + "------")

    f = figure('visible','off');
    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation;
    sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    set(gcf,'Position',[550 50 1500 1300])
    
    for iOdorant = 1:nOdors

    disp("Processing odor #" + num2str(iOdorant))

        data = logical(squeeze(spikeRaster(iOdorant, :,iUnit,:)));
        [yPoints,xPoints] = find(data==1);
        xPointsSec = xPoints/sampFreq - 5;
        
        % plot spike trains
        subplot(nRows,nOdors/nRows,iOdorant)
        plot(xPointsSec,yPoints,'|k','MarkerSize',3);
        hold on
        set(gca,'YDir','reverse');
        xlim([-timeBefore timeDuring+timeAfter])
        set(gca,'XAxisLocation','top','TickDir','out') 
        xlabel('Time (s)');
        ylabel('Trial');
        ylim([0.5 12.5])
        xline(0)
        xline(timeDuring)
        rectangle('Position',[0,-0.5,timeDuring,13], ...
                  'FaceColor',[0 .5 .5 0.5], ...
                  'FaceAlpha', 0.3, ...
                  'EdgeColor','b',...
                  'LineWidth',0.1)
        title(odorIdentities{iOdorant})
        hold off
    end

    saveas(gcf, savedirSpikeRasters + "\" + mouseLabel + "_sortedcurated_spikerasters_unit" + num2str(iUnit, "%.3d") + ".png")

end
toc

disp("Finished plotting peristimulus spike rasters. PART TWO complete.")
disp("Script complete.")
