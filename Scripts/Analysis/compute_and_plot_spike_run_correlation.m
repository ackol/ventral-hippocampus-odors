% COMPUTE_AND_PLOT_SPIKE_RUN_CORRELATION.m - This script saves N png 
% figures, where N is the number of units recorded for a given mouse. Each 
% figure features subplots showing the running speed across the experiment, 
% the spike rate across the experiment, the two z-scored and overlaid, and 
% also a plot of the run velocity vs. spike rate and statistical measures 
% of correlation.  
%
% These analyses and figures recapitulate Figure 1 from 
% Góis, Z. H. T. D. & Tort, A. B. L. Characterizing Speed Cells in the Rat 
% Hippocampus. Cell Reports 25, 1872-1884.e4 (2018).
% https://www.sciencedirect.com/science/article/pii/S2211124718316437?via%3Dihub#fig1
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:regio
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_smoothed_spike_rate_data.mat
%       (4) [AK0xx]_paired_full_session_inst_velocity.mat
%       (5) significantResultsAllMice.mat
%       (6) directory in which to save outputs
%
%   Outputs:
%       (1) [AK0xx]_D[x]_observed_speed_score_data.mat
%       (2) [AK0xx]_D[x]_null_speed_score_data.mat
%       (3) Autocorrelogram of animal's run speed (PNG image) 
%       (4) Histogram showing speed scores of null vs. observed
%       distributions (PNG image)
%       (N) speed-spike correlation for each unit (n PNG images, where n = 
%       # of units recorded in this animal)
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 2, 2026 (by Anna C. Kolstad)
% Script last updated: April 13, 2026 (by Anna C. Kolstad)
% Note: Versions 1-2 of this script were titled
% "plot_spike_run_correlation.m"
% Version 3.0.

%% PART ONE: Load data and get parameters
clear vars
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% % select aligned_phy_unit_data.mat variable file
% [file, path] = uigetfile(".mat","Select [AK0xx]_aligned_phy_unit_data.mat file for " + mouseLabel + ".",baseDir);
% disp("Loading aligned phy unit data structure...")
% load(fullfile(path,file));

% select full_session_inst_velocity.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_paired_full_session_inst_velocity.mat file from speed_coding for " + mouseLabel + ".",baseDir);
disp("Loading running velocity data structure...")
load(fullfile(path,file));

% select significantResultsAllMice.mat variable file
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file for " + mouseLabel + ".",baseDir);
disp("Loading significant results data structure...")
load(fullfile(path,file));

% select smoothed_spike_rate_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_spike_rate_data.mat file for " + mouseLabel + ".",baseDir);

% select path for output data structures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs (choose directory named speed_coding).");
saveDataDir = baseOutputPath + "\" + "speed_scores";
% make new folders if they do not already exist
if ~exist(saveDataDir,'dir')
    mkdir(saveDataDir);
end
% define path for output figures
saveFigDir = saveDataDir + "\" + "figures";
% make new folders if they do not already exist
if ~exist(saveFigDir,'dir')
    mkdir(saveFigDir);
end

% Load smoothed_spike_rate_data.mat variable file
disp("Loading smoothed spike rate data structure...")
tic
load(fullfile(path,file));
toc

disp("Completed PART ONE. Successfully loaded data.")

%% PART TWO: Compute speed score for each unit

disp("Starting PART TWO. Plotting speed-run plots.")

wheelSpeed = abs(wheelVelocity);
nUnits = numel(fieldnames(smoothedSpikeRateStruct));

% Get speed scores
speedScores = table('Size',[nUnits 5], 'VariableTypes', {'int16','double','string','string','string'},'VariableNames',{'Unit #','Pearson correlation','Anatomical Location','Anatomical Abbreviation','Mouse'});
for iUnit = 1:nUnits
    disp("Processing unit #" + iUnit + "/" + nUnits)

    smoothedSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).continuousFiringRate;

    [r, p] = corr(smoothedSpikeRate,wheelSpeed');

    % Populate speed score data structure
    speedScores.("Unit #")(iUnit) = iUnit;
    speedScores.("Pearson correlation")(iUnit) = r;
    speedScores.("Anatomical Location")(iUnit) = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation;
    speedScores.("Anatomical Abbreviation")(iUnit) = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    speedScores.Mouse(iUnit) = string(mouseLabel{1});

end

% Save speed and spike data structures for future use
saveObservedPath = saveDataDir + "\" + mouseLabel + "_observed_speed_score_data";
save(saveObservedPath, "speedScores", '-v7.3')

disp("Completed PART TWO. Successfully saved speed score data structure.")

%% PART THREE: Plot speed-run plots

disp("Starting PART THREE. Plotting speed-run plots.")

deciSpeed = abs(deciVelocity);

% Define speed bins to compute quartiles
speedBinStart = 0; % cm/s
speedBinWidth = 3; % cm/s
speedBinStep = 1; % cm/s
speedBinEnd = ceil(max(wheelSpeed)); % cm/s
start = speedBinStart:speedBinStep:(speedBinEnd - speedBinWidth);
bins = [start; start+speedBinWidth]';
binMidpoints = (bins(:,1) + bins(:,2))./2;

% Plot running-spiking relationship
for iUnit = 1:nUnits
    disp("Processing unit #" + iUnit + "/" + nUnits)

    smoothedSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).continuousFiringRate;
    deciSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).decimatedFiringRate;

    % Compute quartiles from whole dataset
    quantiles = zeros(3,length(bins));
    for iBin = 1:length(bins)
        idx = (wheelSpeed >= bins(iBin,1)) & (wheelSpeed < bins(iBin,2));
        quantiles(:,iBin) = quantile(smoothedSpikeRate(idx), [0.25 0.5 0.75])';
    end
        
    % Get odor tuning status for this neuron
    odorTuningIdx = strcmp(significantResults.Mouse,mouseLabel) & significantResults.("Unit #")==iUnit;
    if any(odorTuningIdx)
        isOdorTuned = "yes";
    else
        isOdorTuned = "no";
    end

    r = speedScores.("Pearson correlation")(iUnit);
    % Plotting: Recapitulate Figure 1 from paper
    fig = figure('Visible','off');
    sgtitle({mouseLabel + " Unit #" + iUnit; smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation; "r = " + r + " | Is odor tuned? " + isOdorTuned})
    % Plot time series
    subplot(4,5,1:3)
    plot(deciVelocity)
    ylabel('velocity (cm/s)')
    subplot(4,5,6:8)
    plot(deciSpeed)
    ylabel('speed (cm/s)')
    subplot(4,5,11:13)
    plot(deciSpikeRate,'m')
    ylabel('firing rate (Hz)')
    subplot(4,5,16:18)
    plot(zscore(deciSpeed))
    hold on
    plot(zscore(deciSpikeRate),'m')
    xlabel('time')
    ylabel('z score')
    % Plot correlation
    subplot(4,5,[4:5 9:10 14:15 19:20])
    [N, xedges, yedges] = histcounts2(deciSpeed,deciSpikeRate');
    P = N / sum(N(:));
    imagesc(xedges,yedges,log(P'+1e-6));
    axis xy;
    cb = colorbar;
    cb.Label.String = '$\log_{10}$(Joint Probability)';
    cb.Label.Interpreter = 'latex';
    
    % % Select subset of data to plot
    % fractionToSelect = 0.05;
    % idx = randperm(totalSamplePoints,floor(totalSamplePoints*fractionToSelect));
    % subsampledSmoothedSpikeRate = smoothedSpikeRate(idx);
    % subsampledWheelVelocity = wheelVelocity(idx);
    % subsampledWheelSpeed = wheelSpeed(idx);
    % scatter(subsampledWheelSpeed',subsampledSmoothedSpikeRate,'filled','MarkerFaceAlpha',0.05)
    hold on
    % Plot quartile lines
    plot(binMidpoints',quantiles(1,:),'k','LineWidth',2)
    plot(binMidpoints',quantiles(2,:),'k--','LineWidth',2)
    plot(binMidpoints',quantiles(3,:),'k','LineWidth',2)
    %legend(["sampled data points","Q1","Q2","Q3"],'Location','northwest')
    legend(["Q1","Q2","Q3"],'Location','northwest')
    xlabel('speed (cm/s)')
    ylabel('Firing rate (Hz)')
    set(gcf,'Position',[800 750 1500 430])
    
    saveas(gcf, saveFigDir + "\" + mouseLabel + "_running_spiking_relationship_" + num2str(iUnit, "%.3d") + ".png")

end

disp("Completed PART THREE. Successfully saved speed-run plots.")

%% PART FOUR: Generate null distribution
% Can use decimated versions of each signal for this calculation.

disp("Starting PART FOUR. Generating null distribution.")

% This variable should be loaded from one of the input .mat files, but
% apparently it was not saved therein. So I am manually specifying the
% value that was used. 
decimateFactor = 10;

% Plot autocorrelation of speed to determine appropriate minimum time lag
% for shuffling
maxLagSec = 90; % seconds
maxLagSamplePoints = maxLagSec*sampFreq; % sample points
wheelSpeedCentered = wheelSpeed - mean(wheelSpeed);
[xc, lags] = xcorr(wheelSpeedCentered,maxLagSamplePoints,'coeff');
timeLags = lags/sampFreq; % seconds
figure('Visible','off');
plot(timeLags, xc, 'LineWidth', 1.5);
hold on;
% Zero-lag reference line
xline(0, '--k');
xlabel('Lag (s)');
ylabel('Autocorrelation');
title('Autocorrelation');
grid on;
% Limit x-axis to symmetric window
xlim([min(timeLags), max(timeLags)]);
title({"Autocorrelation of speed", mouseLabel{1}})
% NOTE: Based on this result for AK012, choose 20+ seconds as the minimum time lag.
saveas(gcf, saveFigDir + "\" + mouseLabel + "_speed_autocorrelation" + ".png")


% Define shuffling approach
nShuffles = 1000;
minimumShiftSec = 30; % Seconds
deciSampFreq = sampFreq/decimateFactor; % Hz
minimumShiftSamplePoints = minimumShiftSec*deciSampFreq; % sample points
maximumShiftSamplePoints = length(wheelSpeed) - minimumShiftSamplePoints; % sample points

% Define speed vector shuffling indices
shift = randi([minimumShiftSamplePoints,maximumShiftSamplePoints],nShuffles,1);
% Get matrix of decimated neural firing rates
nSamplePoints = length(deciSpeed);
decimatedSpikeRates = nan(nSamplePoints,nUnits);
for iUnit = 1:nUnits
    decimatedSpikeRates(:,iUnit) = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).decimatedFiringRate';
end

% % NOTE: This version works, but it is slower.
% % Get shuffled r values
% tic
% nullSpeedScores = nan(nUnits,nShuffles);
% for iShift = 1:nShuffles
%     disp("Shuffle #" + iShift + "/" + nShuffles)
% 
%     % Circularly shift the speed vector
%     speedShifted = circshift(deciSpeed, shift(iShift))';
% 
%     % Correlate with all units at once
%     R = corr([speedShifted,decimatedSpikeRates]);
%     nullSpeedScores(:,iShift) = R(2:end,1);
% end
% toc

% Pre-compute z-scored firing rates (do once)
deciSpikeRatesZScored = (decimatedSpikeRates - mean(decimatedSpikeRates,1)) ./ std(decimatedSpikeRates,1);

% Get shuffled r values
tic
nullSpeedScores = nan(nUnits,nShuffles);
for iShift = 1:nShuffles
    disp("Shuffle #" + iShift + "/" + nShuffles)

    % Circularly shift the speed vector
    speedShifted = circshift(deciSpeed, shift(iShift))';

    % Z-score the shifted speed
    speedShiftedZScored = (speedShifted - mean(speedShifted))./std(speedShifted);

    % Correlate with all units at once
    % Dot product gives the correlation, then normalize
    nullSpeedScores(:,iShift) = ((speedShiftedZScored' * deciSpikeRatesZScored) / (nSamplePoints - 1))';
end
toc

% Save null data
disp("Saving null speed score matrices...")
saveNullPath = saveDataDir + "\" + mouseLabel + "_null_speed_score_data";
save(saveNullPath, "nullSpeedScores","nShuffles","minimumShiftSec", '-v7.3');

disp("Completed PART FOUR. Successfully saved null distribution.")

%% PART FIVE: Plot the null and true distributions for this animal

disp("Starting PART FIVE. Generating null vs. observed speed score histograms.")

speedScoresAll = speedScores.("Pearson correlation");

upperThreshold = prctile(nullSpeedScores(:),97.5);
lowerThreshold = prctile(nullSpeedScores(:),2.5);

[nullCounts, edges] = histcounts(nullSpeedScores,'BinMethod','auto');

% NOTE: This figure as written may cut off any edge observed units (since
% the bounds of the x-axis are set based on the null histogram edges, which
% does not take into account the observed data range).
figure('Visible','off');
histogram(nullSpeedScores,edges,'Normalization','probability')
hold on
histogram(speedScoresAll,edges,'Normalization','probability')
xline(upperThreshold,'r','LineWidth',2)
xline(lowerThreshold,'r','LineWidth',2)
xlabel("speed scores (r)")
xlim([-max(abs(edges)) max(abs(edges))])
title({"Histogram of null versus observed speed scores", mouseLabel{1}})
% Save histogram
saveas(gcf, saveFigDir + "\" + mouseLabel + "_speed_score_histogram" + ".png")


disp("Completed PART FIVE. Successfully saved null vs. observed histogram for this animal.")

disp("End of script.")