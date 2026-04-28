% plot_zoomed_in_section_of_locomotion_firingrate.m - This code is designed 
% to plot overlaid firing rate and running speed in a zoomed-in manner
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
% Script first created: April 17, 2026
% Script last updated: April 17, 2026
% Version 1.0. 

%% PART 1: Load in data

clear vars
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% Manually specify unit of interest
unitNum = inputdlg('Enter unit ID','User input');
unitNum = unitNum{1};
unitNum = str2double(unitNum);

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% select full_session_inst_velocity.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_paired_full_session_inst_velocity.mat file from speed_coding for " + mouseLabel + ".",baseDir);
disp("Loading running velocity data structure...")
load(fullfile(path,file));

% select smoothed_spike_rate_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_spike_rate_data.mat file for " + mouseLabel + ".",baseDir);

% Select directory to save figures
saveFigDir = uigetdir(baseDir,"Select destination directory for plotted figures.");

% Load smoothed_spike_rate_data.mat variable file
disp("Loading smoothed spike rate data structure...")
tic
load(fullfile(path,file));
toc

disp("Completed PART ONE. Successfully loaded data.")



%% PART 2: Plot speed-run plots

disp("Starting PART TWO. Plotting speed-run plots.")

deciSpeed = abs(deciVelocity);
deciSpeedZScore = zscore(deciSpeed);
deciSampFreq = sampFreq/10;

% Plot running-spiking relationship
for iUnit = unitNum
    disp("Processing unit #" + iUnit)

    smoothedSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).continuousFiringRate;
    deciSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).decimatedFiringRate;
    deciSpikeRateZScore = zscore(deciSpikeRate);

    startTime = 7.5; % minutes
    duration = 4; % minutes
    startPoint = startTime*deciSampFreq*60; % sample points
    endPoint = (startTime+duration)*deciSampFreq*60; % sample points
    timeVec = startTime:1/(deciSampFreq*60):(startTime+duration);
    %timeVec = startTime*deciSampFreq:1/deciSampFreq:(startTime+duration)*deciSampFreq;

    fig = figure('Visible','on');
    sgtitle({mouseLabel + " Unit #" + iUnit; smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation})
    % Plot time series
    % subplot(4,3,1:3)
    % plot(timeVec,deciVelocity(startPoint:endPoint),'LineWidth',1.5)
    % ylabel('velocity (cm/s)')

    subplot(3,3,1:3)
    plot(timeVec,deciVelocity(startPoint:endPoint),'c','LineWidth',3)
    hold on
    thisSegment = deciSpeed(startPoint:endPoint);
    plot(timeVec,thisSegment,'b','LineWidth',1.5)
    ylabel('cm/s')
    ylim([-10 max(thisSegment)+3])
    legend({'velocity', 'speed'})

    subplot(3,3,4:6)
    thisSegment = deciSpikeRate(startPoint:endPoint);
    plot(timeVec,thisSegment,'Color', [0.8500 0.3250 0.0980],'LineWidth',1.5)
    ylabel('firing rate (Hz)')
    ylim([-1 max(thisSegment)+5])

    subplot(3,3,7:9)
    plot(timeVec,zscore(deciSpeedZScore(startPoint:endPoint)),'b','LineWidth',1.5)
    hold on
    plot(timeVec,zscore(deciSpikeRateZScore(startPoint:endPoint)),'Color', [0.8500 0.3250 0.0980],'LineWidth',1.5)
    xlabel('time (min)')
    ylabel('z-score')
    legend({'speed', 'firing rate'})
    
    %saveas(gcf, saveFigDir + "\" + mouseLabel + "_running_spiking_relationship_" + num2str(iUnit, "%.3d") + ".png")

end

disp("Completed PART THREE. Successfully saved speed-run plots.")