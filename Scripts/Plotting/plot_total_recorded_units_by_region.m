% plot_total_recorded_units_by_region.m - This code is designed to produce
% a bar graph of the total number of units recorded in specified regions
%
%   Inputs:
%       [variable] - ...
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
% Script first created: March 12, 2026
% Script last updated: March 12, 2026
% Version 1.0. 

%% PART 1: Load data

mice = ["AK012", "AK013", "AK014", "AK015", "AK024", "AK025", "AK026", "AK027"];
nMice = length(mice);
allUnitsAllMice = table;
    
[file, path] = uigetfile(".mat","Select unitLocationsAllMice.mat file.",baseDir);
load(fullfile(path,file),"unitLocationsAllMice"); 
nUnits = height(unitLocationsAllMice);
    
[file, path] = uigetfile(".mat","Select brainRegions.mat file.",baseDir);
load(fullfile(path,file),"brainRegions","nRegions"); 

% select path for output data structures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");

%% PART 2: Compute total units per brain region

brainRegionsCount = brainRegions;

% get unit count per region
for iRegion = 1:(nRegions+1)
    brainRegionsCount{4,iRegion} = sum(strcmp(unitLocationsAllMice.("anatomical location"), brainRegionsCount{3, iRegion}));
end

regionAbbrev = string(brainRegionsCount(3,:))';
regionCounts = cell2mat(brainRegionsCount(4,:))';
regionCountsTable = table(regionAbbrev,regionCounts,'VariableNames', {'Region','Count'});

regionsOfInterest = ["vCA1","iCA1","vCA3","iCA3","DG"];
% Find rows to keep
idx = ismember(string(regionCountsTable.Region), regionsOfInterest);
% Keep selected rows
regionsOfInterestTable = regionCountsTable(idx,:);
% Sum all other rows
otherCount = sum(regionCountsTable.Count(~idx));
% Create "Other" row
regionsOtherTable = table("Other", otherCount, ...
    'VariableNames', {'Region','Count'});
% Combine tables
regionsSummaryTable= [regionsOfInterestTable; regionsOtherTable];

%% PART 2: Plot region distributions as pie chart

plotOrderPieChart = ["vCA1","iCA1","vCA3","iCA3","DG","Other"];
[~, idx] = ismember(plotOrderPieChart, string(regionsSummaryTable.Region));
regionsSummaryTable = regionsSummaryTable(idx, :);

figure()
p = piechart(regionsSummaryTable,"Count","Region");
p.LabelStyle = "namedata";


%% PART 3: Plot region distributions as stacked bar chart

dataToPlot = [
    0 0 regionsSummaryTable.Count(regionsSummaryTable.Region=="DG");
    regionsSummaryTable.Count(regionsSummaryTable.Region=="vCA3") regionsSummaryTable.Count(regionsSummaryTable.Region=="iCA3") 0;
    regionsSummaryTable.Count(regionsSummaryTable.Region=="vCA1") regionsSummaryTable.Count(regionsSummaryTable.Region=="iCA1") 0;
    0 0 regionsSummaryTable.Count(regionsSummaryTable.Region=="Other")
    ];

dataToPlot = flipud(dataToPlot);
totals = sum(dataToPlot,2);

figure;
barh(dataToPlot, 'stacked');
yticklabels(flip({'DG','CA3','CA1','Other'}));
xlabel('number of sorted single units');
legend({'ventral','intermediate',''});
hold on;
y = 1:size(dataToPlot,1);   % y positions of bars
for i = 1:length(y)
    text(totals(i), y(i), sprintf('  n = %d', totals(i)), ...
        'VerticalAlignment', 'middle', ...
        'FontWeight', 'bold');
end

% Save histogram
saveas(gcf, baseOutputPath + "\allMiceRegionDistribution" + ".png")
saveas(gcf, baseOutputPath + "\allMiceRegionDistribution" + ".svg")