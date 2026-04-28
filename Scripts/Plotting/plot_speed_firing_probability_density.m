% plot_speed_firing_probability_density.m - This script 
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
% Note: Adapted from "compute_and_plot_spike_run_correlation.m" Version 3.0
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 17, 2026 (by Anna C. Kolstad)
% Script last updated: April 19, 2026 (by Anna C. Kolstad)
% Version 1.1.

%% PART ONE: Load data and get parameters
clear all
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% Manually specify unit of interest
unitNum = inputdlg('Enter unit ID','User input');
unitNum = unitNum{1};
unitNum = str2double(unitNum);

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% select [AKxxx]_observed_speed_score_data.mat variable file
[file, path] = uigetfile(".mat","Select [AKxxx]_observed_speed_score_data.mat file for " + mouseLabel + ".",baseDir);
disp("Loading speed score data structure...")
load(fullfile(path,file));

% % select [AKxxx]_null_speed_score_data.mat variable file
% [file, path] = uigetfile(".mat","Select [AKxxx]_null_speed_score_data.mat file for " + mouseLabel + ".",baseDir);
% disp("Loading speed score data structure...")
% load(fullfile(path,file));

% select full_session_inst_velocity.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_paired_full_session_inst_velocity.mat file from speed_coding for " + mouseLabel + ".",baseDir);
disp("Loading running velocity data structure...")
load(fullfile(path,file));

% select smoothed_spike_rate_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_spike_rate_data.mat file for " + mouseLabel + ".",baseDir);

% Load smoothed_spike_rate_data.mat variable file
disp("Loading smoothed spike rate data structure...")
tic
load(fullfile(path,file));
toc

disp("Completed PART ONE. Successfully loaded data.")

%% PART 2: Get key info

disp("Starting PART TWO. Get key info.")

deciSpeed = abs(deciVelocity);
wheelSpeed = abs(wheelVelocity);

% Define speed bins to compute quartiles
speedBinStart = 0; % cm/s
speedBinWidth = 3; % cm/s
speedBinStep = 1; % cm/s
speedBinEnd = ceil(max(wheelSpeed)); % cm/s
start = speedBinStart:speedBinStep:(speedBinEnd - speedBinWidth);
bins = [start; start+speedBinWidth]';
binMidpoints = (bins(:,1) + bins(:,2))./2;

% Plot running-spiking relationship
iUnit = unitNum;

smoothedSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).continuousFiringRate;
deciSpikeRate = smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).decimatedFiringRate;

% Compute quartiles from whole dataset
quantiles = zeros(3,length(bins));
for iBin = 1:length(bins)
    idx = (wheelSpeed >= bins(iBin,1)) & (wheelSpeed < bins(iBin,2));
    quantiles(:,iBin) = quantile(smoothedSpikeRate(idx), [0.25 0.5 0.75])';
end
    
r = speedScores.("Pearson correlation")(iUnit);


%% Plotting: Recapitulate Figure 1 from paper

maxSpeed = max(deciVelocity);
maxFR = max(deciSpikeRate);

%xedges = [capLowSpeed:capSpeed/15:capSpeed];
%yedges = [0:capFR/15:capFR];

fullrange = false;

clim1min = min([-22.7928 -21.4088 -15.9481 -23.4759]); % min of logNullJointFixed for AK025 Unit 6
clim1max = max([-0.7208 -1.5322 -1.2401 -1.3004]); % max of logPFixed for AK012 Unit 5 **
%clim2min = min([-2.8728 -5.5620 -2.5820]); % min of PMI for AK026 Unit 27 ** -- log10
clim2min = -18.474; % min of PMI for AK026 Unit 27 ** -- log2
clim2max = 14.596; % max of PMI for AK012 Unit 5 ** -- log2
%clim2max = max([4.3933 1.2497 3.2770]); % max of PMI for AK012 Unit 5 ** -- log10
clim2val = max(abs([clim2min clim2max]));

% % If plotting AK012 Unit #5, use:
if strcmp(string(mouseLabel),"AK012")
    xedges = [0:2.5:35];
    yedges = [0:5:220];
    xlimits = [0 35];
    if fullrange
        ylimits = [0 220];
    else 
        ylimits = [0 90];
    end

% If plotting AK026 Unit #27, use:
elseif strcmp(string(mouseLabel),"AK026")
    xedges = [0:2.5:25];
    yedges = [0:5:220];
    xlimits = [0 25];
    if fullrange
        ylimits = [0 220];
    else
        ylimits = [0 90];
    end

% % % If plotting AK025 Unit #6, use:
elseif strcmp(string(mouseLabel),"AK025")
    xedges = [0:2.5:30];
    yedges = [0:5:220];
    xlimits = [0 30];
    if fullrange
        ylimits = [0 220];
    else
        ylimits = [0 90];
    end
end

% Plot correlation
fig = figure('Visible','on');

ax1 = subplot(5,4,[2:3 6:7]);
[N, xedges, yedges] = histcounts2(deciSpeed,deciSpikeRate',xedges,yedges);
P = N / sum(N(:));
eps = 2e-308;
Pfixed = P;
Pfixed(Pfixed==0) = eps;
logPfixed = log(Pfixed);
meaningfulLogValues = logPfixed(Pfixed>eps);
if isempty(meaningfulLogValues)
else
    minLogP = min(meaningfulLogValues);
    maxLogP = max(meaningfulLogValues);
end
xOuterPoints = [(xedges(1)+xedges(2))/2 (xedges(end)+xedges(end-1))/2];
yOuterPoints = [(yedges(1)+yedges(2))/2 (yedges(end)+yedges(end-1))/2];
imagesc(xOuterPoints,yOuterPoints,log(Pfixed'));
hold on
axis xy;
climits1 = clim;
clim([clim1min clim1max])
colormap(ax1,jet)
% Plot quartile lines
plot(binMidpoints',quantiles(1,:),'k','LineWidth',2)
scatter(binMidpoints',quantiles(2,:),'k','filled','LineWidth',2)
plot(binMidpoints',quantiles(3,:),'k','LineWidth',2)
% Set figure labels
title({mouseLabel + " Unit #" + iUnit; smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation; "r = " + r})
legend(["Q1","Q2","Q3"],'Location','northwest')
xlabel('running speed (cm/s)')
ylabel('unit firing rate (Hz)')
cb = colorbar;
cb.Label.String = '$\log_{10}$(joint probability)';
cb.Label.Interpreter = 'latex';
xlim(xlimits)
ylim(ylimits)

%set(gcf,'Position',[800 750 1500 430])

ax2 = subplot(5,4,[1 5]);
histogram(deciSpikeRate',yedges,'Normalization','probability','EdgeColor','k','LineStyle','none','FaceColor','k','FaceAlpha',1,'Orientation','horizontal');
xlabel("log(probability)")
ylim(ylimits)
set(gca,'XDir','reverse')
set(gca,'XScale','log')

ax3 = subplot(5,4,10:11);
histogram(deciSpeed,xedges,'Normalization','probability','EdgeColor','k','LineStyle','none','FaceColor','k','FaceAlpha',1);
ylabel("log(probability)")
xlim(xlimits)
set(gca,'YDir','reverse')
set(gca,'YScale','log')


ax4 = subplot(5,4,[13:14 17:18]);
[speedCounts, speedEdges] = histcounts(deciSpeed,xedges,'Normalization','probability');
[frCounts, frEdges] = histcounts(deciSpikeRate',yedges,'Normalization','probability');
nullJoint = frCounts' * speedCounts;
nullJointFixed = nullJoint;
nullJointFixed(nullJointFixed==0) = eps;
logNullJointFixed = log(nullJointFixed);
meaningfulLogValues = logNullJointFixed(nullJointFixed>eps);
if isempty(meaningfulLogValues)
else
    minLogNull = min(meaningfulLogValues);
    maxLogNull = max(meaningfulLogValues);
end

imagesc(xOuterPoints,yOuterPoints,log(nullJointFixed))
xlim(xlimits)
ylim(ylimits)
axis xy;
climits2 = clim;
clim([clim1min clim1max])
colormap(ax4,jet)
cb = colorbar;
cb.Label.String = '$\log_{10}$(Joint Probability)';
cb.Label.Interpreter = 'latex';

ax5 = subplot(5,4,[15:16 19:20]);
imagesc(xOuterPoints,yOuterPoints,log2(P'./nullJoint)); 
xlim(xlimits)
ylim(ylimits)
axis xy
climits3 = clim;
clim([-1*clim2val clim2val])
colormap(ax5,bluewhitered); 
cb = colorbar;
cb.Label.String = 'pointwise mutual information';
cb.Label.Interpreter = 'latex';

set(gcf,"Position", 1.0e+03 *[0.9997    0.0857    0.5600    1.0667])

%saveas(gcf, saveFigDir + "\" + mouseLabel + "_running_spiking_relationship_" + num2str(iUnit, "%.3d") + ".png")

disp("Completed PART THREE. Successfully saved speed-run plots.")