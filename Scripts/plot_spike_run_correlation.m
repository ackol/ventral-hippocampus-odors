% plot_spike_run_correlation.m - This script saves N png 
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
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_aligned_phy_unit_data.mat
%       (4) [AK0xx]_full_session_inst_velocity.mat
%       (5) significantResultsAllMice.mat
%       (6) directory in which to save outputs
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
% Script first created: April 2, 2026
% Script last updated: April 2, 2026
% Version 1.0.


%% PART ONE: Load data and get parameters

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% select aligned_phy_unit_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_aligned_phy_unit_data.mat file for " + mouseLabel + ".",baseDir);
disp("Loading aligned phy unit data structure...")
load(fullfile(path,file));

% select full_session_inst_velocity.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_full_session_inst_velocity.mat file for " + mouseLabel + ".",baseDir);
disp("Loading running velocity data structure...")
load(fullfile(path,file));

% select significantResultsAllMice.mat variable file
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file for " + mouseLabel + ".",baseDir);
disp("Loading significant results data structure...")
load(fullfile(path,file));

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
saveDir = baseOutputPath + "\" + "speed_coding";
% make new folders if they do not already exist
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

disp("Completed PART ONE. Successfully loaded data.")

%% PART TWO: Process data and produce plots

nUnits = numel(fieldnames(alignedUnitDataStruct)) - 1;

for iUnit = 1:nUnits
    disp("Processing unit #" + iUnit + "/" + nUnits)

    desiredUnit = iUnit; 

    odorTuningIdx = strcmp(significantResults.Mouse,mouseLabel) & significantResults.("Unit #")==iUnit;
    if any(odorTuningIdx)
        isOdorTuned = "yes";
    else
        isOdorTuned = "no";
    end

    desiredSpikeIndices = alignedUnitDataStruct.("UNIT" + num2str(desiredUnit, "%.3d")).eventData.spikeIndices;
    totalSamplePoints = alignedUnitDataStruct.("UNIT" + num2str(desiredUnit, "%.3d")).info.nSamples;
    timeSeries = zeros(totalSamplePoints,1);
    timeSeries(desiredSpikeIndices) = 1;
    
    % Define smoothing kernel -- based on what was in
    % computewheelvelocityconvolution
    % Compute the instantaneous spike rate with a moving window (1 second wide)
    convolveLength = .5*sampFreq; 
    convolveType = "square";
    xVector = linspace(-1,1,convolveLength);
    convolveSignal = ones(1,length(xVector));        
    % Compute the spike rate using the convolution operator
    smoothedSpikeRate = conv(timeSeries, (convolveSignal))./(length(convolveSignal)/sampFreq); % in Hz
    % Adjust the size of the spike rate matrix to account for the convolution bounds
    startIdx = (length(convolveSignal)/2)-1; %<-- code in the computewheelvelocityconvolution seem strange? 
    endIdx = startIdx + length(timeSeries) - 1; %length(timeSeries)-length(convolveSignal)/2;
    smoothedSpikeRate = smoothedSpikeRate(startIdx:endIdx);
    
    [r, p] = corr(smoothedSpikeRate,wheelVelocity');
    
    fractionToSelect = 0.05;
    idx = randperm(totalSamplePoints,floor(totalSamplePoints*fractionToSelect));
    subsampledSmoothedSpikeRate = smoothedSpikeRate(idx);
    subsampledWheelVelocity = wheelVelocity(idx);
    
    % look at speed from 0 to 16 cm/s
    speedBinWidth = 6; % cm/s
    speedBinStep = 2; % cm/s
    speedBinStart = 0; % cm/s
    speedBinEnd = 16; % cm/s
    
    start = speedBinStart:speedBinStep:(speedBinEnd - speedBinWidth);
    bins = [start; start+speedBinWidth]';
    binMidpoints = (bins(:,1) + bins(:,2))./2;
    
    quantiles = zeros(3,length(bins));
    for iBin = 1:length(bins)
        idx = (wheelVelocity >= bins(iBin,1)) & (wheelVelocity < bins(iBin,2));
        quantiles(:,iBin) = quantile(smoothedSpikeRate(idx), [0.25 0.5 0.75])';
    end
    
    deciSpikeRate = decimate(smoothedSpikeRate, 10);
    
    % Plotting: Recapitulate Figure 1 from paper
    fig = figure('Visible','off');
    sgtitle({mouseLabel + " Unit #" + desiredUnit; alignedUnitDataStruct.("UNIT" + num2str(desiredUnit, "%.3d")).info.anatomicLocation; "r = " + r + ", p = " + p + " | Is odor tuned? " + isOdorTuned})
    % Plot time series
    subplot(3,5,1:3)
    plot(deciVelocity)
    ylabel('speed (cm/s)')
    subplot(3,5,6:8)
    plot(deciSpikeRate,'m')
    ylabel('firing rate (Hz)')
    subplot(3,5,11:13)
    plot(zscore(deciVelocity))
    hold on
    plot(zscore(deciSpikeRate),'m')
    xlabel('time')
    ylabel('z score')
    % Plot correlation
    subplot(3,5,[4:5 9:10 14:15])
    scatter(subsampledWheelVelocity',subsampledSmoothedSpikeRate,'.c')
    hold on
    plot(binMidpoints',quantiles(1,:),'k','LineWidth',2)
    plot(binMidpoints',quantiles(2,:),'k--','LineWidth',2)
    plot(binMidpoints',quantiles(3,:),'k','LineWidth',2)
    legend(["sampled data points","Q1","Q2","Q3"],'Location','northwest')
    xlabel('speed (cm/s)')
    ylabel('Firing rate (Hz)')
    set(gcf,'Position',[800 750 1500 430])
    
    saveas(gcf, saveDir + "\" + mouseLabel + "_running_spiking_relationship_" + num2str(iUnit, "%.3d") + ".png")

end