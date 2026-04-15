% plot_velocity_heatmap_across_all_animals.m - align the velocity data for
% each mouse to the corresponding rows in the unit-odor heatmap matrix, and
% plot to visually assess for any correlations
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) unitLocationsAllMice.mat
%       (2) allVelocityTestResults.mat
%   Outputs:
%       (1) two figures
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 14, 2026
% Script last updated: April 14, 2026
% Version 1.0.

%% PART 1: Load data

clear all
clc

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for all animals.");

% Load in unit location info for all mice
[file, pathMice] = uigetfile('*.mat','Select unitLocationsAllMice.mat file',baseDir);
load(fullfile(pathMice,file));

% Load in velocity info for all mice
[file, pathMice] = uigetfile('*.mat','Select allVelocityTestResults.mat file',baseDir);
load(fullfile(pathMice,file));

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
saveFigDir = baseOutputPath;
% make new folder if it does not already exist
if ~exist(saveFigDir,'dir')
    mkdir(saveFigDir);
end


%% PART 2: Organize into heatmap structure

%% Sort responses by anatomical location and chemical functional group

% create custum anatomical ordering
[found, idx] = ismember(unitLocationsAllMice.("anatomical location"), ...
    ["DG","iCA3","vCA3","iCA1","vCA1","CA2","dCA1","dCA3","SUB",...
    "BLAp","EPv", "TR","V1"]);
[~, sortorder] = sort(idx);
unitLocationsAllMiceSorted = unitLocationsAllMice(sortorder,:); 
%%
alpha = 0.05;
% create new version that has units sorted by anatomical location
medianChangeInVelocityConcatAnatomicalSort = [];
meanChangeInVelocityConcatAnatomicalSort = [];
meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly = [];
for iRow = 1:height(unitLocationsAllMiceSorted)
    thisMouse = unitLocationsAllMiceSorted.('mouse')(iRow);
    
    thisVelocityResponseMedian = allVelocityTestResultsTable.("median change in velocity")(strcmp(allVelocityTestResultsTable.Mouse,thisMouse));
    thisVelocityResponseMean = allVelocityTestResultsTable.("mean change in velocity")(strcmp(allVelocityTestResultsTable.Mouse,thisMouse));
    
    medianChangeInVelocityConcatAnatomicalSort = [medianChangeInVelocityConcatAnatomicalSort ; thisVelocityResponseMedian'];
    meanChangeInVelocityConcatAnatomicalSort = [meanChangeInVelocityConcatAnatomicalSort ; thisVelocityResponseMean'];

    significantResponses = (allVelocityTestResultsTable.("WSR p-value")(strcmp(allVelocityTestResultsTable.Mouse,thisMouse)) < alpha);
    thisVelocityResponseMeanSigOnly = thisVelocityResponseMean .* significantResponses;
    meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly = [meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly ; thisVelocityResponseMeanSigOnly'];
end

%%

odorantsOrderedPanelCFcnGrpSort = ["limonene", "cumene", "1-octanol", "eugenol", "hexanal", "valeraldehyde", "amyl acetate", "isoamyl acetate", "acetophenone", "valeric acid","mineral oil", "air"];
includeAir = true;
if includeAir == true
    finalIdx = 12;
else
    finalIdx = 11;
end

if includeAir
    % sort odorants by chemical functional group
    medianChangeInVelocityConcatAnatomicalSortOdorSort = [
        medianChangeInVelocityConcatAnatomicalSort(:,1:6) ...
        medianChangeInVelocityConcatAnatomicalSort(:,8) ...
        medianChangeInVelocityConcatAnatomicalSort(:,10) ...
        medianChangeInVelocityConcatAnatomicalSort(:,7) ...
        medianChangeInVelocityConcatAnatomicalSort(:,9) ...
        medianChangeInVelocityConcatAnatomicalSort(:,11:12)]; 
    % sort odorants by chemical functional group
    meanChangeInVelocityConcatAnatomicalSortOdorSort = [
        meanChangeInVelocityConcatAnatomicalSort(:,1:6) ...
        meanChangeInVelocityConcatAnatomicalSort(:,8) ...
        meanChangeInVelocityConcatAnatomicalSort(:,10) ...
        meanChangeInVelocityConcatAnatomicalSort(:,7) ...
        meanChangeInVelocityConcatAnatomicalSort(:,9) ...
        meanChangeInVelocityConcatAnatomicalSort(:,11:12)]; 
   % sort odorants by chemical functional group
    meanChangeVelocityHeatmapSignificantOnlyOdorSort = [
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,1:6) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,8) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,10) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,7) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,9) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,11:12)]; 
else
    % sort odorants by chemical functional group
    medianChangeInVelocityConcatAnatomicalSortOdorSort = [
        medianChangeInVelocityConcatAnatomicalSort(:,1:6) ...
        medianChangeInVelocityConcatAnatomicalSort(:,8) ...
        medianChangeInVelocityConcatAnatomicalSort(:,10) ...
        medianChangeInVelocityConcatAnatomicalSort(:,7) ...
        medianChangeInVelocityConcatAnatomicalSort(:,9) ...
        medianChangeInVelocityConcatAnatomicalSort(:,11)]; 
    % sort odorants by chemical functional group
    meanChangeInVelocityConcatAnatomicalSortOdorSort = [
        meanChangeInVelocityConcatAnatomicalSort(:,1:6) ...
        meanChangeInVelocityConcatAnatomicalSort(:,8) ...
        meanChangeInVelocityConcatAnatomicalSort(:,10) ...
        meanChangeInVelocityConcatAnatomicalSort(:,7) ...
        meanChangeInVelocityConcatAnatomicalSort(:,9) ...
        meanChangeInVelocityConcatAnatomicalSort(:,11)]; 
    % sort odorants by chemical functional group
    meanChangeVelocityHeatmapSignificantOnlyOdorSort  = [
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,1:6) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,8) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,10) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,7) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,9) ...
        meanChangeInVelocityConcatAnatomicalSortWSRSignificantOnly(:,11)]; 
end

%% Plot heatmap of all modulations (significant and not significant), grouped by anatomical location


figure()
ax1 = subplot(1,2,1);
imagesc(medianChangeInVelocityConcatAnatomicalSortOdorSort)
title('median change in velocity')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax1, bluewhitered);
cb = colorbar;
cb.Label.String = "median change in velocity (cm/sec)";
set(gca,'fontsize', 18)
% from ChatGPT -- start--: 
hold on;
% Specify the fixed y-values (row indices) for the horizontal lines
% Find where the 'anatomical location' column changes
regionChanges = [true; ~strcmp(unitLocationsAllMiceSorted.("anatomical location")(2:end),...
    unitLocationsAllMiceSorted.("anatomical location")(1:end-1))];  % First element is true because we start at the first row
% Get the indices where the region change
newRegionIndices = find(regionChanges);
regionLabels = unitLocationsAllMiceSorted.("anatomical location")(newRegionIndices);
yLinePositions = newRegionIndices(2:end)-1;
% Overlay horizontal lines at the specified y-values
for i = 1:length(yLinePositions)
    line([0.5 size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
% Hold off to stop overlaying
hold off;
% from ChatGPT -- end --.

ax2 = subplot(1,2,2);
imagesc(meanChangeInVelocityConcatAnatomicalSortOdorSort)
title('mean change in velocity')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax2, bluewhitered);
cb = colorbar;
cb.Label.String = "mean change in velocity (cm/sec)";
set(gca,'fontsize', 18)
% from ChatGPT -- start--: 
hold on;
% Specify the fixed y-values (row indices) for the horizontal lines
% Find where the 'anatomical location' column changes
regionChanges = [true; ~strcmp(unitLocationsAllMiceSorted.("anatomical location")(2:end),...
    unitLocationsAllMiceSorted.("anatomical location")(1:end-1))];  % First element is true because we start at the first row
% Get the indices where the region change
newRegionIndices = find(regionChanges);
regionLabels = unitLocationsAllMiceSorted.("anatomical location")(newRegionIndices);
yLinePositions = newRegionIndices(2:end)-1;
% Overlay horizontal lines at the specified y-values
for i = 1:length(yLinePositions)
    line([0.5 size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
% Hold off to stop overlaying
hold off;
% from ChatGPT -- end --.

saveas(gcf, saveFigDir + "\" + "velocity_heatmap_aligned_mean_vs_median" + ".png")
saveas(gcf, saveFigDir + "\" + "velocity_heatmap_aligned_mean_vs_median" + ".fig")

%% Plot mean heatmap and mean significant only heatmap

figure()
ax1 = subplot(1,2,1);
imagesc(meanChangeInVelocityConcatAnatomicalSortOdorSort)
title('mean change in velocity')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax1, bluewhitered);
cb = colorbar;
cb.Label.String = "mean change in velocity (cm/sec)";
set(gca,'fontsize', 18)
% from ChatGPT -- start--: 
hold on;
% Specify the fixed y-values (row indices) for the horizontal lines
% Find where the 'anatomical location' column changes
regionChanges = [true; ~strcmp(unitLocationsAllMiceSorted.("anatomical location")(2:end),...
    unitLocationsAllMiceSorted.("anatomical location")(1:end-1))];  % First element is true because we start at the first row
% Get the indices where the region change
newRegionIndices = find(regionChanges);
regionLabels = unitLocationsAllMiceSorted.("anatomical location")(newRegionIndices);
yLinePositions = newRegionIndices(2:end)-1;
% Overlay horizontal lines at the specified y-values
for i = 1:length(yLinePositions)
    line([0.5 size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
% Hold off to stop overlaying
hold off;
% from ChatGPT -- end --.

ax2 = subplot(1,2,2);
imagesc(meanChangeVelocityHeatmapSignificantOnlyOdorSort)
title({"mean change in velocity", "(significant only, no FWE correction)"})
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax2, bluewhitered);
cb = colorbar;
cb.Label.String = "mean change in velocity (cm/sec)";
set(gca,'fontsize', 18)
% from ChatGPT -- start--: 
hold on;
% Specify the fixed y-values (row indices) for the horizontal lines
% Find where the 'anatomical location' column changes
regionChanges = [true; ~strcmp(unitLocationsAllMiceSorted.("anatomical location")(2:end),...
    unitLocationsAllMiceSorted.("anatomical location")(1:end-1))];  % First element is true because we start at the first row
% Get the indices where the region change
newRegionIndices = find(regionChanges);
regionLabels = unitLocationsAllMiceSorted.("anatomical location")(newRegionIndices);
yLinePositions = newRegionIndices(2:end)-1;
% Overlay horizontal lines at the specified y-values
for i = 1:length(yLinePositions)
    line([0.5 size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInVelocityConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
% Hold off to stop overlaying
hold off;
% from ChatGPT -- end --.

saveas(gcf, saveFigDir + "\" + "velocity_heatmap_aligned_median_vs_significant" + ".png")
saveas(gcf, saveFigDir + "\" + "velocity_heatmap_aligned_median_vs_significant" + ".fig")