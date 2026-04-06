% check_tuning_correlations_within_regions.m - This code is designed
% to calculate correlation between tuning curves for all tuned neurons in
% vCA1, CA3, and dentate gyrus
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: November 10, 2025
% Script last updated: November 13, 2025
% Version 1.0. 

%% PART ONE: Retrieve results of statistical testing

needToCompile = false;

baseDir = uigetdir('',"Select base directory from which to navigate.");

% Compile significant results from all animals
    % Run this part once --> save significantResults and mice variables to
    % "signficantResultsAllMice.mat" file for future use.
if needToCompile

    mice = ["AK012", "AK013", "AK014", "AK015", "AK024", "AK025", "AK026", "AK027"];
    nMice = length(mice);
    significantResults = table;
    
    [file, path] = uigetfile(".mat","Select unitLocationsAllMice.mat file.",baseDir);
    load(fullfile(path,file),"unitLocationsAllMice"); 
    
    for i = 1:nMice
        mouse = mice(i);
        % load results of sign test
        [file, path] = uigetfile(".mat","Select .mat file containing significant results with anatomical locations of WSR test for " + mouse + ".",baseDir);
        tic
        disp("Loading WSR test significant results...")
        load(fullfile(path,file),"wsrTestSignificant"); 
        wsrTestSignificant.Mouse = repmat(mouse,[height(wsrTestSignificant),1]);
        % if there are any signficant modulations from this mouse, concatenate
        % data:
        if height(wsrTestSignificant) > 0
            significantResults = vertcat(significantResults,wsrTestSignificant);
        end
        toc
    end

    save(baseDir + "\significantResultsAllMice.mat","significantResults","mice",'-v7.3')
    
    clear wsrTestSignificant i mouse 
% Load significant results from all animals
else
    [file, path] = uigetfile(".mat","Select significantResultsAllMice.mat file.",baseDir);
    load(fullfile(path,file),"significantResults","mice"); 
    nMice = length(mice);
end

clear file path


%% PART THREE: get list of odorants

% % Panel C odorants
% odorantsOrderedPanelC = ["limonene", "cumene", "octanol", "eugenol", "hexanal", "valeraldehyde", "acetophenone", "amyl acetate", "valeric acid", "isoamyl acetate", "mineral oil", "air"];
% odorantsOrderedPanelD = ["alpha-pinene","eucalyptol","methyl benzoate","hexanol","benzylaldehyde","heptanal","trans-3-octen-2-one","ethyl butyrate","butyric acid","hexyl acetate","mineral oil D","air D"];

%% Pull out only results from Panel C, excluding air

odorantsOrderedPanelCnoAir = ["limonene", "cumene", "1-octanol", "eugenol", "hexanal", "valeraldehyde", "acetophenone", "amyl acetate", "valeric acid", "isoamyl acetate", "mineral oil"];
odorantsOrderedPanelCFcnGrpSortNoAir = ["limonene", "cumene", "1-octanol", "eugenol", "hexanal", "valeraldehyde", "amyl acetate", "isoamyl acetate", "acetophenone", "valeric acid","mineral oil"];

rowsToKeep = ismember(significantResults.Odorant,odorantsOrderedPanelCnoAir);
significantResults = significantResults(rowsToKeep,:); % keep Panel C odorants only for now (no air)


%% Extract region-specific data

% vCA1
% get tuned vCA1 units only
vCA1rowIndices = significantResults.("Anatomical Abbreviation")=="vCA1";
vCA1significantResults = significantResults(vCA1rowIndices,:);
nUnitsVCA1OdorTuned = length(unique(vCA1significantResults.Mouse + vCA1significantResults.("Unit #")));
vCA1OdorTunedUnits = unique(vCA1significantResults.Mouse + num2str(vCA1significantResults.("Unit #"), "%.3d"));
vCA1significantResults.unitID = vCA1significantResults.Mouse + num2str(vCA1significantResults.("Unit #"), "%.3d");
% populate odor tuning matrix
vCA1tuningMatrix = zeros(11,nUnitsVCA1OdorTuned);
for iPair = 1:height(vCA1significantResults)
    unitID = find(vCA1OdorTunedUnits == vCA1significantResults.unitID(iPair));
    odor = find(vCA1significantResults.Odorant(iPair) == odorantsOrderedPanelCFcnGrpSortNoAir);
    vCA1tuningMatrix(odor,unitID) = vCA1significantResults.medianChangeRate(iPair);
end


% CA3
% get tuned CA3 units only
CA3rowIndices = significantResults.("Anatomical Abbreviation")=="CA3" | ...
    significantResults.("Anatomical Abbreviation")=="dCA3" | ...
    significantResults.("Anatomical Abbreviation")=="iCA3" | ...
    significantResults.("Anatomical Abbreviation")=="vCA3";
CA3significantResults = significantResults(CA3rowIndices,:);
nUnitsCA3OdorTuned = length(unique(CA3significantResults.Mouse + CA3significantResults.("Unit #")));
CA3OdorTunedUnits = unique(CA3significantResults.Mouse + num2str(CA3significantResults.("Unit #"), "%.3d"));
CA3significantResults.unitID = CA3significantResults.Mouse + num2str(CA3significantResults.("Unit #"), "%.3d");
% populate odor tuning matrix
CA3tuningMatrix = zeros(11,nUnitsCA3OdorTuned);
for iPair = 1:height(CA3significantResults)
    unitID = find(CA3OdorTunedUnits == CA3significantResults.unitID(iPair));
    odor = find(CA3significantResults.Odorant(iPair) == odorantsOrderedPanelCFcnGrpSortNoAir);
    CA3tuningMatrix(odor,unitID) = CA3significantResults.medianChangeRate(iPair);
end



% DG
% get tuned DG units only
DGrowIndices = significantResults.("Anatomical Abbreviation")=="DG";
DGsignificantResults = significantResults(DGrowIndices,:);
nUnitsDGOdorTuned = length(unique(DGsignificantResults.Mouse + DGsignificantResults.("Unit #")));
DGOdorTunedUnits = unique(DGsignificantResults.Mouse + num2str(DGsignificantResults.("Unit #"), "%.3d"));
DGsignificantResults.unitID = DGsignificantResults.Mouse + num2str(DGsignificantResults.("Unit #"), "%.3d");
% populate odor tuning matrix
DGtuningMatrix = zeros(11,nUnitsDGOdorTuned);
for iPair = 1:height(DGsignificantResults)
    unitID = find(DGOdorTunedUnits == DGsignificantResults.unitID(iPair));
    odor = find(DGsignificantResults.Odorant(iPair) == odorantsOrderedPanelCFcnGrpSortNoAir);
    DGtuningMatrix(odor,unitID) = DGsignificantResults.medianChangeRate(iPair);
end


clear file path 

%% Compute tuning correlations between neurons in each region

% compute & plot correlation matrices
vCA1Corr = corr(vCA1tuningMatrix);
figure()
imagesc(vCA1Corr)
title("vCA1 correlations between neural tuning profiles")
axis equal
colorbar

vCA1Corr = corrcoef(vCA1tuningMatrix);
figure()
imagesc(vCA1Corr)
title("vCA1 correlations between neural tuning profiles")
axis equal
colorbar


CA3Corr = corr(CA3tuningMatrix);
figure()
imagesc(CA3Corr)
title("CA3 correlations between neural tuning profiles")
axis equal
colorbar('location','east')

DGCorr = corr(DGtuningMatrix);
figure()
imagesc(DGCorr)
title("DG correlations between neural tuning profiles")
axis equal
colorbar


% get off diagonal elements
vCA1elements = vCA1Corr(tril(true(size(vCA1Corr)), -1));
CA3elements = CA3Corr(tril(true(size(CA3Corr)), -1));
DGelements = DGCorr(tril(true(size(DGCorr)), -1));

% get fraction with positive correlation
% vCA1
vCA1positiveFrac = sum(vCA1elements>0)/size(vCA1elements,1);
vCA1negativeFrac = sum(vCA1elements<0)/size(vCA1elements,1);
vCA1zeroFrac = sum(vCA1elements == 0)/size(vCA1elements,1);
% CA3
CA3positiveFrac = sum(CA3elements>0)/size(CA3elements,1);
CA3negativeFrac = sum(CA3elements<0)/size(CA3elements,1);
CA3zeroFrac = sum(CA3elements == 0)/size(CA3elements,1);
% DG
DGpositiveFrac = sum(DGelements>0)/size(DGelements,1);
DGnegativeFrac = sum(DGelements<0)/size(DGelements,1);
DGzeroFrac = sum(DGelements == 0)/size(DGelements,1);


% plot histograms
nBins = 9;
bins = [-1:(2/nBins):1];

% plot with counts
figure()
subplot(3,1,1)
histogram(vCA1elements,'Normalization','count','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("count")
title({"vCA1";"positive fraction: " + vCA1positiveFrac})
subplot(3,1,2)
histogram(CA3elements,'Normalization','count','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("count")
title({"CA3";"positive fraction: " + CA3positiveFrac})
subplot(3,1,3)
histogram(DGelements,'Normalization','count','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("count")
title({"DG";"positive fraction: " + DGpositiveFrac})


% normalize by probability
maxY = 0.6;
figure()
subplot(3,1,1)
histogram(vCA1elements,'Normalization','probability','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("probability")
title({"vCA1";"positive fraction: " + vCA1positiveFrac})
ylim([0 maxY])
subplot(3,1,2)
histogram(CA3elements,'Normalization','probability','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("probability")
title({"CA3";"positive fraction: " + CA3positiveFrac})
ylim([0 maxY])
subplot(3,1,3)
histogram(DGelements,'Normalization','probability','BinEdges',bins)
xlabel("tuning curve correlation across neurons")
ylabel("probability")
title({"DG";"positive fraction: " + DGpositiveFrac})
ylim([0 maxY])

%% Create combined vector for boxplots and statistical tests

combinedTuningCorr = [vCA1elements; CA3elements; DGelements];
groupTuningCorr = [ones(length(vCA1elements),1); 2*ones(length(CA3elements),1); 3*ones(length(DGelements),1)];


%% Run a kruskal-wallis test

[p, tbl, stats] = kruskalwallis(combinedTuningCorr,groupTuningCorr);
% Use Dunn to check pairwise comparisons
[c, m, h, gnames] = multcompare(stats, 'CriticalValueType', 'dunn-sidak');
%% Perform post-hoc pairwise comparisons

ztest()

%% Save tuning matrices for each region

save(baseDir + "\vCA1tuning.mat","vCA1tuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","vCA1OdorTunedUnits","vCA1significantResults",'-v7.3')
save(baseDir + "\CA3tuning.mat","CA3tuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","CA3OdorTunedUnits","CA3significantResults",'-v7.3')
save(baseDir + "\DGtuning.mat","DGtuningMatrix","odorantsOrderedPanelCFcnGrpSortNoAir","DGOdorTunedUnits","DGsignificantResults",'-v7.3')