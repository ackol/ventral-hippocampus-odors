% plot_PSTHs_for_all_odorants.m - This script saves N png 
% figures, where N is the number of units recorded for a given mouse. Each 
% figure features M subplots showing the PSTHs for each odorant (where M 
% is the number of odorants on the panel). 
%
%   Inputs:
%   USER MUST SPECIFIY IN-LINE:
%       (1) dataType -- specify if you are processing recorded data from a 
%           single animal or simulated data 
%      
%   USER MUST SPECIFY VIA UI:
%       (1) mouseID (or regionID in case of simulated data)
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

% select spikes_grouped_by_odor_trial.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_spikes_grouped_by_odor_trial.mat file for " + mouseLabel + ".",baseDir);

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
savedirPSTH = baseOutputPath + "\" + "2 - PSTH";
% make new folders if they do not already exist
if ~exist(savedirPSTH,'dir')
    mkdir(savedirPSTH);
end

% load spikes_grouped_by_odor_trial.mat variable file
tic
disp("Loading spikes grouped by odor trial data structure...")
load(fullfile(path,file),"spikeRaster","mouseLabel","timeBefore","timeDuring","timeAfter","sampFreq","nUnits","unitInfo","nOdors","nTrialsPerOdor","odorIdentities"); % note: took <3 mins
toc

disp("Completed PART ONE. Successfully loaded data.")

%% PART 2: Plot spike histograms for each electrode channel for each odorant across trials
clear binWidth binEdges nSamplesPerBin iUnit f iOdorant data yPoints xPoints xPointsSec counts countsR binCounts

nRows = 4;

% Manually set desired bin-width
binWidth = 1; % (seconds)
binEdges = -timeBefore:binWidth:(timeDuring+timeAfter);
nSamplesPerBin = binWidth*sampFreq; % number of sample points per histogram bin

tic
for iUnit = 1:nUnits
        
    disp("-----Processing unit #" + num2str(iUnit) + "-----")

    f = figure('visible','off');
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    if strcmp(dataType,"recorded")
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
        sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    elseif strcmp(dataType,"simulated")
        sgtitle({"Mouse " + mouseLabel, "simulated", "Unit #" + num2str(iUnit) + ", " + thisAnatomicalRegion})
    end
    set(gcf,'Position',[550 50 1500 1300])
    
    for iOdorant = 1:nOdors

    disp("Processing odor #" + num2str(iOdorant))

        data = logical(squeeze(spikeRaster(iOdorant, :,iUnit,:)));
       
        % plot spike histograms
        subplot(nRows,nOdors/nRows,iOdorant)

        counts = sum(data,1);
        % bin the counts
        countsR = reshape(counts,nSamplesPerBin,((timeBefore+timeDuring+timeAfter)/binWidth));
        binCounts = sum(countsR,1);

        histogram('BinCounts', binCounts, 'BinEdges',binEdges)
        hold on
        xlim([-timeBefore timeDuring+timeAfter])
        ylim([0 max(binCounts)+1])
        set(gca,'XAxisLocation','top','TickDir','out') 
        title(odorIdentities{iOdorant})
        %set(gca,'XTick',[],'XAxisLocation','top','TickDir','out') 
        ylabel('Counts');
        rectangle('Position',[0,-0.5,timeDuring,10000],...
                  'FaceColor',[0 .5 .5 0.5],...
                  'FaceAlpha', 0.3, ...
                  'EdgeColor','b',...
                  'LineWidth',0.1)
        hold off

    end

    if strcmp(dataType,"recorded")
        saveas(gcf, savedirPSTH + "\" + mouseLabel + "_sortedcurated_PSTH_unit" + num2str(iUnit, "%.3d") + ".png")
    elseif strcmp(dataType,"simulated")
        saveas(gcf, savedirPSTH + "\" + mouseLabel + "_simulated_PSTH_unit" + num2str(iUnit, "%.3d") + ".png")
    end
    
end
toc

disp("Finished plotting peristimulus time histograms.")

%clear binWidth binEdges nSamplesPerBin iUnit f iOdorant data yPoints xPoints xPointsSec counts countsR binCounts

