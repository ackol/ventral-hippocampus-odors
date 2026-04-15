% generate_figures_for_talk_sfn_2025_populationvariability.m - This code is designed
% to ...
%
%   Inputs:
%       ...
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
% Script first created: October 1, 2024 (Version 1.0)
% Script last updated: November 11, 2025
% Version 3.0. 
% (Note: Version 1.0 was titled
% "generate_figures_for_talk_sfn_2024_populationvariability.m"; 
% Version 2.0 was titled
% "generate_figures_for_poster_achems_2025_populationvariability_v2.m")

%% PART ONE: Load results of statistical testing
clear vars

baseDir = uigetdir('',"Select base directory from which to navigate.");

% Load significant results from all animals
[file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file.",baseDir);
load(fullfile(path,file),"significantResults","mice"); 

% Load modulations medians (significant and not significant)
[file, path] = uigetfile(".mat","Select medianDeltaRateAllMice.mat file.",baseDir);
load(fullfile(path,file),"medianChangeInRateConcat","medianDeltaRate","nUnitsPerMouse"); 

% Load allUnitInfo from all animals
[file, path] = uigetfile(".mat","Select allUnitInfo.mat file.",baseDir);
load(fullfile(path,file),"allUnitInfo","totalUnits","mice","nMice"); 

nOdorantsPerUnit = 12;

clear file path

%% PART TWO: Get data on total number of units

% total number of recorded units
if ~(totalUnits==sum(nUnitsPerMouse))
    error("There is a discrepancy in the total number of units.")
end

% total number of tuned units
nUnitsOdorTuned = length(unique(significantResults.Mouse + significantResults.("Unit #"))); 
% total unit-odorant pairs
%nOdorantsPerUnit = 11; % Only evaluate results from Panel C (excluding air)
nOdorantsPerUnit = 12;
totalUnitOdorPairs = totalUnits*nOdorantsPerUnit;

%% Extract region-specific data

fields = fieldnames(allUnitInfo);
% Temporary fix --> all contacts that are labelled as CA3 have been
% determined to be in iCA3. Should re-run analysis from beginning, but for
% now, will simply substitute the labels here.
for iField = 1:numel(fields)
    if allUnitInfo.(fields{iField}).info.("anatomicAbbrev") == "CA3"
        allUnitInfo.(fields{iField}).info.("anatomicAbbrev") = "iCA3";
        allUnitInfo.(fields{iField}).info.("anatomicLocation") = "intermediate CA3";
    end
end
significantResults.("Anatomical Location")(significantResults.("Anatomical Location") == "CA3") = "intermediate CA3";
significantResults.("Anatomical Abbreviation")(significantResults.("Anatomical Abbreviation") == "CA3") = "iCA3";

% Count number of units found in each region
regions = string(cellfun(@(f) allUnitInfo.(f).info.("anatomicAbbrev"), fields, 'UniformOutput', false));
uniqueRegions = unique(regions);
nRegions = length(uniqueRegions);
for iRow = 1:nRegions
    uniqueRegions(iRow,2) = sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), uniqueRegions(iRow)), fields));
end


% vCA1
% get tuned vCA1 units only
vCA1rowIndices = significantResults.("Anatomical Abbreviation")=="vCA1";
vCA1significantResults = significantResults(vCA1rowIndices,:);
nUnitsVCA1 = sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), "vCA1"), fields));
nUnitsVCA1OdorTuned = length(unique(vCA1significantResults.Mouse + vCA1significantResults.("Unit #")));
% get median delta rate for all vCA1 units (i.e. all unit-odor pairs),
% including negative controls
vCA1medianDeltaRate = medianChangeInRateConcat(regions == "vCA1",:);
% get median delta rate for tuned vCA1-odor pairs
vCA1significantMedianDeltaRate = nan(height(vCA1significantResults),1);
for iPair = 1:height(vCA1significantResults)
    % mouse = vCA1significantResults.Mouse(iPair);
    % odorIndex = find(odorantsOrderedPanelC==vCA1significantResults.Odorant(iPair));
    % unit = vCA1significantResults.("Unit #")(iPair);
    %vCA1significantMedianDeltaRate(iPair) = medianDeltaRate.(mouse)(unit,odorIndex);
    vCA1significantMedianDeltaRate(iPair) = vCA1significantResults.medianChangeRate(iPair);
end


% CA3
% get tuned CA3 units only
CA3rowIndices = significantResults.("Anatomical Abbreviation")=="dCA3" | ...
    significantResults.("Anatomical Abbreviation")=="iCA3" | ...
    significantResults.("Anatomical Abbreviation")=="vCA3";
CA3significantResults = significantResults(CA3rowIndices,:);
nUnitsCA3 = sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), "dCA3"), fields)) +...
    sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), "iCA3"), fields)) + ...
    sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), "vCA3"), fields));
nUnitsCA3OdorTuned = length(unique(CA3significantResults.Mouse + CA3significantResults.("Unit #")));
% get median delta rate for all CA3 units (i.e. all unit-odor pairs),
% including negative controls
CA3medianDeltaRate = [medianChangeInRateConcat(regions == "dCA3",:);medianChangeInRateConcat(regions == "iCA3",:) ; medianChangeInRateConcat(regions == "vCA3",:)];
% get median delta rate for tuned CA3-odor pairs
CA3significantMedianDeltaRate = nan(height(CA3significantResults),1);
for iPair = 1:height(CA3significantResults)
    % mouse = CA3significantResults.Mouse(iPair);
    % odorIndex = find(odorantsOrderedPanelC==CA3significantResults.Odorant(iPair));
    % unit = CA3significantResults.("Unit #")(iPair);
    % CA3significantMedianDeltaRate(iPair) = medianDeltaRate.(mouse)(unit,odorIndex);
    CA3significantMedianDeltaRate(iPair) = CA3significantResults.medianChangeRate(iPair);
end

% DG
% get tuned Dentate gyrus units only
DGrowIndices = significantResults.("Anatomical Abbreviation")=="DG";
DGsignificantResults = significantResults(DGrowIndices,:);
nUnitsDG = sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), "DG"), fields));
nUnitsDGOdorTuned = length(unique(DGsignificantResults.Mouse + DGsignificantResults.("Unit #")));
% get median delta rate for all DG units (i.e. all unit-odor pairs),
% including negative controls
DGmedianDeltaRate = medianChangeInRateConcat(regions == "DG",:);
% get median delta rate for tuned CA3-odor pairs
DGsignificantMedianDeltaRate = nan(height(DGsignificantResults),1);
for iPair = 1:height(DGsignificantResults)
    % mouse = DGsignificantResults.Mouse(iPair);
    % odorIndex = find(odorantsOrderedPanelC==DGsignificantResults.Odorant(iPair));
    % unit = DGsignificantResults.("Unit #")(iPair);
    % DGsignificantMedianDeltaRate(iPair) = medianDeltaRate.(mouse)(unit,odorIndex);
    DGsignificantMedianDeltaRate(iPair) = DGsignificantResults.medianChangeRate(iPair);
end

%% Plot total number of neurons recorded per region

regionsToPlot = ["vCA1","CA3","DG"];
figure()
barh(regionsToPlot, [nUnitsVCA1 nUnitsCA3 nUnitsDG])
title("Number of recorded  units")
xlabel({"number of units","(n)"})

%% Plot total number of neurons recorded per subdivided regions

regionsToPlot = ["vCA1","iCA1","dCA1","vCA3","iCA3","dCA3","DG"];
nRegionsToPlot = length(regionsToPlot);
numberUnitsVec = [];
for iRow = 1:nRegionsToPlot
    numberUnitsVec = [numberUnitsVec sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), regionsToPlot(iRow)), fields))];
end
figure()
barh(regionsToPlot, numberUnitsVec)
title("Number of recorded  units")
xlabel({"number of units","(n)"})

%% Plot fraction of neurons that are tuned to neurons

regionsToPlot = ["vCA1","CA3","DG"];
figure()
barh(regionsToPlot, [nUnitsVCA1OdorTuned/nUnitsVCA1 nUnitsCA3OdorTuned/nUnitsCA3 nUnitsDGOdorTuned/nUnitsDG])
title("Fraction of units that are odor tuned")
xlabel({"percentage of units","%"})

%% Plot fraction of neurons that are tuned to neurons per subdivided regions

regionsToPlot = ["vCA1","iCA1","dCA1","vCA3","iCA3","dCA3","DG"];
nRegionsToPlot = length(regionsToPlot);
fractionUnitsVec = [];
for iRow = 1:nRegionsToPlot
    rowIndices = significantResults.("Anatomical Abbreviation")==regionsToPlot(iRow);
    significantResultsThisRegion = significantResults(rowIndices,:);
    nUnitsThisRegion = sum(cellfun(@(f) isequal(allUnitInfo.(f).info.("anatomicAbbrev"), regionsToPlot(iRow)), fields));
    nUnitsThisRegionOdorTuned = length(unique(significantResultsThisRegion.Mouse + significantResultsThisRegion.("Unit #")));
    fractionUnitsVec = [fractionUnitsVec nUnitsThisRegionOdorTuned/nUnitsThisRegion];
end
figure()
barh(regionsToPlot, fractionUnitsVec)
title("Fraction of units that are odor tuned")
xlabel({"percentage of units","%"})


%% Compute chi-squared test of independence



%% Examine distribution of delta rates (for all odor-unit pairs) between anatomic regions

% All odor trials (significant and non significant responses)

bins = [-7.5:1:18.5];

% Do you want to plot with y-axis in log scale?
yLog = true;
trimXaxis = false;
xlimits = [-5 5];

figure(300)
sgtitle("Distribution of all odor-pre median change in firing rates")
subplot(3,1,1)
histogram(vCA1medianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','LineWidth',1)
title("vCA1")
%xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
end
if trimXaxis == true
    xlim(xlimits)
end
hold on

subplot(3,1,2)
histogram(CA3medianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','LineWidth',1)
title("CA3")
%xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
end
if trimXaxis == true
    xlim(xlimits)
end

subplot(3,1,3)
histogram(DGmedianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','LineWidth',1)
title("DG")
xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
end
if trimXaxis == true
    xlim(xlimits)
end
%legend(["vCA1" "CA3" "DG"])

% Run Kruskal-Wallis test to assess if medians of the distribution differ
vCA1medianDeltaRateVec = vCA1medianDeltaRate(:);
CA3medianDeltaRateVec = CA3medianDeltaRate(:);
DGmedianDeltaRateVec = DGmedianDeltaRate(:);
allMedians = [vCA1medianDeltaRateVec; CA3medianDeltaRateVec; DGmedianDeltaRateVec];
regionsAll = [ones(size(vCA1medianDeltaRateVec)); 2*ones(size(CA3medianDeltaRateVec)); 3*ones(size(DGmedianDeltaRateVec))];

[p,tbl,stats] = kruskalwallis(allMedians,regionsAll);
[c, m, h, gnames] = multcompare(stats, 'CriticalValueType', 'dunn-sidak');

%% Plot fraction of positive vs. negative response



%% Examine distribution of delta rates (significant odor-unit pairs only) between anatomic regions

% Significant unit-odor pairs only

bins = [-7.5:1:18.5];
binCenters = (bins(1:end-1)+ bins(2:end))/2;
nBins = length(bins)-1;
clim([bins(1) bins(end)])
cmNew = bluewhitered(nBins);

% Do you want to plot with y-axis in log scale?
yLog = false;
trimXaxis = false;
xlimits = [bins(1) bins(end)];
xlimitsTrim = [-5 5];
%ylimits = [0 0.45]; % for probability setting
ylimits = [0 45]; % for percent setting
lineWidth = 1.5;

figure(300)
sgtitle("Distribution of significant odor-pre median change in firing rates")
subplot(3,1,3)
h = histogram(vCA1significantMedianDeltaRate,bins,'Normalization','percent','DisplayStyle','bar','LineWidth',1);
b = bar(binCenters,h.Values,1,'LineWidth',lineWidth);
b.FaceColor = 'flat';
b.CData = cmNew;
title("vCA1")
%xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
    ylim(ylimits)
end
if trimXaxis == true
    xlim(xlimitsTrim)
else
    xlim(xlimits)
end
hold on

subplot(3,1,2)
h = histogram(CA3significantMedianDeltaRate,bins,'Normalization','percent','DisplayStyle','bar','LineWidth',1);
b = bar(binCenters,h.Values,1,'LineWidth',lineWidth);
b.FaceColor = 'flat';
b.CData = cmNew;
title("CA3")
%xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
    ylim(ylimits)
end
if trimXaxis == true
    xlim(xlimitsTrim)
else
    xlim(xlimits)
end

subplot(3,1,1)
h = histogram(DGsignificantMedianDeltaRate,bins,'Normalization','percent','DisplayStyle','bar','LineWidth',1);
b = bar(binCenters,h.Values,1,'LineWidth',lineWidth);
b.FaceColor = 'flat';
b.CData = cmNew;
title("DG")
xlabel("median change in FR (Hz)")
if yLog == true
    ylabel("probability (log)")
    set(gca, 'YScale', 'log');
else
    ylabel("probability")
    ylim(ylimits)
end
if trimXaxis == true
    xlim(xlimitsTrim)
else
    xlim(xlimits)
end
%legend(["vCA1" "CA3" "DG"])


% plot on single plot
figure()
histogram(vCA1significantMedianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','FaceAlpha',0.5,'Orientation','horizontal','LineWidth',1)
hold on
histogram(CA3significantMedianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','FaceAlpha',0.5,'Orientation','horizontal','LineWidth',1)
histogram(DGsignificantMedianDeltaRate,bins,'Normalization','probability','DisplayStyle','bar','FaceAlpha',0.5,'Orientation','horizontal','LineWidth',1)
legend(["vCA1", "CA3","DG"])
title("distributions of median change in rate for tuned units only")

% Run Kruskal-Wallis test to assess if medians of the distribution differ
allSigMedians = [vCA1significantMedianDeltaRate; CA3significantMedianDeltaRate; DGsignificantMedianDeltaRate];
regionsSig = [ones(size(vCA1significantMedianDeltaRate)); 2*ones(size(CA3significantMedianDeltaRate)); 3*ones(size(DGsignificantMedianDeltaRate))];

[p,tbl,stats] = kruskalwallis(allSigMedians,regionsSig);
[c, m, h, gnames] = multcompare(stats, 'CriticalValueType', 'dunn-sidak');

%% Count units that are significantly modulated by each odor

% Count the total number of units that were significantly modulated by each
% odorant (across the whole population)
odorants = unique(significantResults.Odorant);
totalSignificantPerOdorant = nan(1,length(odorants));
significantResults.Odorant = string(significantResults.Odorant);
for i = 1:length(odorants)
    totalSignificantPerOdorant(i) = sum(significantResults.Odorant==odorants{i});
end
totalSignificantPerOdorantTable = table(odorants,totalSignificantPerOdorant');
totalSignificantPerOdorantTable.Properties.VariableNames([1 2]) = {'Odorants','Count'};
totalSignificantPerOdorantTable = sortrows(totalSignificantPerOdorantTable,"Count",'descend');

% Count the total number of units that were significantly modulated by each
% odorant (across the vCA1 population)
totalvCA1SignificantPerOdorant = nan(1,length(odorants));
for i = 1:length(odorants)
    totalvCA1SignificantPerOdorant(i) = sum(string(vCA1significantResults.Odorant)==odorants{i});
end
totalvCA1SignificantPerOdorantTable = table(odorants,totalvCA1SignificantPerOdorant');
totalvCA1SignificantPerOdorantTable.Properties.VariableNames([1 2]) = {'Odorants','Count'};
totalvCA1SignificantPerOdorantTable = sortrows(totalvCA1SignificantPerOdorantTable,"Count",'descend');

% Count the total number of units that were significantly modulated by each
% odorant (across the CA3 population)
totalCA3SignificantPerOdorant = nan(1,length(odorants));
for i = 1:length(odorants)
    totalCA3SignificantPerOdorant(i) = sum(string(CA3significantResults.Odorant)==odorants{i});
end
totalCA3SignificantPerOdorantTable = table(odorants,totalCA3SignificantPerOdorant');
totalCA3SignificantPerOdorantTable.Properties.VariableNames([1 2]) = {'Odorants','Count'};
totalCA3SignificantPerOdorantTable = sortrows(totalCA3SignificantPerOdorantTable,"Count",'descend');

% Count the total number of units that were significantly modulated by each
% odorant (across the DG population)
totalDGSignificantPerOdorant = nan(1,length(odorants));
for i = 1:length(odorants)
    totalDGSignificantPerOdorant(i) = sum(string(DGsignificantResults.Odorant)==odorants{i});
end
totalDGSignificantPerOdorantTable = table(odorants,totalDGSignificantPerOdorant');
totalDGSignificantPerOdorantTable.Properties.VariableNames([1 2]) = {'Odorants','Count'};
totalDGSignificantPerOdorantTable = sortrows(totalDGSignificantPerOdorantTable,"Count",'descend');


%% Sort responses by anatomical location and chemical functional group

% Load unitLocationsAllMice from all animals
[file, path] = uigetfile(".mat","Select unitLocationsAllMice.mat file.",baseDir);
load(fullfile(path,file)); 

% I think this following code was used originally to produce the
% unitLocationsAllMice.mat data structure? However, I think that structure
% was subsequently manually modified to correctly assign subregions to the
% CA3 units. When the following code is re-run, it results in a generic
% "CA3" category. 
% unitLocationsAllMice = table();
% unitColumn = [];
% anatomicalLocationColumn = [];
% mouseColumn = [];
% unitCounter = 1;
% mouseCounter = 1;
% for iUnit = 1:totalUnits
%     unitColumn = [unitColumn; unitCounter];
%     anatomicalLocationColumn = [anatomicalLocationColumn; allUnitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev];
%     mouseColumn = [mouseColumn; allUnitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.mouse];
%     if unitCounter < nUnitsPerMouse(mouseCounter)
%         unitCounter = unitCounter + 1;
%     else
%         unitCounter = 1;
%         mouseCounter = mouseCounter + 1;
%     end
% end
% unitLocationsAllMice.unit = unitColumn;
% unitLocationsAllMice.("anatomical location") = anatomicalLocationColumn;
% unitLocationsAllMice.mouse = mouseColumn;
% 
% %save(baseDir + "\" + "unitLocationsAllMice.mat", "unitLocationsAllMice",'-v7.3');


% create new version that has units sorted by anatomical location
medianChangeInRateConcatAnatomicalSort = [];
% create custum anatomical ordering
% [found, idx] = ismember(unitLocationsAllMice.("anatomical location"), ...
%     ["Dentate gyrus","CA3","vCA1","iCA1","dCA1","CA2","Subiculum",...
%     "Basolateral amygdalar nucleus posterior part","Endopiriform nucleus ventral part",...
%     "Postpiriform transition area","V1"]);
[found, idx] = ismember(unitLocationsAllMice.("anatomical location"), ...
    ["DG","iCA3","vCA3","iCA1","vCA1","CA2","dCA1","dCA3","SUB",...
    "BLAp","EPv", "TR","V1"]);
[~, sortorder] = sort(idx);
unitLocationsAllMiceSorted = unitLocationsAllMice(sortorder,:); 

for iRow = 1:height(unitLocationsAllMiceSorted)
    thisMouse = unitLocationsAllMiceSorted.('mouse')(iRow);
    thisIndex = unitLocationsAllMiceSorted.('unit')(iRow);
    thisResponse = medianDeltaRate.(thisMouse)(thisIndex,:);
    medianChangeInRateConcatAnatomicalSort = [medianChangeInRateConcatAnatomicalSort ; thisResponse];
end


odorantsOrderedPanelCFcnGrpSort = ["limonene", "cumene", "1-octanol", "eugenol", "hexanal", "valeraldehyde", "amyl acetate", "isoamyl acetate", "acetophenone", "valeric acid","mineral oil", "air"];
includeAir = true;
if includeAir == true
    finalIdx = 12;
else
    finalIdx = 11;
end

if includeAir
    % sort odorants by chemical functional group
    medianChangeInRateConcatAnatomicalSortOdorSort = [
        medianChangeInRateConcatAnatomicalSort(:,1:6) ...
        medianChangeInRateConcatAnatomicalSort(:,8) ...
        medianChangeInRateConcatAnatomicalSort(:,10) ...
        medianChangeInRateConcatAnatomicalSort(:,7) ...
        medianChangeInRateConcatAnatomicalSort(:,9) ...
        medianChangeInRateConcatAnatomicalSort(:,11:12)]; 
else
    % sort odorants by chemical functional group
    medianChangeInRateConcatAnatomicalSortOdorSort = [
        medianChangeInRateConcatAnatomicalSort(:,1:6) ...
        medianChangeInRateConcatAnatomicalSort(:,8) ...
        medianChangeInRateConcatAnatomicalSort(:,10) ...
        medianChangeInRateConcatAnatomicalSort(:,7) ...
        medianChangeInRateConcatAnatomicalSort(:,9) ...
        medianChangeInRateConcatAnatomicalSort(:,11)]; 
end

%% Plot heatmap of all modulations (significant and not significant), grouped by anatomical location


figure()
ax1 = subplot(1,2,1);
imagesc(medianChangeInRateConcatAnatomicalSortOdorSort)
%title('median difference in spike rate (all units)')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
%clim([-13 18]) % USE ONLY FOR NULL DATA TO MATCH REAL DATA
cm = colormap(ax1, bluewhitered);
colorbar;
%c1.Label.String = "median change in rate (Hz)";
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
    line([0.5 size(medianChangeInRateConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInRateConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
% Hold off to stop overlaying
xline(11.5,'Color', 'black','LineWidth',2)
hold off;
% from ChatGPT -- end --.


%% Plot heatmap of ONLY statistically significant modulations, grouped by anatomical location

% get direction of modulation
responseDirection = zeros(totalUnits,nOdorantsPerUnit); % 1 for upmodulation, 0 for no modulation, -1 for downmodulation
responseMagnitude = zeros(totalUnits,nOdorantsPerUnit);

% only the significant results will have a modulation direction
significantResultsID = significantResults.Mouse + significantResults.("Unit #");
unitLocationsAllMiceSortedID = unitLocationsAllMiceSorted.mouse + unitLocationsAllMiceSorted.unit;

for i = 1:height(significantResults)
    
    % get odor (column number along the odor axis)
    odorNum = find(significantResults.Odorant(i) == odorantsOrderedPanelCFcnGrpSort);

    % get unit (row number along the unit axis)
    rowNum = find(unitLocationsAllMiceSortedID==significantResultsID(i));
    
    % set the response direction
    if (significantResults.Direction(i) == "increase")
        responseDirection(rowNum, odorNum) = 1;
    elseif (significantResults.Direction(i) == "decrease")
        responseDirection(rowNum, odorNum) = -1;
    end

    % set the response magnitude
    responseMagnitude(rowNum, odorNum) = medianChangeInRateConcatAnatomicalSortOdorSort(rowNum, odorNum);

end

%figure(6)
ax2 = subplot(1,2,2);
imagesc(responseMagnitude(:,1:finalIdx))
%title('modulation (significant units only)')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
%clim([-13 18])
colormap(ax2,bluewhitered);
c2 = colorbar;
ylabel(c2,'median change in rate (Hz)','FontSize',18,'Rotation',270);
c2.Label.Position(1) = 4;
set(gca, 'TickDir', 'out')
set(gca,'fontsize', 18)

% Overlay horizontal lines at the specified y-values
for i = 1:length(yLinePositions)
    line([0.5 size(medianChangeInRateConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)+0.5], ...
        [yLinePositions(i)+0.5 yLinePositions(i)+0.5], 'Color', 'k', 'LineWidth', 2);
end
% Overlay regional labels at the specified rows
for i = 1:length(newRegionIndices)
    % Get the row index
    row = newRegionIndices(i);
    % Place text at the center of the row (on the x-axis, at the midpoint)
    % Adjust the y-position to correspond to the row, and x-position to be the middle of the row
    text(size(medianChangeInRateConcatAnatomicalSortOdorSort(:,1:finalIdx), 2)/2, ...
        row, regionLabels(i), 'Color', 'black', ...
        'FontSize', 8, 'HorizontalAlignment', 'center');
end
xline(11.5,'Color', 'black','LineWidth',2)

%% Export Heatmap matrices for Krishnan

%medianChangeInRateConcatAnatomicalSortOdorSort
%responseMagnitude

%newRegionIndices 

label = 1;
mapRowIndexToAnatomy = [];
CA3count = 0;
for iRow = 1:length(regions)
    if any(newRegionIndices(2:end)==iRow)
        if label == 1
            label = 2;
            CA3count = 1;
        elseif label==2
            if CA3count > 2
                label = label + 1;
            end
            CA3count = CA3count + 1;
        else
            label = label + 1;
        end
    end
    mapRowIndexToAnatomy = [mapRowIndexToAnatomy label];
end
mapRowIndexToAnatomy(mapRowIndexToAnatomy > 3) = 4;

save(baseDir + "\" + "odortuning_heatmap_variables.mat","medianChangeInRateConcatAnatomicalSortOdorSort", "responseMagnitude","mapRowIndexToAnatomy",'-v7.3');

%% Plot sparsity versus direction of tuning for ALL units



%% Plot sparsity versus direction of tuning for significant units only

% get the mean magnitude of response (for ALL units) and the sparsity
meanMagnitudeEveryUnit = mean(medianChangeInRateConcatAnatomicalSort,2);
sparsityEveryUnit = sum(responseMagnitude(:,1:11) ~= 0,2);

% shrink matrix down to only include rows with at least one significant
% response
unitLocationsAllMiceSorted.UniqueID = unitLocationsAllMiceSorted.mouse + "-" + unitLocationsAllMiceSorted.unit;
significantResults.UniqueID = significantResults.Mouse + "-" + significantResults.("Unit #");
significantUnits = unique(significantResults.UniqueID);
rowIDs = ismember(unitLocationsAllMiceSorted.UniqueID,significantUnits);
responseMagnitudeOdorTunedUnitsOnly = responseMagnitude(rowIDs,:);
responseMagnitudeAllUnits = medianChangeInRateConcatAnatomicalSort(rowIDs,:);

sparsityPerUnit = sum(responseMagnitudeOdorTunedUnitsOnly(:,1:11) ~= 0, 2);
responseMagnitudePerUnit = sum(responseMagnitudeOdorTunedUnitsOnly(:,1:11), 2) ./ sum(responseMagnitudeOdorTunedUnitsOnly(:,1:11) ~= 0, 2);
meanResponseMagnitudeAllUnits = mean(responseMagnitudeAllUnits,2);

figure()
subplot(1,2,1)
histogram(sparsityPerUnit)
subplot(1,2,2)
histogram(sparsityEveryUnit)
%%
indicesCA3 = unitLocationsAllMiceSorted.("anatomical location")=="vCA3" | unitLocationsAllMiceSorted.("anatomical location")=="iCA3";
indicesCA1 = unitLocationsAllMiceSorted.("anatomical location")=="vCA1" | unitLocationsAllMiceSorted.("anatomical location")=="iCA1";
indicesDG = unitLocationsAllMiceSorted.("anatomical location")=="DG";
%%
yMin = -0.05;
yMax = 0.7; 

figure()
subplot(3,1,1)
scatter(meanMagnitudeEveryUnit(indicesCA1),sparsityEveryUnit(indicesCA1)/11,'b','filled','MarkerFaceAlpha',0.5)
hold on
scatter(meanMagnitudeEveryUnit(indicesCA3),sparsityEveryUnit(indicesCA3)/11,'g','filled','MarkerFaceAlpha',0.5)
scatter(meanMagnitudeEveryUnit(indicesDG),sparsityEveryUnit(indicesDG)/11,'m','filled','MarkerFaceAlpha',0.5)
%scatter(meanMagnitudeEveryUnit(indicesDG),sparsityEveryUnit(indicesDG)/11,'m','filled')
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("All units, all odors")
ylim([yMin yMax])
%legend(["DG","CA3","CA1",""])
legend(["CA1","CA3","DG"])

subplot(3,1,2)
scatter(meanResponseMagnitudeAllUnits,sparsityPerUnit/11,'filled','MarkerFaceAlpha',0.5)
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("Significant units, all odors")
ylim([yMin yMax])

subplot(3,1,3)
scatter(responseMagnitudePerUnit,sparsityPerUnit/11,'filled','MarkerFaceAlpha',0.5)
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("Significant unit-odor pairs only")
ylim([yMin yMax])

%%

xMin = -2;
xMax = 4;

figure()
sgtitle("All units, all odors")
subplot(3,1,1)
scatter(meanMagnitudeEveryUnit(indicesDG),sparsityEveryUnit(indicesDG)/11,'m','filled','MarkerFaceAlpha',0.5)
hold on
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("DG")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,2)
scatter(meanMagnitudeEveryUnit(indicesCA3),sparsityEveryUnit(indicesCA3)/11,'g','filled','MarkerFaceAlpha',0.5)
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("CA3")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,3)
scatter(meanMagnitudeEveryUnit(indicesCA1),sparsityEveryUnit(indicesCA1)/11,'b','filled','MarkerFaceAlpha',0.5)
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
title("CA1")
ylim([yMin yMax])
xlim([xMin xMax])

%%
Xedges = -2:0.5:4;
Yedges = -0.05:0.08:0.7;

figure()
subplot(3,1,1)
hist3([meanMagnitudeEveryUnit(indicesCA1) sparsityEveryUnit(indicesCA1)/11], 'Edges', {Xedges Yedges},'CDataMode','auto','FaceColor','interp');
view(2);        % top-down view
colorbar;
set(gca, 'ColorScale', 'log');
title("CA1")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,2)
hist3([meanMagnitudeEveryUnit(indicesCA3) sparsityEveryUnit(indicesCA3)/11],  'Edges', {Xedges Yedges},'CDataMode','auto','FaceColor','interp');
view(2);        % top-down view
colorbar;
set(gca, 'ColorScale', 'log');
title("CA3")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,3)
hist3([meanMagnitudeEveryUnit(indicesDG) sparsityEveryUnit(indicesDG)/11],  'Edges', {Xedges Yedges},'CDataMode','auto','FaceColor','interp');
view(2);        % top-down view
colorbar;
set(gca, 'ColorScale', 'log');
title("DG")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

%%

%%
Xedges = -2:0.2:4;
Yedges = -0.05:0.05:0.7;

logOn = false;

% Plot
figure()


subplot(3,1,3)
[counts, xedges, yedges] = histcounts2(meanMagnitudeEveryUnit(indicesCA1), sparsityEveryUnit(indicesCA1)/11, Xedges,Yedges);
% Smooth it
countsSmooth = imgaussfilt(counts, 0.75);
imagesc(xedges, yedges, countsSmooth');
set(gca, 'YDir', 'normal');
cb = colorbar;
if logOn
    set(gca, 'ColorScale', 'log');
    cb.Label.String = "log of smoothed counts";
else
    cb.Label.String = "smoothed counts";
end
title("CA1")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,2)
[counts, xedges, yedges] = histcounts2(meanMagnitudeEveryUnit(indicesCA3), sparsityEveryUnit(indicesCA3)/11, Xedges,Yedges);
% Smooth it
countsSmooth = imgaussfilt(counts, 0.75);
imagesc(xedges, yedges, countsSmooth');
set(gca, 'YDir', 'normal');
cb = colorbar;
if logOn
    set(gca, 'ColorScale', 'log');
    cb.Label.String = "log of smoothed counts";
else
    cb.Label.String = "smoothed counts";
end
title("CA2")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

subplot(3,1,1)
[counts, xedges, yedges] = histcounts2(meanMagnitudeEveryUnit(indicesDG), sparsityEveryUnit(indicesDG)/11, Xedges,Yedges);
% Smooth it
countsSmooth = imgaussfilt(counts, 0.75);
imagesc(xedges, yedges, countsSmooth');
set(gca, 'YDir', 'normal');
cb = colorbar;
if logOn
    set(gca, 'ColorScale', 'log');
    cb.Label.String = "log of smoothed counts";
else
    cb.Label.String = "smoothed counts";
end
title("DG")
xlabel("mean response magnitude (Hz)")
ylabel("fraction of odor panel")
ylim([yMin yMax])
xlim([xMin xMax])

%% 

% Can see okay from this one, but it gets smoothed past zero, and you lose the
% sparse density on the edges (which is part of what distinguishes the
% clusters)

% data
x1 = meanMagnitudeEveryUnit(indicesCA1); y1 = sparsityEveryUnit(indicesCA1)/11;
x2 = meanMagnitudeEveryUnit(indicesCA3); y2 = sparsityEveryUnit(indicesCA3)/11;
x3 = meanMagnitudeEveryUnit(indicesDG); y3 = sparsityEveryUnit(indicesDG)/11;

% Common grid
xlin = linspace(-2,4,20);
ylin = linspace(0,0.7,20);
[xi, yi] = meshgrid(xlin, ylin);

figure; hold on;

% Group 1
f1 = ksdensity([x1 y1], [xi(:) yi(:)]);
contour(xi, yi, reshape(f1,size(xi)), 'r', 'LineWidth', 1.5);

% Group 2
f2 = ksdensity([x2 y2], [xi(:) yi(:)]);
contour(xi, yi, reshape(f2,size(xi)), 'b', 'LineWidth', 1.5);

% Group 3
f3 = ksdensity([x3 y3], [xi(:) yi(:)]);
contour(xi, yi, reshape(f3,size(xi)), 'k', 'LineWidth', 1.5);

legend('CA1','CA3','DG');

%%
% Totally not able to distinguish the three groups (since their centers of
% density overlap)
figure; hold on;

[~,h1] = contourf(xi, yi, reshape(f1,size(xi)), 10, 'LineColor','none');
h1.FaceAlpha = 0.3;

[~,h2] = contourf(xi, yi, reshape(f2,size(xi)), 10, 'LineColor','none');
h2.FaceAlpha = 0.3;

[~,h3] = contourf(xi, yi, reshape(f3,size(xi)), 10, 'LineColor','none');
h3.FaceAlpha = 0.3;


%%
% Not sure why this just totally isn't working??
[n1,~,~] = histcounts2(x1,y1,20);
[n2,~,~] = histcounts2(x2,y2,20);
[n3,~,~] = histcounts2(x3,y3,20);

n1 = imgaussfilt(n1,0.5);
n2 = imgaussfilt(n2,0.5);
n3 = imgaussfilt(n3,0.5);

figure; hold on;
contour(n1','r');
contour(n2','b');
contour(n3','k');


%% PART THREE: PLOTTING
%% 3.1 Plot bar graph of number of units responding to each odorant stimulus

functionalGroupsColormap = [
    50 89 168; % #1 - dark blue -- alkenes
    22 157 203; % #2 - light blue -- alcohol
    235 167 33; % #3 - yellow -- aldehyde
    186 32 38; % #4 - magenta -- carboxylic acid
    92 193 161; % #5 - teal -- ester
    77 79 81; % #6 - gray -- ketone
    255 255 255 % #7 - white -- negative controls
]/255;
odorantToFunctionalGroup = [1 1 2 2 3 3 6 5 4 5 7];
odorantsOrderedPanelC = ["limonene", "cumene", "octanol", "eugenol", "hexanal", "valeraldehyde", "acetophenone", "amyl acetate", "valeric acid", "isoamyl acetate", "mineral oil", "air"];

for i = 1:height(totalSignificantPerOdorantTable)
    index = string(totalSignificantPerOdorantTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalSignificantPerOdorantTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
X = categorical(totalSignificantPerOdorantTable.Odorants);
X = reordercats(X,totalSignificantPerOdorantTable.Odorants);
figure()
b = bar(X, totalSignificantPerOdorantTable.Count'/totalUnits*100);
b.FaceColor = 'flat';
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(totalSignificantPerOdorantTable.FunctionalGroup(i),:);
end
xlabel('odorant')
ylabel('(%)')
title('probability of a unit being tuned to each odorant')

%% VCA1 only

for i = 1:height(totalvCA1SignificantPerOdorantTable)
    index = string(totalvCA1SignificantPerOdorantTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalvCA1SignificantPerOdorantTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
X = categorical(totalvCA1SignificantPerOdorantTable.Odorants);
X = reordercats(X,totalvCA1SignificantPerOdorantTable.Odorants);
figure()
b = bar(X, totalvCA1SignificantPerOdorantTable.Count'/totalUnits*100);
b.FaceColor = 'flat';
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(totalvCA1SignificantPerOdorantTable.FunctionalGroup(i),:);
end
xlabel('odorant')
ylabel('(%)')
title('probability of a vCA1 unit being tuned to each odorant')

%% CA3 only

for i = 1:height(totalCA3SignificantPerOdorantTable)
    index = string(totalCA3SignificantPerOdorantTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalCA3SignificantPerOdorantTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
X = categorical(totalCA3SignificantPerOdorantTable.Odorants);
X = reordercats(X,totalCA3SignificantPerOdorantTable.Odorants);
figure()
b = bar(X, totalCA3SignificantPerOdorantTable.Count'/totalUnits*100);
b.FaceColor = 'flat';
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(totalCA3SignificantPerOdorantTable.FunctionalGroup(i),:);
end
xlabel('odorant')
ylabel('(%)')
title('probability of a CA3 unit being tuned to each odorant')

%% DG only

for i = 1:height(totalDGSignificantPerOdorantTable)
    index = string(totalDGSignificantPerOdorantTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalDGSignificantPerOdorantTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
X = categorical(totalDGSignificantPerOdorantTable.Odorants);
X = reordercats(X,totalDGSignificantPerOdorantTable.Odorants);
figure()
b = bar(X, totalDGSignificantPerOdorantTable.Count'/totalUnits*100);
b.FaceColor = 'flat';
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(totalDGSignificantPerOdorantTable.FunctionalGroup(i),:);
end
xlabel('odorant')
ylabel('(%)')
title('probability of a DG unit being tuned to each odorant')


%% 3.2 Plot bar graph of number of units responding to each odorant stimulus, including negative controls and grouped by functional group

odorantToFunctionalGroup = [1 1 3 3 5 5 2 2 4 6 7];
odorantsOrderedPanelC = ["cumene", "limonene","hexanal", "valeraldehyde", "isoamyl acetate", "amyl acetate", "octanol", "eugenol",  "valeric acid", "acetophenone","mineral oil"];

for i = 1:height(totalSignificantPerOdorantTable)
    index = string(totalSignificantPerOdorantTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalSignificantPerOdorantTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
% X = categorical(totalSignificantPerOdorantNoControlsTable.Odorants);
% X = reordercats(X,totalSignificantPerOdorantNoControlsTable.Odorants);
X = categorical(totalSignificantPerOdorantTable.Odorants, ...
                odorantsOrderedPanelC, ...
                'Ordinal', true);

figure(100)
b = bar(X, totalSignificantPerOdorantTable.Count'/totalUnits);
b.FaceColor = 'flat';
% Set colors based on functional group
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(odorantToFunctionalGroup(i),:);
    %b.CData(i,:) = functionalGroupsColormap(totalSignificantPerOdorantNoControlsTable.FunctionalGroup(i),:);
end
% Add labels and title
xlabel('odorant')
ylabel('probability')
set(gca, 'TickDir', 'out','XTick',[])
set(gca,'fontsize', 18)
title('probability of a unit being tuned to each odorant (including controls)')

%% 3.3 Plot bar graph of number of units responding to each odorant stimulus, excluding negative controls and grouped by functional group

totalSignificantPerOdorantNoControlsTable = totalSignificantPerOdorantTable;
totalSignificantPerOdorantNoControlsTable(totalSignificantPerOdorantNoControlsTable.Odorants == "air",:) = [];

odorantToFunctionalGroup = [1 1 3 3 5 5 2 2 4 6 7];
odorantsOrderedPanelC = ["cumene", "limonene","hexanal", "valeraldehyde", "isoamyl acetate", "amyl acetate", "1-octanol", "eugenol",  "valeric acid", "acetophenone","mineral oil"];

for i = 1:height(totalSignificantPerOdorantNoControlsTable)
    index = string(totalSignificantPerOdorantNoControlsTable.Odorants(i))==odorantsOrderedPanelC;
    group = odorantToFunctionalGroup(index);
    totalSignificantPerOdorantNoControlsTable.FunctionalGroup(i) = group;
end

% plot bar graph showing probability of a given unit being tuned to each
% odorant
% X = categorical(totalSignificantPerOdorantNoControlsTable.Odorants);
% X = reordercats(X,totalSignificantPerOdorantNoControlsTable.Odorants);
X = categorical(totalSignificantPerOdorantNoControlsTable.Odorants, ...
                odorantsOrderedPanelC, ...
                'Ordinal', true);

figure(2)
b = bar(X, totalSignificantPerOdorantNoControlsTable.Count'/totalUnits);
b.FaceColor = 'flat';
% Set colors based on functional group
for i = 1:length(X)
    b.CData(i,:) = functionalGroupsColormap(odorantToFunctionalGroup(i),:);
    %b.CData(i,:) = functionalGroupsColormap(totalSignificantPerOdorantNoControlsTable.FunctionalGroup(i),:);
end
% Add labels and title
xlabel('odorant')
ylabel('probability')
set(gca, 'TickDir', 'out','XTick',[])
set(gca,'fontsize', 18)
title('probability of a unit being tuned to each odorant (excluding controls)')

%% Plot bar graph of probability of a given unit responding to k odorants

% Remove significant (unit, odorant) pairs where the odorant being
% responded to is a control condition
significantResultsNoControls = significantResults;
significantResultsNoControls(significantResultsNoControls.Odorant == "blank",:) = [];

significantResultsNoControls.CombinedUnitName = strcat(significantResultsNoControls.Mouse,string(significantResultsNoControls.("Unit #")));
responsiveUnits = unique(significantResultsNoControls.CombinedUnitName);
numSignificantOdorantsPerUnit = nan(length(responsiveUnits),1);
for i = 1:length(responsiveUnits)
    numSignificantOdorantsPerUnit(i) = sum(significantResultsNoControls.CombinedUnitName==responsiveUnits(i));
end
% add in all the units that don't respond to any odorant stimuli
unresponsiveUnits = totalUnits - length(responsiveUnits);

numResponsiveOdorantsPerUnit = [numSignificantOdorantsPerUnit' zeros(1,unresponsiveUnits)];

binEdges = [-0.5:1:max(numResponsiveOdorantsPerUnit)+1.5];
figure()
H = histogram(numResponsiveOdorantsPerUnit,'BinEdges',binEdges,'Normalization','probability','FaceColor','k');
totalResponsiveFraction = sum(H.Values(2:end));
%ylim([0 27])
xlabel('number of odorants (k)')
ylabel('probability')
title({'probability of a unit being tuned to k odorants','(excluding controls)',"total responsive fraction = " + totalResponsiveFraction})
set(gca,'fontsize', 18)
set(gca, 'TickDir', 'out')
xticks([0:6])

% clear responsive units

%% vCA1 only

% Remove significant (unit, odorant) pairs where the odorant being
% responded to is a control condition
vCA1significantResultsNoControls = vCA1significantResults;
vCA1significantResultsNoControls(vCA1significantResultsNoControls.Odorant == "blank",:) = [];

vCA1significantResultsNoControls.CombinedUnitName = strcat(vCA1significantResultsNoControls.Mouse,string(vCA1significantResultsNoControls.("Unit #")));
responsiveUnits = unique(vCA1significantResultsNoControls.CombinedUnitName);
numSignificantOdorantsPerUnit = nan(length(responsiveUnits),1);
for i = 1:length(responsiveUnits)
    numSignificantOdorantsPerUnit(i) = sum(vCA1significantResultsNoControls.CombinedUnitName==responsiveUnits(i));
end
% add in all the units that don't respond to any odorant stimuli
unresponsiveUnits = nUnitsVCA1 - length(responsiveUnits);

numResponsiveOdorantsPerUnit = [numSignificantOdorantsPerUnit' zeros(1,unresponsiveUnits)];

plotOnlyTunedNeurons = false;
% enable this line if you want to plot the fraction of tuned neurons that
% respond to k (>=1) odors. Otherwise, deactivate this line if you want to
% plot the fraction of all neurons that respond to k (>=0) odors.
if plotOnlyTunedNeurons == true
    numResponsiveOdorantsPerUnit(numResponsiveOdorantsPerUnit == 0) = [];
    binEdges = [0.5:1:5.5];
else
    binEdges = [-0.5:1:5.5];
end

%binEdges = [0.5:1:max(numResponsiveOdorantsPerUnit)+1];
figure()
H = histogram(numResponsiveOdorantsPerUnit,'BinEdges',binEdges,'Normalization','probability','FaceColor','k');
ylim([0 0.7])
xlabel('number of odorants (k)')
ylabel('probability')
title({'probability of a tuned vCA1 unit responding to k / 11 odorants'})
set(gca,'fontsize', 18)
set(gca, 'TickDir', 'out')
xticks([0:6])


%% CA3 only

% Remove significant (unit, odorant) pairs where the odorant being
% responded to is a control condition
CA3significantResultsNoControls = CA3significantResults;
CA3significantResultsNoControls(CA3significantResultsNoControls.Odorant == "blank",:) = [];

CA3significantResultsNoControls.CombinedUnitName = strcat(CA3significantResultsNoControls.Mouse,string(CA3significantResultsNoControls.("Unit #")));
responsiveUnits = unique(CA3significantResultsNoControls.CombinedUnitName);
numSignificantOdorantsPerUnit = nan(length(responsiveUnits),1);
for i = 1:length(responsiveUnits)
    numSignificantOdorantsPerUnit(i) = sum(CA3significantResultsNoControls.CombinedUnitName==responsiveUnits(i));
end
% add in all the units that don't respond to any odorant stimuli
unresponsiveUnits = nUnitsCA3 - length(responsiveUnits);

numResponsiveOdorantsPerUnit = [numSignificantOdorantsPerUnit' zeros(1,unresponsiveUnits)];

plotOnlyTunedNeurons = false;
% enable this line if you want to plot the fraction of tuned neurons that
% respond to k (>=1) odors. Otherwise, deactivate this line if you want to
% plot the fraction of all neurons that respond to k (>=0) odors.
if plotOnlyTunedNeurons == true
    numResponsiveOdorantsPerUnit(numResponsiveOdorantsPerUnit == 0) = [];
    binEdges = [0.5:1:5.5];
else
    binEdges = [-0.5:1:5.5];
end

%binEdges = [0.5:1:max(numResponsiveOdorantsPerUnit)+1];
figure()
H = histogram(numResponsiveOdorantsPerUnit,'BinEdges',binEdges,'Normalization','probability','FaceColor','k');
ylim([0 0.7])
xlabel('number of odorants (k)')
ylabel('probability')
title({'probability of a tuned CA3 unit responding to k / 11 odorants'})
set(gca,'fontsize', 18)
set(gca, 'TickDir', 'out')
xticks([0:6])

%% DG only

% Remove significant (unit, odorant) pairs where the odorant being
% responded to is a control condition
DGsignificantResultsNoControls = DGsignificantResults;
DGsignificantResultsNoControls(DGsignificantResultsNoControls.Odorant == "blank",:) = [];
DGsignificantResultsNoControls(DGsignificantResultsNoControls.Odorant == "mineral oil",:) = [];

DGsignificantResultsNoControls.CombinedUnitName = strcat(DGsignificantResultsNoControls.Mouse,string(DGsignificantResultsNoControls.("Unit #")));
responsiveUnits = unique(DGsignificantResultsNoControls.CombinedUnitName);
numSignificantOdorantsPerUnit = nan(length(responsiveUnits),1);
for i = 1:length(responsiveUnits)
    numSignificantOdorantsPerUnit(i) = sum(DGsignificantResultsNoControls.CombinedUnitName==responsiveUnits(i));
end
% add in all the units that don't respond to any odorant stimuli
unresponsiveUnits = nUnitsDG - length(responsiveUnits);

numResponsiveOdorantsPerUnit = [numSignificantOdorantsPerUnit' zeros(1,unresponsiveUnits)];

plotOnlyTunedNeurons = false;
% enable this line if you want to plot the fraction of tuned neurons that
% respond to k (>=1) odors. Otherwise, deactivate this line if you want to
% plot the fraction of all neurons that respond to k (>=0) odors.
if plotOnlyTunedNeurons == true
    numResponsiveOdorantsPerUnit(numResponsiveOdorantsPerUnit == 0) = [];
    binEdges = [0.5:1:5.5];
else
    binEdges = [-0.5:1:5.5];
end

%binEdges = [0.5:1:max(numResponsiveOdorantsPerUnit)+1];
figure()
H = histogram(numResponsiveOdorantsPerUnit,'BinEdges',binEdges,'Normalization','probability','FaceColor','k');
ylim([0 0.7])
xlabel('number of odorants (k)')
ylabel('probability')
title({'probability of a tuned DG unit responding to k / 11 odorants'})
set(gca,'fontsize', 18)
set(gca, 'TickDir', 'out')
xticks([0:6])

%% Get whether each responsive unit-odorant pair is excitatory or inhibitory

upmodulationCount = sum(significantResults.Direction == "increase");
downmodulationCount = sum(significantResults.Direction == "decrease");

totalUnitOdorPairs = height(significantResults);

upmodulationPercentage = upmodulationCount / totalUnitOdorPairs *100;
downmodulationPercentage = downmodulationCount / totalUnitOdorPairs *100;

upmodulationColor = [0 0 1];
downmodulationColor = [1 0 0];
piechartColors = [downmodulationColor; upmodulationColor];

figure(11)
piechart([upmodulationPercentage downmodulationPercentage],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'Response direction', '(including negative controls)'})
set(gca,'fontsize', 18)

%% vCA1 only

upmodulationCount = sum(vCA1significantResults.Direction == "increase");
downmodulationCount = sum(vCA1significantResults.Direction == "decrease");

totalUnitOdorPairs = height(vCA1significantResults);

upmodulationPercentage = upmodulationCount / totalUnitOdorPairs *100;
downmodulationPercentage = downmodulationCount / totalUnitOdorPairs *100;

upmodulationColor = [0 0 1];
downmodulationColor = [1 0 0];
piechartColors = [downmodulationColor; upmodulationColor];

% figure()
% piechart([upmodulationPercentage downmodulationPercentage],["excitatory", "inhibitory"])
% colororder(piechartColors)
% title({'vCA1 response direction', '(including negative controls)'})
% set(gca,'fontsize', 18)


figure()
negColor = [0	0.428571428571429	0.928571428571429]; % blue
posColor = [0.833333333333333	0	0]; % red
barh(1,upmodulationPercentage,'FaceColor',posColor);
hold on
barh(1,-downmodulationPercentage,'FaceColor',negColor);
title("vCA1")
legend(["increased" "decreased"])
ylabel("percent of tuned odor-unit pairs")
xlim([-90 90])


%% CA3 only

upmodulationCount = sum(CA3significantResults.Direction == "increase");
downmodulationCount = sum(CA3significantResults.Direction == "decrease");

totalUnitOdorPairs = height(CA3significantResults);

upmodulationPercentage = upmodulationCount / totalUnitOdorPairs *100;
downmodulationPercentage = downmodulationCount / totalUnitOdorPairs *100;

upmodulationColor = [0 0 1];
downmodulationColor = [1 0 0];
piechartColors = [downmodulationColor; upmodulationColor];
% 
% figure()
% piechart([upmodulationPercentage downmodulationPercentage],["excitatory", "inhibitory"])
% colororder(piechartColors)
% title({'CA3 response direction', '(including negative controls)'})
% set(gca,'fontsize', 18)

figure()
negColor = [0	0.428571428571429	0.928571428571429]; % blue
posColor = [0.833333333333333	0	0]; % red
barh(1,upmodulationPercentage,'FaceColor',posColor);
hold on
barh(1,-downmodulationPercentage,'FaceColor',negColor);
title("CA3")
legend(["increased" "decreased"])
ylabel("percent of tuned odor-unit pairs")
xlim([-90 90])

%% DG only

upmodulationCount = sum(DGsignificantResults.Direction == "increase");
downmodulationCount = sum(DGsignificantResults.Direction == "decrease");

totalUnitOdorPairs = height(DGsignificantResults);

upmodulationPercentage = upmodulationCount / totalUnitOdorPairs *100;
downmodulationPercentage = downmodulationCount / totalUnitOdorPairs *100;

upmodulationColor = [0 0 1];
downmodulationColor = [1 0 0];
piechartColors = [downmodulationColor; upmodulationColor];

figure()
piechart([upmodulationPercentage downmodulationPercentage],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'DG response direction', '(including negative controls)'})
set(gca,'fontsize', 18)

figure()
negColor = [0	0.428571428571429	0.928571428571429]; % blue
posColor = [0.833333333333333	0	0]; % red
barh(1,upmodulationPercentage,'FaceColor',posColor);
hold on
barh(1,-downmodulationPercentage,'FaceColor',negColor);
title("DG")
legend(["increased" "decreased"])
ylabel("percent of tuned odor-unit pairs")
xlim([-90 90])

%% Get whether each responsive unit-odorant pair is excitatory or inhibitory, excluding negative controls

upmodulationCountNoControls = sum(significantResultsNoControls.Direction == "increase");
downmodulationCountNoControls = sum(significantResultsNoControls.Direction == "decrease");

totalPairsNoControls = height(significantResultsNoControls);

upmodulationPercentageNoControls = upmodulationCountNoControls / totalPairsNoControls *100;
downmodulationPercentageNoControls = downmodulationCountNoControls / totalPairsNoControls *100;

figure()
piechart([upmodulationPercentageNoControls downmodulationPercentageNoControls],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'Response direction', '(excluding negative controls)'})
set(gca,'fontsize', 18)

%% vCA1 only
upmodulationCountNoControls = sum(vCA1significantResultsNoControls.Direction == "increase");
downmodulationCountNoControls = sum(vCA1significantResultsNoControls.Direction == "decrease");

totalPairsNoControls = height(vCA1significantResultsNoControls);

upmodulationPercentageNoControls = upmodulationCountNoControls / totalPairsNoControls *100;
downmodulationPercentageNoControls = downmodulationCountNoControls / totalPairsNoControls *100;

figure()
piechart([upmodulationPercentageNoControls downmodulationPercentageNoControls],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'vCA1 response direction', '(excluding negative controls)'})
set(gca,'fontsize', 18)

%% CA3 only

upmodulationCountNoControls = sum(CA3significantResultsNoControls.Direction == "increase");
downmodulationCountNoControls = sum(CA3significantResultsNoControls.Direction == "decrease");

totalPairsNoControls = height(CA3significantResultsNoControls);

upmodulationPercentageNoControls = upmodulationCountNoControls / totalPairsNoControls *100;
downmodulationPercentageNoControls = downmodulationCountNoControls / totalPairsNoControls *100;

figure()
piechart([upmodulationPercentageNoControls downmodulationPercentageNoControls],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'CA3 response direction', '(excluding negative controls)'})
set(gca,'fontsize', 18)

%% DG only
upmodulationCountNoControls = sum(DGsignificantResultsNoControls.Direction == "increase");
downmodulationCountNoControls = sum(DGsignificantResultsNoControls.Direction == "decrease");

totalPairsNoControls = height(DGsignificantResultsNoControls);

upmodulationPercentageNoControls = upmodulationCountNoControls / totalPairsNoControls *100;
downmodulationPercentageNoControls = downmodulationCountNoControls / totalPairsNoControls *100;

figure()
piechart([upmodulationPercentageNoControls downmodulationPercentageNoControls],["excitatory", "inhibitory"])
colororder(piechartColors)
title({'DG response direction', '(excluding negative controls)'})
set(gca,'fontsize', 18)

%% PART TWO: Plot Heatmaps

%% Plot heatmap of ALL modulations (significant and not significant)

figure(5)
ax1 = subplot(1,2,1);
imagesc(medianChangeInRateConcat(:,1:12))
%title('median difference in spike rate (all units)')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 50 100 150 200])
set(gca, 'TickDir', 'out')
colormap(ax1, bluewhitered);
colorbar;
%c1.Label.String = "median change in rate (Hz)";
set(gca,'fontsize', 18)

%% Plot heatmap of ONLY statistically significant modulations

% the port numbering for these odorants:
odorantsOrderedPanelC = ["limonene", "cumene", "octanol", "eugenol", "hexanal", "valeraldehyde", "acetophenone", "amyl acetate", "valeric acid", "isoamyl acetate", "mineral oil", "air"];

% get direction of modulation
responseDirection = zeros(totalUnits,nOdorantsPerUnit); % 1 for upmodulation, 0 for no modulation, -1 for downmodulation
responseMagnitude = zeros(totalUnits,nOdorantsPerUnit); % 1 for upmodulation, 0 for no modulation, -1 for downmodulation

% only the significant results will have a modulation direction
for i = 1:height(significantResults)
    
    % get row number along the unit axis
    thisMouse = significantResults.Mouse(i);

    if thisMouse == mice(1)
        rowNum = significantResults.("Unit #")(i);
    elseif thisMouse == mice(2)
        rowNum = significantResults.("Unit #")(i) + nUnitsPerMouse(1);
    elseif thisMouse == mice(3)
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:2));
    elseif thisMouse == mice(4)
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:3));
    elseif thisMouse == mice(5)
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:4));
    elseif thisMouse == mice(6)
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:5));
    elseif thisMouse == mice(7)
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:6));
    else
        rowNum = significantResults.("Unit #")(i) + sum(nUnitsPerMouse(1:7));
    end
    odorNum = find(significantResults.Odorant(i) == odorantsOrderedPanelC);
    
    % set the response direction
    if (significantResults.Direction(i) == "increase")
        responseDirection(rowNum, odorNum) = 1;
    elseif (significantResults.Direction(i) == "decrease")
        responseDirection(rowNum, odorNum) = -1;
    end

    % set the response magnitude
    responseMagnitude(rowNum, odorNum) = medianChangeInRateConcat(rowNum, odorNum);

end

%figure(6)
ax2 = subplot(1,2,2);
imagesc(responseMagnitude(:,1:12))
%title('modulation (significant units only)')
xlabel('odorant')
ylabel('unit #')
xticks([1 10])
yticks([1 74])
colormap(ax2,bluewhitered);
c2 = colorbar;
ylabel(c2,'median change in rate (Hz)','FontSize',18,'Rotation',270);
c2.Label.Position(1) = 4;
set(gca, 'TickDir', 'out')
set(gca,'fontsize', 18)


% %figure(6)
% ax2 = subplot(1,2,2);
% imagesc(responseDirection(:,1:10))
% %title('direction of modulation (significant units)')
% xlabel('odorant')
% ylabel('unit #')
% xticks([1 10])
% yticks([1 74])
% colormap(ax2,bluewhitered);
% colorbar
% set(gca, 'TickDir', 'out')
% set(gca,'fontsize', 18)
