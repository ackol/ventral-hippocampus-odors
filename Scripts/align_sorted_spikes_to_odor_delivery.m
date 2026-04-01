% align_sorted_spikes_to_odor_delivery.m - This code is designed to import 
% data already processed from a single full recording after spike sorting (with
% manual curation and anatomical alignment already applied), align the 
% spiking activity with odor delivery, and statistically assess for odor 
% tuning 
%
%   Inputs:
%       (1) [IDxxx]_full_session_odor_sequence_matrix.mat (containing
%       "odorSeqMat" variable and others)
%       
%       (2) [IDxxx]_D[x]_full_session_pid_data.mat (containing "odorSetInfo" variable)
%       
%       (3) [IDxxx]_aligned_phy_unit_data.mat (containing
%       "alignedUnitDataStruct" variable)
%           Note: in Version 3.0 of this script, the analogous variable was
%           the "alignedUnitDataStruct" variable.
%           Note: in Version 1.0 of this script, the analogous variable was
%           the "goodUnitsTable" variable.
%
%
%   Outputs:
%       (1) [IDxxx]_sortedspikes_curated_medianchangeinrate.mat
%       (2) [IDxxx]_sortedspikes_curated_pairedTtestresults.mat
%       (3) [IDxxx]_sortedspikes_curated_pairedTtestresults_significant_alpha5.mat
%       
%
%   Dependencies:
%       ...
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: September 13, 2024
% Script last updated: March 31, 2026
% Version 4.0

%% PART ONE: Load data and get parameters

clear all
clc

saveImages = true;

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% load odor delivery timing
[file, path] = uigetfile(".mat","Select [IDxxx]_full_session_odor_sequence_matrix.mat",baseDir);
load(fullfile(path,file));

% load odorant identities
[file, path] = uigetfile(".mat","Select .mat file containing PID data ([AK0xx]_D[x]_full_session_pid_data.mat.",baseDir);
load(fullfile(path,file),"odorSetInfo");
thisOdorSet = odorSetInfo.setLayout;
if length(thisOdorSet)==1
    thisOdorSetInfo = odorSetInfo.("Set_" + thisOdorSet);
else
    error("Need to adapt the code to handle more than one sequentially presented odor set!")
end
odorIdentities = cellstr(thisOdorSetInfo.odorNames);

% load spike variable
[file, path] = uigetfile(".mat","Select .mat file containing alignedUnitDataStruct variable for " + mouseLabel + ".",baseDir);
tic
disp("Loading aligned units data structure...")
load(fullfile(path,file),"alignedUnitDataStruct"); % note: took <3 mins
toc

% get paths for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");
if saveImages == true

    savedirSpikeRasters = baseOutputPath + "\" + "1 - peristimulus spike rasters";
    savedirPSTH = baseOutputPath + "\" + "2 - PSTH";
    savedirRawCounts = baseOutputPath + "\" + "3 - raw spike counts";
    savedirAbsoluteChange = baseOutputPath + "\" + "4 - absolute change in spike counts";
    savedirAbsoluteChangeBar = baseOutputPath + "\" + "5 - spike count bar graph";
    savedirPercentChange = baseOutputPath + "\" + "6 - percent change";
    savedirPercentChangeBar = baseOutputPath + "\" + "7 - percent change bar";

    % make new folders if they do not already exist
    if ~exist(savedirSpikeRasters,'dir')
        mkdir(savedirSpikeRasters);
    end
    if ~exist(savedirPSTH,'dir')
        mkdir(savedirPSTH);
    end
    if ~exist(savedirRawCounts,'dir')
        mkdir(savedirRawCounts);
    end
    if ~exist(savedirAbsoluteChange,'dir')
        mkdir(savedirAbsoluteChange);
    end
    if ~exist(savedirAbsoluteChangeBar,'dir')
        mkdir(savedirAbsoluteChangeBar);
    end
    if ~exist(savedirPercentChange,'dir')
        mkdir(savedirPercentChange);
    end
    if ~exist(savedirPercentChangeBar,'dir')
        mkdir(savedirPercentChangeBar);
    end
end
savedirStatisticalTests = baseOutputPath + "\" + "8 - statistical tests";
if ~exist(savedirStatisticalTests,'dir')
    mkdir(savedirStatisticalTests);
end

% Infer experimental parameters
nOdors = length(odorIdentities);
nTrialsPerOdor = length(odorSeqMat)/nOdors; % Here, this calculation rests upon the assumption that all odors are presented an equal number of times. May not always be true.

odorSampFreq = 30000; % Hz % TO-DO - in process_raw_behavior_rig_data, need to save/export sample frequency for odor data
odorTimeVector =  1:(1/odorSampFreq):((length(odorSignal)-1)/odorSampFreq); % in sec. 
nOdorPresentations = size(odorSeqMat,1); % total number of odorant trials in this experiment
onPoints = odorSeqMat(:,4); % sampling points at which odor turned on
offPoints = odorSeqMat(:,5); % sampling points at which odor turned off
odorDeliveryDurations = offPoints - onPoints; % Observation: there is some error in the on/off timing for each odorant trial relative to other trials
odorDeliveryDurationsTime = odorDeliveryDurations/odorSampFreq; % Observation: that error is all in the thousandths of a second range (millisecond error)
onTimes = odorSeqMat(:,4)/odorSampFreq; % sample points at which odor turned on, in seconds
offTimes = odorSeqMat(:,5)/odorSampFreq; % sample points at which odor turned off, in seconds

% Define intra-trial time windows
timeBefore = 5; % (seconds) set the amount of time prior to odorant onset to be considered "before" time
timeDuring = 3; % (seconds) set duration of odorant presentation
timeAfter = 10; % (seconds) set the amount of time after odorant onset to be considered "after" time
pointsBefore = timeBefore*odorSampFreq; 
pointsDuring = timeDuring*odorSampFreq;
pointsAfter = timeAfter*odorSampFreq;

singleTrialTimeVector = -timeBefore:(1/odorSampFreq):(timeDuring+timeAfter-1/odorSampFreq); % in seconds

% Get total number of units
nUnits = numel(fieldnames(alignedUnitDataStruct))-1;
% Get total recording duration (in sample points)
nSamples = alignedUnitDataStruct.UNIT001.info.nSamples;

clear file

disp("Finished loading data and getting parameters. PART ONE complete.")

%% PART TWO: Group spikes by odor trial

clear spikeRaster spikePeaksCell spikePeaks trialCountByOdor odorantNum onPoint

% Preallocate memory for new data structure
spikeRaster = nan(nOdors, nTrialsPerOdor, nUnits, pointsBefore+pointsDuring+pointsAfter); % Create empty 3D matrix for storing per-trial spike rasters, grouped by odorant identity

% Reformat spiking data
spikePeaks = zeros(nUnits,nSamples);
for iUnit = 1:nUnits
    spikeIndices = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
    spikePeaks(iUnit,spikeIndices) = 1;
end

% Extract summary information on each unit from the alignedUnitDataStruct
% before deleting it to save space in memory.
mainFields = fieldnames(alignedUnitDataStruct);
mainFields = mainFields(1:end-1);
keepFields = {'info','qualityMetrics'};
for iUnit = 1:nUnits
    thisField =  mainFields{iUnit};
    unitInfo.(thisField) = struct();
    for j = 1:numel(keepFields)
        fieldName = keepFields{j};
        unitInfo.(thisField).(fieldName) = alignedUnitDataStruct.(thisField).(fieldName);
    end
end

clear mainFields keepFields thisField iUnit fieldName alignedUnitDataStruct

% Populate new data structure, organizing spike logicals by odor identity,
% trial number, and electrode channel
% -- Reference time: took 91 seconds to run. | Took 101 seconds to complete
% on AK012 data
tic
disp("Grouping spiking data by trial...")
trialCountByOdor = zeros(1,nOdors);
for iPresentation = 1:nOdorPresentations
    fprintf('Processing presentation #%d/%d \r',iPresentation,nOdorPresentations);
    drawnow;
    odorantNum = odorSeqMat(iPresentation,1); % get port number
    onPoint = onPoints(iPresentation);
    trialCountByOdor(1,odorantNum) = trialCountByOdor(1,odorantNum) + 1; % increment trial count for that odorant
    
    spikeRaster(odorantNum, trialCountByOdor(1,odorantNum), :, :) = spikePeaks(:, (onPoint-pointsBefore):(onPoint+pointsDuring+pointsAfter-1));
end
fprintf('\n')
toc

clear iPresentation odorantNum 
%%
tic
disp("Saving spikes_grouped_by_odor_trial data structure to .mat file.")
save(savedirStatisticalTests + "\" + mouseLabel + "" + "_spikes_grouped_by_odor_trial.mat","spikeRaster", "mouseLabel","timeBefore","timeDuring","timeAfter","sampFreq","unitInfo",'-v7.3');
toc

disp("Finished grouping spikes by odor trial. PART TWO complete.")

%% PART THREE: Compute spike counts before and during odor delivery

disp("Computing spike counts before and during odor delivery.")

tic

% Preallocate memory for new data structure
beforeCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity
duringCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity

startIndex = pointsBefore-pointsDuring; % start counting spikes from 2 seconds in to trial, 
onsetIndex = startIndex + pointsDuring;
endIndex = onsetIndex + pointsDuring;

for iUnit = 1:nUnits
        
    disp("Processing unit #" + num2str(iUnit))

    for iOdorant = 1:nOdors

        for iTrial = 1:nTrialsPerOdor
            beforeCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,startIndex:(onsetIndex-1)));
            duringCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,onsetIndex:endIndex));
        end

    end
end

disp("Finished computing spike counts. PART THREE complete.")

%% PART FOUR: Plotting

nRows = 4;

%% PART 4.1: Plot spike rasters for each electrode channel for each odorant across trials

clear iUnit f iOdorant data yPoints xPoints xPointsSec 

if saveImages == true

    tic
    for iUnit = 1:nUnits
        disp("-----Processing unit #" + num2str(iUnit) + "------")
    
        f = figure('visible','off');
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
        thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
        sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
        set(gcf,'Position',[550 50 1500 1300])
        
        for iOdorant = 1:nOdors
    
        disp("Processing odor #" + num2str(iOdorant))
    
            data = logical(squeeze(spikeRaster(iOdorant, :,iUnit,:)));
            [yPoints,xPoints] = find(data==1);
            xPointsSec = xPoints/sampFreq - 5;
            
            % plot spike trains
            subplot(nRows,nOdors/nRows,iOdorant)
            plot(xPointsSec,yPoints,'|k','MarkerSize',3);
            hold on
            set(gca,'YDir','reverse');
            xlim([-timeBefore timeDuring+timeAfter])
            set(gca,'XAxisLocation','top','TickDir','out') 
            xlabel('Time (s)');
            ylabel('Trial');
            ylim([-0.5 12.5])
            xline(0)
            xline(timeDuring)
            rectangle('Position',[0,-0.5,timeDuring,13], ...
                      'FaceColor',[0 .5 .5 0.5], ...
                      'FaceAlpha', 0.3, ...
                      'EdgeColor','b',...
                      'LineWidth',0.1)
            title(odorIdentities{iOdorant})
            hold off
        end
    
        saveas(gcf, savedirSpikeRasters + "\" + mouseLabel + "_sortedcurated_spikerasters_unit" + num2str(iUnit, "%.3d") + ".png")
    
    end
    toc
    
    disp("Finished plotting peristimulus spike rasters.")

end

clear iUnit f iOdorant data yPoints xPoints xPointsSec

%% PART 4.2: Plot spike histograms for each electrode channel for each odorant across trials

clear binWidth binEdges nSamplesPerBin iUnit f iOdorant data yPoints xPoints xPointsSec counts countsR binCounts

% Manually set desired bin-width
binWidth = 1; % (seconds)
binEdges = -timeBefore:binWidth:(timeDuring+timeAfter);
nSamplesPerBin = binWidth*sampFreq; % number of sample points per histogram bin

if saveImages == true
    tic
    for iUnit = 1:nUnits
            
        disp("-----Processing unit #" + num2str(iUnit) + "-----")
    
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
        thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
        f = figure('visible','off');
        sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
        set(gcf,'Position',[550 50 1500 1300])
        
        for iOdorant = 1:nOdors
    
        disp("Processing odor #" + num2str(iOdorant))
    
            data = logical(squeeze(spikeRaster(iOdorant, :,iUnit,:)));
           
            % plot spike histograms
            subplot(nRows,nOdors/nRows,iOdorant)
    
            counts = sum(data,1);
            % bin the counts
            countsR = reshape(counts,nSamplesPerBin,((timeBefore+timeDuring+timeAfter)/binWidth));
            binCounts = sum(countsR,1);
    
            histogram('BinCounts', binCounts, 'BinEdges',binEdges)
            hold on
            xlim([-timeBefore timeDuring+timeAfter])
            ylim([0 max(binCounts)+1])
            set(gca,'XAxisLocation','top','TickDir','out') 
            title(odorIdentities{iOdorant})
            %set(gca,'XTick',[],'XAxisLocation','top','TickDir','out') 
            ylabel('Counts');
            rectangle('Position',[0,-0.5,timeDuring,10000],...
                      'FaceColor',[0 .5 .5 0.5],...
                      'FaceAlpha', 0.3, ...
                      'EdgeColor','b',...
                      'LineWidth',0.1)
            hold off
    
        end
    
        saveas(gcf, savedirPSTH + "\" + mouseLabel + "_sortedcurated_PSTH_unit" + num2str(iUnit, "%.3d") + ".png")
    %     set(gcf, 'Renderer', 'Painters');
    %     saveas(gcf, savedir + "\" + mouseLabel + "_MUA_PSTH_" + odorIdentities{iOdorant} + ".eps", 'epsc')
    
    end
    toc
    
    disp("Finished plotting peristimulus time histograms.")
end

clear binWidth binEdges nSamplesPerBin iUnit f iOdorant data yPoints xPoints xPointsSec counts countsR binCounts


%% PART 4.3: Plot raw spike counts before and during odor delivery

disp("Plotting raw spike counts before and during odor delivery...")

wilcoxanRankSumTestPValues = nan(nUnits,nOdors);
wilcoxanSignedRankTestPValues = nan(nUnits,nOdors);
pairedTTestPValues = nan(nUnits,nOdors);

tic
for iUnit = 1:nUnits

    disp("-----Processing unit #" + num2str(iUnit) + "-----")

    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    f = figure('visible','off');
    sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + iUnit, "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    set(gcf,'Position',[550 50 700 1300])

    minY = 0;
    maxY = 0;
    for iOdorant = 1:nOdors
        
        subplot(nRows,nOdors/nRows,iOdorant)

        x = [1 2];
        beforeCountThisOdorant = nan(1,nTrialsPerOdor);
        duringCountThisOdorant = nan(1,nTrialsPerOdor);

        for iTrial = 1:nTrialsPerOdor
            beforeCountThisOdorant(1,iTrial) = beforeCount(iOdorant, iTrial, iUnit);
            duringCountThisOdorant(1,iTrial) = duringCount(iOdorant, iTrial, iUnit);
            y = [beforeCount(iOdorant, iTrial, iUnit) duringCount(iOdorant, iTrial, iUnit)];
            if max(y) > maxY; maxY = max(y);end
            if min(y) < minY; minY = min(y); end
            plot(x,y,'-k.')
            hold on
        end
        % Perform statistical test to evaluate this unit's response to
        % this odorant
        % wilcoxan rank sum test -- evaluates whether the medians of the
        % two population distributions are equal to each other
        wilcoxanRankSumTestPValues(iUnit,iOdorant) = ranksum(beforeCountThisOdorant, duringCountThisOdorant);
        wilcoxanSignedRankTestPValues(iUnit,iOdorant) = signrank(beforeCountThisOdorant, duringCountThisOdorant);

        
        % Perform a paired t-test
        [h, p, ci, stats] = ttest(beforeCountThisOdorant, duringCountThisOdorant);
        pairedTTestPValues(iUnit,iOdorant) = p;

%         % Display the results
%         fprintf('Hypothesis Test Result (h): %d\n', h);
%         fprintf('p-value: %.4f\n', p);
%         fprintf('Confidence Interval: [%.4f, %.4f]\n', ci(1), ci(2));
%         fprintf('t-statistic: %.4f\n', stats.tstat);
%         
%         % Interpretation
%         alpha = 0.05;  % Significance level
%         if h == 1
%             fprintf('Reject the null hypothesis: There is a significant difference between the means.\n');
%         else
%             fprintf('Fail to reject the null hypothesis: There is no significant difference between the means.\n');
%         end
        

        % Set plotting parameters
        xlim([0.5 2.5])
        xlabel({'time period relative to', 'odorant delivery'})
        ylabel('spike count')
        xticks([1 2])
        xticklabels({'before','during'})
        title({odorIdentities{iOdorant}, "WRS p-value: " + sprintf('%.3f',wilcoxanRankSumTestPValues(iUnit,iOdorant)),"WSR p-value: " + sprintf('%.3f',wilcoxanSignedRankTestPValues(iUnit,iOdorant)),"Paired t-test p-value: " + sprintf('%.3f',pairedTTestPValues(iUnit,iOdorant))})
        hold off

    end

    for iOdorant = 1:nOdors
        subplot(nRows,nOdors/nRows,iOdorant)
        ylim([0 maxY*1.05])
    end

    if saveImages == true
        saveas(f, savedirRawCounts + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_rawspikecounts.png")
    end
end

disp("Finished plotting raw spike counts.")

%% PART 4.4: Plot absolute change in spike count during odor delivery

disp("Plotting absolute change in spike count upon odor delivery...")

clear duringMetric

absoluteChangeMean = nan(nUnits,nOdors);
absoluteChangeStd = nan(nUnits,nOdors);

signTestPValues = nan(nUnits,nOdors);

for iUnit = 1:nUnits

    disp("Processing unit #" + num2str(iUnit))

    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    f = figure('visible','off');
    sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    set(gcf,'Position',[550 50 700 1300])

    minY = 0;
    maxY = 0;
    for iOdorant = 1:nOdors

        subplot(nRows,nOdors/nRows,iOdorant)

        countDiff = (duringCount(iOdorant, :, iUnit)-beforeCount(iOdorant, :, iUnit))./timeDuring; % in spikes/sec
        x = [1 2];

        for iTrial = 1:nTrialsPerOdor
            y = [0 countDiff(1,iTrial)];
            plot(x,y,'-k.')
            hold on
        end
        
        % get bounds for plotting
        maxY = max(countDiff(isfinite(countDiff)));
        minY = min(countDiff(isfinite(countDiff)));

        % Calculate statistical characteristics of the data
        absoluteChangeMean(iUnit,iOdorant) = mean(countDiff(isfinite(countDiff)));
        absoluteChangeStd(iUnit,iOdorant) = std(countDiff(isfinite(countDiff)));
        % Perform statistical test to evaluate whether this unit's responds
        % to this odorant:
        % Sign Test -- evaluates whether the median of the paired sample
        % differences is zero
        signTestPValues(iUnit,iOdorant) = signtest(countDiff);

        % Set plotting parameters
        xlim([0.5 2.5])
        if minY==maxY
            ylim([-10 10])
        else
            ylim([minY*1.2 maxY*1.2])
        end
        xlabel({'time period relative to', 'odorant delivery'})
        ylabel('absolute change in spike count (spikes/sec)')
        xticks([1 2])
        xticklabels({'before','during'})
        yline(0,'--')
        title({odorIdentities{iOdorant}, "sign test p-value: " + sprintf('%.3f',signTestPValues(iUnit,iOdorant))})
        hold off


    end

    if saveImages == true
        saveas(f, savedirAbsoluteChange + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_absolutechange.png")
    end
end

disp("Finished plotting absolute change in spike counts.")

%% PART 4.5: Plot bar graph of absolute change in spike count before and after delivery

if saveImages == true
    for iUnit = 1:nUnits
        disp("Processing unit #" + num2str(iUnit))
        
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;
        thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
        f = figure('visible','off');
        sgtitle("Mouse " + mouseLabel + " - sorted & curated - Unit #" + num2str(iUnit) + ", Ch#" + thisContactNum + ", " + thisAnatomicalRegion)
        set(gcf,'Position',[550 550 700 500])
    
        x = 1:nOdors;
        bar(x,absoluteChangeMean(iUnit,:))                
        hold on
        er = errorbar(x,absoluteChangeMean(iUnit,:),absoluteChangeStd(iUnit,:));    
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  
        xticks(x)
        xticklabels(odorIdentities)
        xlabel('odorant')
        ylabel({'absolute change in spike count','(error bars 2SD in length)'})
        hold off
    
        saveas(f, savedirAbsoluteChangeBar + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_absolutechange_bargraph-mean-std.png")
    
    end
    
    disp("Finished plotting bar graph of absolute change in spike counts.")
end

%% PART 4.6: Plot percent change in spike count before and during odor delivery

disp("Plotting percent change in spike count before vs. during odor delivery...")

clear duringMetric

meanPercentChange = nan(nUnits,nOdors);

for iUnit = 1:nUnits

    disp("Processing unit #" + num2str(iUnit))

    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    f = figure('visible','off');
    sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
    set(gcf,'Position',[550 50 700 1300])

   
    minY = 0;
    maxY = 0;
    for iOdorant = 1:nOdors
        
        subplot(nRows,nOdors/nRows,iOdorant)
        
        duringMetric = (duringCount(iOdorant, :, iUnit)-beforeCount(iOdorant, :, iUnit))./beforeCount(iOdorant, :, iUnit)*100;
        x = [1 2];
        
        for iTrial = 1:nTrialsPerOdor            
            y = [0 duringMetric(1,iTrial)];
            plot(x,y,'-k.')
            hold on
        end

        maxY = max(duringMetric(isfinite(duringMetric)));
        minY = min(duringMetric(isfinite(duringMetric)));
        xlim([0.5 2.5])
        if isempty(minY)
            ylim([-1 1])
        elseif minY == maxY
            ylim([minY-1 maxY+1])
        else
            ylim([minY*1.2 maxY*1.2])
        end
        xlabel({'time period relative to', 'odorant delivery'})
        ylabel('% change in spike count')
        xticks([1 2])
        xticklabels({'before','during'})
        yline(0,'--')
        title(odorIdentities{iOdorant})
        hold off

        meanPercentChange(iUnit,iOdorant) = mean(duringMetric(isfinite(duringMetric)));
        percentChangeStd(iUnit,iOdorant) = std(duringMetric(isfinite(duringMetric)));

    end

    if saveImages == true
        saveas(f, savedirPercentChange + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_percentchange.png")
    end
end

disp("Finished plotting percent change in spike counts.")

%% PART 4.7: Plot bar graph of percent change in spike count before and after delivery

if saveImages == true
    disp("Plotting bar graph of percent change in spike count...")
    
    for iUnit = 1:nUnits
        
        disp("Processing unit #" + num2str(iUnit))
        
        thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
        thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
        f = figure('visible','off');
        sgtitle("Mouse " + mouseLabel + " - sorted & curated - Unit #" + num2str(iUnit) + ", Ch#" + thisContactNum + ", " + thisAnatomicalRegion)
        set(gcf,'Position',[550 550 700 500])
    
        x = 1:nOdors;
        bar(x,meanPercentChange(iUnit,:))                
        hold on
        er = errorbar(x,meanPercentChange(iUnit,:),percentChangeStd(iUnit,:));    
        er.Color = [0 0 0];                            
        er.LineStyle = 'none';  
        xticks(x)
        xticklabels(odorIdentities)
        xlabel('odorant')
        ylabel({'percent change in spike count','(error bars 2SD in length)'})
        hold off
    
        saveas(f, savedirPercentChangeBar + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_percentchange_bargraph-mean-std.png")
    
    end
    
    disp("Finished plotting bar graph of percent change in spike count.")
end

%% PART FIVE: Get Unit-Odor combos with p-values > alpha

clear alpha temp units odors tTestSignificant

alpha = 0.05;

% Paired t-test
temp = pairedTTestPValues < alpha;
[units, odors] = find(temp==1);

tTestSignificant = table(units, odorIdentities(odors)',pairedTTestPValues(sub2ind(size(pairedTTestPValues),units,odors)));
tTestSignificant.Properties.VariableNames = ["Unit #","Odorant","p-value"];
tTestSignificant = sortrows(tTestSignificant);

% Wilcoxan Rank Sum Test
temp = wilcoxanRankSumTestPValues < alpha;
[units, odors] = find(temp==1);

wrsTestSignificant = table(units, odorIdentities(odors)',wilcoxanRankSumTestPValues(sub2ind(size(wilcoxanRankSumTestPValues),units,odors)));
wrsTestSignificant.Properties.VariableNames = ["Unit #","Odorant","p-value"];
wrsTestSignificant = sortrows(wrsTestSignificant);

% Wilcoxan Signed Rank Test
temp = wilcoxanSignedRankTestPValues < alpha;
[units, odors] = find(temp==1);

wsrTestSignificant = table(units, odorIdentities(odors)',wilcoxanSignedRankTestPValues(sub2ind(size(wilcoxanSignedRankTestPValues),units,odors)));
wsrTestSignificant.Properties.VariableNames = ["Unit #","Odorant","p-value"];
wsrTestSignificant = sortrows(wsrTestSignificant);

% Sign Test
temp = signTestPValues < alpha;
[units, odors] = find(temp==1);

signTestSignificant = table(units, odorIdentities(odors)',signTestPValues(sub2ind(size(signTestPValues),units,odors)));
signTestSignificant.Properties.VariableNames = ["Unit #","Odorant","p-value"];
signTestSignificant = sortrows(signTestSignificant);

%% PART SIX: Get modulation value for all unit-odorant pairs

rateDiff = (duringCount - beforeCount)./timeDuring; % spikes / sec
medianRateDiff = median(rateDiff,2); % # rows = # odorants; # columns = # trials; # z-stack = # units

medianChangeInRate = squeeze(medianRateDiff)'; % spikes / sec

save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_medianchangeinrate", "medianChangeInRate",'-v7.3');

%% PART SEVEN: Get modulation direction for each significant unit-odorant pair

% ** NEED TO ADJUST THIS TO BE ABLE TO HANDLE WHEN THE SAME ODOR IS USED IN
% THE FIRST AND SECOND ODOR SETS (SINCE THE NAME FOR EACH IS THE SAME, IT
% GIVES A 2x1 logical array. <-- I believe this was fixed by appending "D"
% to the duplicate odors in the panel D array.
for iPair = 1:height(wsrTestSignificant)
    unit = wsrTestSignificant.("Unit #")(iPair);
    odorant = find(string(odorIdentities)==wsrTestSignificant.Odorant{iPair});

    if medianRateDiff(odorant,:,unit) > 0
        wsrTestSignificant.Direction(iPair) = "increase"; % odorant delivery results in increase in spike rate
    elseif medianRateDiff(odorant,:,unit) < 0
        wsrTestSignificant.Direction(iPair) = "decrease"; % odorant delivery results in increase in spike rate
    else
        fprintf("There is an error. A significant unit (iPair = %d) has a median change of zero. \n",iPair)
    end

    wsrTestSignificant.medianChangeRate(iPair) = medianRateDiff(odorant,:,unit);
   
end

%% PART EIGHT: Add anatomical location for each significant unit-odor pair

% For paired t-test
for iPair = 1:height(tTestSignificant)
    unit = tTestSignificant.("Unit #")(iPair);
    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    tTestSignificant.("Anatomical Location")(iPair) = thisAnatomicalRegion;
end

% For Wilcoxan Rank Sum Test
for iPair = 1:height(wrsTestSignificant)
    unit = wrsTestSignificant.("Unit #")(iPair);
    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    wrsTestSignificant.("Anatomical Location")(iPair) = thisAnatomicalRegion;
end

% For Wilcoxan Signed Rank test
for iPair = 1:height(wsrTestSignificant)
    unit = wsrTestSignificant.("Unit #")(iPair);
    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    wsrTestSignificant.("Anatomical Location")(iPair) = thisAnatomicalRegion;
end

% For Sign Test
for iPair = 1:height(signTestSignificant)
    unit = signTestSignificant.("Unit #")(iPair);
    thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
    thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    signTestSignificant.("Anatomical Location")(iPair) = thisAnatomicalRegion;
end

%% PART NINE: Export data

disp("Saving statistical test p-values...")
tic
% Save p-values
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_signtestresults", "signTestPValues","unitInfo",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_WRStestresults", "wilcoxanRankSumTestPValues","unitInfo",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_WSRtestresults", "wilcoxanSignedRankTestPValues","unitInfo",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_pairedTtestresults", "pairedTTestPValues","unitInfo",'-v7.3');
% Save unit-odor pairs with significant p-values
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_signtestresults_significant_alpha"+num2str(alpha*100), "signTestSignificant","alpha",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_WRStestresults_significant_alpha"+num2str(alpha*100), "wrsTestSignificant","alpha",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_WSRtestresults_significant_alpha"+num2str(alpha*100), "wsrTestSignificant","alpha",'-v7.3');
save(savedirStatisticalTests + "\" + mouseLabel + "_sortedspikes_curated_pairedTtestresults_significant_alpha"+num2str(alpha*100), "tTestSignificant","alpha",'-v7.3');
toc
disp("Done saving statistical test p-values.")

disp("Done running script.")

