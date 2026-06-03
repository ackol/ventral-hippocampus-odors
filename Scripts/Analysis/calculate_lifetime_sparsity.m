% calculate_lifetime_sparsity.m - This code is designed to calculate the
% lifetime sparsity for neurons responding to odor stimuli
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: November 11, 2025
% Script last updated: November 11, 2025
% Version 1.0


%% Calculate the lifetime sparsity of each neuron in each brain region

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

%% Calculate lifetime sparsity for each neuron

tuningCurves = {vCA1tuningMatrix, CA3tuningMatrix, DGtuningMatrix};

Lsparsity = cell(1,3);
LsparsityMedian = nan(1,3);
LsparsityQ1 = nan(1,3);
LsparsityQ3 = nan(1,3);
for iRegion = 1:nRegions
    tuningCurvesThisRegion = tuningCurves{iRegion};

    nUnits = size(tuningCurvesThisRegion,2);

    % Calculate lifetime sparsity for each neuron
    LS = nan(nUnits,1);
    for iUnit = 1:nUnits
        LS(iUnit) = lifetimeSparsity(tuningCurvesThisRegion(:,iUnit));
    end

    Lsparsity(iRegion) = {LS};

    quartiles = prctile(LS, [25 50 75]);
    LsparsityMedian(iRegion) = quartiles(2);
    LsparsityQ1(iRegion) = quartiles(1);
    LsparsityQ3(iRegion) = quartiles(3);

end

clear LS

%% Plot histogram of lifetime sparsity across regions

figure()
nBins = 6;
minX = 0.7;
bins = [minX:(1-minX)/nBins:1];
% probability
for iRegion = 1:nRegions
    subplot(3,1,iRegion)
    histogram(Lsparsity{iRegion},'BinEdges',bins,'Normalization','probability')
    xlim([minX 1])
    ylim([0 0.8])
    title({regions(iRegion), "Median = " + LsparsityMedian(iRegion) + " (IQR = " + LsparsityQ1(iRegion) + "-" + LsparsityQ3(iRegion) + ")"})
    ylabel("probability")
end

figure()
% count
for iRegion = 1:nRegions
    subplot(3,1,iRegion)
    histogram(Lsparsity{iRegion},'BinEdges',bins,'Normalization','count')
    xlim([minX 1])
    title(regions(iRegion))
    ylabel("count")
end

%% Create combined vector for boxplots and statistical tests

combinedLS = [Lsparsity{1}; Lsparsity{2}; Lsparsity{3}];
groupLS = [ones(length(Lsparsity{1}),1); 2*ones(length(Lsparsity{2}),1); 3*ones(length(Lsparsity{3}),1)];

%% Plot boxplots to compare sparsity across regions

figure()
boxplot(combinedLS,groupLS,"Labels",regions)
ylabel("Lifetime sparsity")

%% Compare lifetime sparsity across regions

[p, tbl, stats] = kruskalwallis(combinedLS,groupLS);

%% Local functions

% Calculates lifetime sparsity, which characterizes the selectivity of a
% neuron across stimlui
function S = lifetimeSparsity(tuningCurve)
    % tuningCurve is an N x 1 vector, where N is the total number of stimuli.
    % The values in the vector are the the median response (change
    % in firing rate) of the neuron to each stimulus.
    
    nStimuli = size(tuningCurve,1);
    tuningCurve = abs(tuningCurve);
    
    numerator = (1/nStimuli * sum(tuningCurve))^2;
    denominator = 1/nStimuli * sum(tuningCurve.^2);
    
    S = (1 - (numerator/denominator)) / (1 - 1/nStimuli);

end