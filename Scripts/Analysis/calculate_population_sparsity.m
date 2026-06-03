% calculate_population_sparsity.m - This code is designed to calculate the
% population sparsity for populations of neurons responding to odor stimuli
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: November 11, 2025
% Script last updated: November 11, 2025
% Version 1.0


%% Load data structures

baseDir = uigetdir('',"Select base directory from which to navigate.");

regions = ["vCA1", "CA3", "DG"];
nRegions = length(regions);

% load odor tuning curves for all neurons in each region
for i = 1:nRegions
    region = regions(i);
    [file, path] = uigetfile(".mat","Select .mat file containing tuning curves of neurons in " + region + ".",baseDir);
    tic
    disp("Loading odor tuning curves...")
    if region == "vCA1"
        load(fullfile(path,file),"vCA1tuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","vCA1OdorTunedUnits","vCA1significantResults"); 
    elseif region == "CA3"
        load(fullfile(path,file),"CA3tuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","CA3OdorTunedUnits","CA3significantResults");
    elseif region == "DG"
        load(fullfile(path,file),"DGtuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","DGOdorTunedUnits","DGsignificantResults"); 
    end
end

%% Calculate population sparsity for each stimulus

tuningCurves = {vCA1tuningMatrix, CA3tuningMatrix, DGtuningMatrix};

Psparsity = cell(1,3);
PsparsityMedian = nan(1,3);
PsparsityQ1 = nan(1,3);
PsparsityQ3 = nan(1,3);
for iRegion = 1:nRegions
    tuningCurvesThisRegion = tuningCurves{iRegion};

    nStimuli = size(tuningCurvesThisRegion,1);

    % Calculate population sparsity for each stimulus
    PS = nan(nUnits,1);
    for iStimulus = 1:nStimuli
        PS(iStimulus) = populationSparsity(tuningCurvesThisRegion(iStimulus,:));
    end

    Psparsity(iRegion) = {PS};

    quartiles = prctile(PS, [25 50 75]);
    PsparsityMedian(iRegion) = quartiles(2);
    PsparsityQ1(iRegion) = quartiles(1);
    PsparsityQ3(iRegion) = quartiles(3);

end

clear PS

% Look at this paper!! 10.1002/hipo.23651
% and this one: 10.1152/jn.00594.2010
% and this third one: 1. Quian Quiroga, R. & Kreiman, G. Measuring sparseness in the brain: Comment on Bowers (2009). Psychological Review 117, 291–297 (2010).
% and this: https://pubmed.ncbi.nlm.nih.gov/11563529/

%% Plot histogram of population sparsity across regions

figure()
nBins = 5;
minX = 0.6;
bins = [minX:(1-minX)/nBins:1];
% probability
for iRegion = 1:nRegions
    subplot(3,1,iRegion)
    histogram(Psparsity{iRegion},'BinEdges',bins,'Normalization','probability')
    xlim([minX 1])
    ylim([0 0.6])
    title({regions(iRegion), "Median = " + PsparsityMedian(iRegion) + " (IQR = " + PsparsityQ1(iRegion) + "-" + PsparsityQ3(iRegion) + ")"})
    ylabel("probability")
end

figure()
% count
for iRegion = 1:nRegions
    subplot(3,1,iRegion)
    histogram(Psparsity{iRegion},'BinEdges',bins,'Normalization','count')
    xlim([minX 1])
    title(regions(iRegion))
    ylabel("count")
end


%% Create combined vector for boxplots and statistical tests

combinedPS = [Psparsity{1}; Psparsity{2}; Psparsity{3}];
groupPS = [ones(length(Psparsity{1}),1); 2*ones(length(Psparsity{2}),1); 3*ones(length(Psparsity{3}),1)];

%% Plot boxplots to compare population sparsity across regions

figure()
boxplot(combinedPS,groupPS,"Labels",regions)
ylabel("Population sparsity")

%% Compare population sparsity across regions

[p, tbl, stats] = kruskalwallis(combinedPS,groupPS);


%% Local functions

% Calculates population sparsity, which characterizes how distributed the
% response to a given stimulus is across a population of neurons
% Follows the modified Treves-Rolls metric used in this paper: 
%   Willmore, B. & Tolhurst, D. J. Characterizing the sparseness of neural 
%   codes. Network: Computation in Neural Systems 12, 255–270 (2001).

function S = populationSparsity(responseVector)
    % tuningCurve is a 1 x M vector, where M is the total number of neurons.
    % The values in the vector are the the median response (change
    % in firing rate) of each neuron to the stimulus.
    
    nNeurons = size(responseVector,2);
    responseVector = abs(responseVector);
    
    numerator = (1/nNeurons * sum(responseVector))^2;
    denominator = 1/nNeurons * sum(responseVector.^2);
    
    S = 1 - (numerator/denominator);

end