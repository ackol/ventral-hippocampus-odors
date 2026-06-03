% COMPUTE_PARTIAL_CORRELATIONS_SNIFF_RUN_SPIKE.m - This script saves ...
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
% Script first created: April 2, 2026 (by Anna C. Kolstad)
% Script last updated: April 13, 2026 (by Anna C. Kolstad)
% Note: Versions 1-2 of this script were titled
% "plot_spike_run_correlation.m"
% Version 3.0.

%% NEED TO AMMEND THE ABOVE COMMENTS AND FILL IN THE CODE THAT GOT DELETED

%% PART ELEVEN: Calculate correlation between Stationary speed and sniff rate ONLY IN STATIONARY EPOCHS

% Compute Pearson's correlation
[rPearsonRS_EpochS, ~] = corr(sniffingStationary',speedStationary','Type','Pearson');

% Compute Spearman's correlation
[rhoSpearmanRS_EpochS, ~] = corr(sniffingStationary',speedStationary','Type','Spearman');

% Compute Kendall's tau
tic
[tauKendallRS_EpochS, ~] = corr(sniffingStationary',speedStationary','Type','Kendall');
toc

%% PART TWELVE: Calculate correlation between spike rate and sniff rate ONLY IN STATIONARY EPOCHS

% Compute Pearson's correlation
[rPearsonFS_EpochS, ~] = corr(firingStationary,sniffingStationary','Type','Pearson');

% Compute Spearman's correlation
[rhoSpearmanFS_EpochS, ~] = corr(firingStationary,sniffingStationary','Type','Spearman');

% Compute Kendall's tau
tic
[tauKendallFS_EpochS, ~] = corr(firingStationary,sniffingStationary','Type','Kendall');
toc


%% PART THIRTEEN: Calculate correlation between spike rate and Stationary speed ONLY IN STATIONARY EPOCHS

% Compute Pearson's correlation
[rPearsonFR_EpochS, ~] = corr(firingStationary,speedStationary','Type','Pearson');

% Compute Spearman's correlation
[rhoSpearmanFR_EpochS, ~] = corr(firingStationary,speedStationary','Type','Spearman');

% Compute Kendall's tau
tic
[tauKendallFR_EpochS, ~] = corr(firingStationary,speedStationary','Type','Kendall');
toc


%% PART FOURTEEN: Calculate partial correlations ONLY IN STATIONARY EPOCHS

% Use Pearson's partial correlations (note: not appropriate for our data
% since Stationary speed is highly skewed and bounded at zero)
% Use rank-based partial correlations

% look at the effect of Stationary on neural firing, controlling for sniffing
rhoPearsonFR_S_EpochS = partialcorr(firingStationary,speedStationary',sniffingStationary','Type','Pearson');
rhoPearsonFS_R_EpochS = partialcorr(firingStationary,sniffingStationary',speedStationary','Type','Pearson');
rhoSpearmanFR_S_EpochS = partialcorr(firingStationary,speedStationary',sniffingStationary','Type','Spearman');
rhoSpearmanFS_R_EpochS = partialcorr(firingStationary,sniffingStationary',speedStationary','Type','Spearman');