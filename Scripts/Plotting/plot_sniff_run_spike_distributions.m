% PLOT_SNIFF_RUN_SPIKE_DISTRIBUTIONS.m - This script saves 
% N png 
% figures, where N is the number of units recorded for a given mouse. Each 
% figure features subplots showing the running speed across the experiment, 
% the spike rate across the experiment, the two z-scored and overlaid, and 
% also a plot of the run velocity vs. spike rate and statistical measures 
% of correlation.  
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
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: May 19, 2026 (by Anna C. Kolstad)
% Script last updated: May 19, 2026 (by Anna C. Kolstad)
% Version 1.0.

%% PART ONE: Load data and get parameters
clear vars
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% select smoothed_sniff_rate.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_sniff_rate.mat file from sniff_run_spike for " + mouseLabel + ".",baseDir);
disp("Loading sniff rate data structure...")
load(fullfile(path,file));

% select smoothed_run_speed.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_run_speed.mat file from sniff_run_spike for " + mouseLabel + ".",baseDir);
disp("Loading running velocity data structure...")
load(fullfile(path,file));

% select significantResultsAllMice.mat variable file
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file for " + mouseLabel + ".",baseDir);
disp("Loading significant results data structure...")
load(fullfile(path,file));

% select smoothed_spike_rate_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_smoothed_spike_rate.mat file for " + mouseLabel + ".",baseDir);

% select path for output data structures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs (choose directory named sniff_run_spike).");
saveDataDir = baseOutputPath + "\" + "distributions";
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

% Load smoothed_spike_rates.mat variable file
disp("Loading smoothed spike rate data structure...")
tic
load(fullfile(path,file));
toc

disp("Completed PART ONE. Successfully loaded data.")

%% PART TWO: Plot overall histograms of behavioral variables across the entire recording

binEdgesSniff = [1:0.1:7];
binEdgesVelocity = [-10:0.3:27];
binEdgesSpeed = [0:0.3:27];

% Figure 1
figure()
% Sniffing
subplot(3,1,1)
histogram(smoothSniffRate,binEdgesSniff,'Normalization','probability')
%histogram(smoothSniffRate,'BinMethod','fd','Normalization','probability')
xlabel("sniffing rate (Hz)")
ylabel("probability")

% Running Velocity
subplot(3,1,2)
histogram(deciVelocity,binEdgesVelocity,'Normalization','probability')
xlabel("running velocity (cm/s)")
ylabel("probability")


% Running Speed
subplot(3,1,3)
histogram(deciSpeed,binEdgesSpeed,'Normalization','probability')
xlabel("running speed (cm/s)")
ylabel("probability")

%% PART THREE: Plot overall histograms of behavioral variables across the entire recording
% with velocity in a log scale

% Figure 1
figure()
sgtitle("Probability on log scale")
% Sniffing
subplot(3,1,1)
histogram(smoothSniffRate,binEdgesSniff,'Normalization','probability')
set(gca,'YScale','log')
xlabel("sniffing rate (Hz)")
ylabel("probability")

% Running Velocity
subplot(3,1,2)
histogram(deciVelocity,binEdgesVelocity,'Normalization','probability')
set(gca,'YScale','log')
xlabel("running velocity (cm/s)")
ylabel("probability")

% Running Speed
subplot(3,1,3)
histogram(deciSpeed,binEdgesSpeed,'Normalization','probability')
set(gca,'YScale','log')
xlabel("running speed (cm/s)")
ylabel("probability")


%% PART THREE: Plot overall histograms of behavioral variables during running vs. stationary epochs

runningFraction = mean(decimatedFinalEpochLabels);
stationaryFraction = 1-runningFraction;
% Figure 1
figure()
sgtitle("Running: " + round(runningFraction*100) + "%; Stationary: " + round(stationaryFraction*100) + "%")
% Sniffing
subplot(3,1,1)
histogram(smoothSniffRate(decimatedFinalEpochLabels==0),binEdgesSniff,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(smoothSniffRate(decimatedFinalEpochLabels==1),binEdgesSniff,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
xlabel("sniffing rate (Hz)")
ylabel("probability")
legend(["stationary" "running"])

% Running Velocity
subplot(3,1,2)
histogram(deciVelocity(decimatedFinalEpochLabels==0),binEdgesVelocity,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(deciVelocity(decimatedFinalEpochLabels==1),binEdgesVelocity,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
xlabel("running velocity (cm/s)")
ylabel("probability")
legend(["stationary" "running"])

% Running Speed
subplot(3,1,3)
histogram(deciSpeed(decimatedFinalEpochLabels==0),binEdgesSpeed,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(deciSpeed(decimatedFinalEpochLabels==1),binEdgesSpeed,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
xlabel("running speed (cm/s)")
ylabel("probability")
legend(["stationary" "running"])

%% PART FOUR: Plot overall histograms of behavioral variables during running vs. stationary epochs
% using log scale on y axis

runningFraction = mean(decimatedFinalEpochLabels);
stationaryFraction = 1-runningFraction;
% Figure 1
figure()
sgtitle("Running: " + round(runningFraction*100) + "%; Stationary: " + round(stationaryFraction*100) + "%")
% Sniffing
subplot(3,1,1)
histogram(smoothSniffRate(decimatedFinalEpochLabels==0),binEdgesSniff,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(smoothSniffRate(decimatedFinalEpochLabels==1),binEdgesSniff,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
set(gca,'YScale','log')
xlabel("sniffing rate (Hz)")
ylabel("probability")
legend(["stationary" "running"])

% Running Velocity
subplot(3,1,2)
histogram(deciVelocity(decimatedFinalEpochLabels==0),binEdgesVelocity,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(deciVelocity(decimatedFinalEpochLabels==1),binEdgesVelocity,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
set(gca,'YScale','log')
xlabel("running velocity (cm/s)")
ylabel("probability")
legend(["stationary" "running"])

% Running Speed
subplot(3,1,3)
histogram(deciSpeed(decimatedFinalEpochLabels==0),binEdgesSpeed,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
hold on
histogram(deciSpeed(decimatedFinalEpochLabels==1),binEdgesSpeed,'Normalization','probability','DisplayStyle','stairs','LineWidth',2)
set(gca,'YScale','log')
xlabel("running speed (cm/s)")
ylabel("probability")
legend(["stationary" "running"])

%% PART FIVE: Plot marginal distributions of sniffing and running

