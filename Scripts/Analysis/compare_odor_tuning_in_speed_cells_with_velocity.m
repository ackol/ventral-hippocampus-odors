% compare_odor_tuning_in_speed_cells_with_velocity.m
%
%   Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) allSpeedScoreInfo.mat
%       (2) significantResultsAllMice.mat
%       (3) allUnitInfo.mat
%   Outputs:
%       (1) display in the command window the fraction of units that are
%       tuned to both speed and odors
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

%% Load speedTunedUnitsTable

clear all
clc

% Load in speed and odor tuned cells
[file, path] = uigetfile(".mat","Select speedAndOdorTunedCells.mat file for all mice.");
disp("Loading list of speed AND odor tuned cells...")
load(fullfile(path,file)); 

% Load in significantResults for all mice
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file.",path);
disp("Loading significantly odor-tuned neurons...")
load(fullfile(path,file)); 
nTunedOdorUnitPairs = height(significantResults);

% Load in medianDeltaRate for all mice
[file, path] = uigetfile(".mat","Select medianDeltaRateAllMice.mat file.",path);
disp("Loading median change in firing rate for all unit-odor pairs...")
load(fullfile(path,file)); 

% Load in unitLocationsAllMice
[file, path] = uigetfile(".mat","Select unitLocationsAllMice.mat file.",path);
disp("Loading unit information...")
load(fullfile(path,file)); 

% Load in allVelocityTestResults
[file, path] = uigetfile(".mat","Select allVelocityTestResults.mat file.",path);
disp("Loading change in velocity information...")
load(fullfile(path,file)); 

% select path for output figures
baseOutputPath = uigetdir(path,"Select base directory in which to save outputs.");
saveFigDir = baseOutputPath;
% make new folder if it does not already exist
if ~exist(saveFigDir,'dir')
    mkdir(saveFigDir);
end


%% Extract median change in firing rate upon odor presentation for speed-odor cells

unitLocationsAllMice.UniqueID = unitLocationsAllMice.mouse + "-" + unitLocationsAllMice.unit;
significantResults.UniqueID = significantResults.Mouse + "-" + significantResults.("Unit #");

odorantNames = ["limonene", "cumene", "1-octanol", "eugenol", "hexanal", "valeraldehyde", "acetophenone", "amyl acetate", "valeric acid", "isoamyl acetate", "mineral oil", "air"];

nSpeedOdorCells = length(speedAndOdorTunedCells);

meanChangeInVelocityAll = [];
medianChangeInFiringRateAll = [];
medianChangeInFiringRateSignificantOdorsOnly = [];
meanChangeInVelocitySignificantOdorsOnly = [];
for iUnit = 1:nSpeedOdorCells
    thisUnit = speedAndOdorTunedCells(iUnit,1);
    thisMouse = split(thisUnit,"-");
    thisMouse = thisMouse(1);

    % Get the response to all odorants
    correspondingRow = find(strcmp(unitLocationsAllMice.UniqueID, thisUnit));
    medianChangeInFiringRate = medianChangeInRateConcat(correspondingRow,:);
    medianChangeInFiringRateAll = [medianChangeInFiringRateAll; medianChangeInFiringRate];
    meanChangeInVelocityInsignificantOdorsOnly = allVelocityTestResultsTable.("mean change in velocity")(strcmp(allVelocityTestResultsTable.Mouse,thisMouse))';
    meanChangeInVelocityAll = [meanChangeInVelocityAll; meanChangeInVelocityInsignificantOdorsOnly];

    % Get the response to only significantly odor-tuned odorants
    correspondingRows = find(strcmp(significantResults.UniqueID, thisUnit));
    for iRow = 1:length(correspondingRows)
        thisRow = correspondingRows(iRow);
        thisOdorant = find(significantResults.Odorant(thisRow) == odorantNames);
        changeinFR = significantResults.medianChangeRate(thisRow);
        medianChangeInFiringRateSignificantOdorsOnly = [medianChangeInFiringRateSignificantOdorsOnly changeinFR];
        meanChangeInVelocityInsignificantOdorsOnly = allVelocityTestResultsTable.("mean change in velocity")(strcmp(allVelocityTestResultsTable.Mouse,thisMouse))';
        temp = meanChangeInVelocityInsignificantOdorsOnly(1,thisOdorant);
        meanChangeInVelocitySignificantOdorsOnly = [meanChangeInVelocitySignificantOdorsOnly temp];
    end

end

medianChangeInFiringRateInsignificantOdorsOnly = medianChangeInFiringRateAll;
meanChangeInVelocityInsignificantOdorsOnly = meanChangeInVelocityAll;
for iUnit = 1:nSpeedOdorCells
    thisUnit = speedAndOdorTunedCells(iUnit,1);

    % Get the response to NOT significantly odor-tuned odorants
    correspondingRow = find(strcmp(unitLocationsAllMice.UniqueID, thisUnit));
    correspondingRows = find(strcmp(significantResults.UniqueID, thisUnit));
    for iRow = 1:length(correspondingRows)
        thisRow = correspondingRows(iRow);
        thisOdorant = find(significantResults.Odorant(thisRow) == odorantNames);

        medianChangeInFiringRateInsignificantOdorsOnly(iUnit,thisOdorant) = nan;
        meanChangeInVelocityInsignificantOdorsOnly(iUnit,thisOdorant) = nan;
    end

end

medianChangeInFiringRateInsignificantOdorsOnly = medianChangeInFiringRateInsignificantOdorsOnly(:);
meanChangeInVelocityInsignificantOdorsOnly = meanChangeInVelocityInsignificantOdorsOnly(:);
medianChangeInFiringRateInsignificantOdorsOnly = medianChangeInFiringRateInsignificantOdorsOnly(~isnan(medianChangeInFiringRateInsignificantOdorsOnly));
meanChangeInVelocityInsignificantOdorsOnly = meanChangeInVelocityInsignificantOdorsOnly(~isnan(meanChangeInVelocityInsignificantOdorsOnly));
%% Plot both as heatmaps side by side

figure()
ax1 = subplot(1,2,1);
imagesc(medianChangeInFiringRateAll)
title('median change in firing rate (Hz)')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
%yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax1, bluewhitered);
cb = colorbar;
cb.Label.String = "median change in FR (Hz)";
set(gca,'fontsize', 18)
% from ChatGPT -- end --.

ax2 = subplot(1,2,2);
imagesc(meanChangeInVelocityAll)
title({"mean change in velocity"})
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
%yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax2, bluewhitered);
cb = colorbar;
cb.Label.String = "mean change in velocity (cm/sec)";
set(gca,'fontsize', 18)

saveas(gcf, saveFigDir + "\" + "velocity_heatmap_for_speed_cells_only" + ".png")
saveas(gcf, saveFigDir + "\" + "velocity_heatmap_for_speed_cells_only" + ".fig")

%% Plot as scatter plot

% correlation = corr(medianChangeInFiringRateAll(:),meanChangeInVelocityAll(:));
% figure()
% scatter(medianChangeInFiringRateAll(:),meanChangeInVelocityAll(:),'filled')
% xlabel("median change in firing rate upon odor presentation (Hz)")
% ylabel("mean change in velocity upon odor presentation (cm/sec)")
% title({"Response of units tuned to both speed and odor","correlation r = " + correlation})

correlation = corr(medianChangeInFiringRateSignificantOdorsOnly(:),meanChangeInVelocitySignificantOdorsOnly(:));
figure()
sgtitle("Central trial responses of units tuned to both speed and odor")
subplot(1,2,1)
scatter(medianChangeInFiringRateSignificantOdorsOnly(:),meanChangeInVelocitySignificantOdorsOnly(:),'filled')
xlabel("median change in firing rate upon odor presentation (Hz)")
ylabel("mean change in velocity upon odor presentation (cm/sec)")
title({"tuned odors only","correlation r = " + correlation})
x1 = xlim;
y1 = ylim;

% NOTE: IDEALLY I SHOULD REALLY Z-SCORE THE CHANGES IN FIRING RATE HERE
% (NORMALIZE BASED ON THE FIRING RATE STATISTICS FOR EACH NEURON). THE
% RATIO BETWEEN FIRING RATE AND RUNNING SPEED LIKELY DIFFERS BETWEEN SPEED
% CELLS, AND SO THE SHAPE OF THIS CORRELATION WILL CHANGE
correlation = corr(medianChangeInFiringRateInsignificantOdorsOnly,meanChangeInVelocityInsignificantOdorsOnly);
subplot(1,2,2)
scatter(medianChangeInFiringRateInsignificantOdorsOnly,meanChangeInVelocityInsignificantOdorsOnly,'filled')
xlabel("median change in firing rate upon odor presentation (Hz)")
ylabel("mean change in velocity upon odor presentation (cm/sec)")
title({"non-tuned odors only","correlation r = " + correlation})
xlim(x1)
ylim(y1)

saveas(gcf, saveFigDir + "\" + "odor_response_compare_velocity_and_firing_for_speed_cells" + ".png")
saveas(gcf, saveFigDir + "\" + "odor_response_compare_velocity_and_firing_for_speed_cells" + ".fig")