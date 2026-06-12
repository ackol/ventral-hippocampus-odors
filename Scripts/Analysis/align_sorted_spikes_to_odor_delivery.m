% align_sorted_spikes_to_odor_delivery.m - This code is designed to import 
% data already processed from a single full recording after spike sorting (with
% manual curation and anatomical alignment already applied) and align the 
% spiking activity with odor delivery.
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
%       (1) [IDxxx]_spikes_grouped_by_odor_trial.mat, containing the
%       following variables:
%           spikeRaster
%           mouseLabel
%           timeBefore
%           timeDuring
%           timeAfter
%           sampFreq
%           nUnits
%           unitInfo
%           nOdors
%           nTrialsPerOdor
%           odorIdentities
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
% Script last updated: June 12, 2026
% Version 6.0

%% PART ONE: Load data and get parameters

clear all
clc

dataType = "simulated"; % options: "simulated" or "recorded"

if strcmp(dataType,"recorded")
    % Manually specify Mouse ID
    mouseLabel = inputdlg('Enter animal ID','User input');
    % select base directory from which to navigate
    baseDir = uigetdir('',"Select base directory for this animal.");
elseif strcmp(dataType,"simulated")
    mouseLabel = inputdlg('Enter region ID (CA1, CA3, or DG):','User input');
    % select base directory from which to navigate
    baseDir = uigetdir('',"Select base directory for simulated data.");
end

% load odor delivery timing
[file, path] = uigetfile(".mat","Select [IDxxx]_full_session_odor_sequence_matrix.mat",baseDir);
load(fullfile(path,file));

% load odorant identities
if strcmp(dataType,"recorded")
    [file, path] = uigetfile(".mat","Select .mat file containing PID data ([AK0xx]_D[x]_full_session_pid_data.mat.",path);
elseif strcmp(dataType,"simulated")
    [file, path] = uigetfile(".mat","Select .mat file containing PID data for one of the animals to retrieve odor names ([AK0xx]_D[x]_full_session_pid_data.mat.",path);
end
load(fullfile(path,file),"odorSetInfo");
thisOdorSet = odorSetInfo.setLayout;
if length(thisOdorSet)==1
    thisOdorSetInfo = odorSetInfo.("Set_" + thisOdorSet);
else
    error("Need to adapt the code to handle more than one sequentially presented odor set!")
end
odorIdentities = cellstr(thisOdorSetInfo.odorNames);

% load alignedUnitDataStruct variable
[file, path] = uigetfile(".mat","Select .mat file containing alignedUnitDataStruct variable for " + mouseLabel + ".",baseDir);
tic
disp("Loading aligned units data structure...")
load(fullfile(path,file),"alignedUnitDataStruct"); % note: took <3 mins
toc            

% get paths for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");

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

%% PART TWO: Group spikes by odor trial and save to .mat file

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

tic
disp("Saving spikes_grouped_by_odor_trial data structure to .mat file.")
save(baseOutputPath + "\" + mouseLabel + "" + "_spikes_grouped_by_odor_trial.mat","spikeRaster", "mouseLabel","timeBefore","timeDuring","timeAfter","sampFreq","nUnits","unitInfo","nOdors","nTrialsPerOdor","odorIdentities",'-v7.3');
toc

disp("Finished grouping spikes by odor trial and saving to file. PART TWO complete.")

disp("Done running script.")

%% NEW VERSION OF SCRIPT ENDS HERE. IF THE BELOW PLOTS ARE DESIRED, THEY 
% SHOULD BE BROKEN OUT INTO SEPARATE PLOTTING AND ANALYSIS FUNCTIONS AS WAS
% DONE WITH "plot_raw_spike_counts_before_vs_during_odor_delivery.m", 
% "compare_spike_counts_before_vs_during_with_WSR.m", 
% "plot_spike_rasters_for_all_odorant_trials.m", and
% "plot_PSTHs_for_all_odorants.m".


% savedirAbsoluteChange = baseOutputPath + "\" + "4 - absolute change in spike counts";
% savedirAbsoluteChangeBar = baseOutputPath + "\" + "5 - spike count bar graph";
% savedirPercentChange = baseOutputPath + "\" + "6 - percent change";
% savedirPercentChangeBar = baseOutputPath + "\" + "7 - percent change bar";
% 
% % make new folders if they do not already exist
% if ~exist(savedirAbsoluteChange,'dir')
%     mkdir(savedirAbsoluteChange);
% end
% if ~exist(savedirAbsoluteChangeBar,'dir')
%     mkdir(savedirAbsoluteChangeBar);
% end
% if ~exist(savedirPercentChange,'dir')
%     mkdir(savedirPercentChange);
% end
% if ~exist(savedirPercentChangeBar,'dir')
%     mkdir(savedirPercentChangeBar);
% end
% savedirStatisticalTests = baseOutputPath + "\" + "8 - statistical tests";
% if ~exist(savedirStatisticalTests,'dir')
%     mkdir(savedirStatisticalTests);
% end

% %% PART THREE: Compute spike counts before and during odor delivery
% 
% disp("Computing spike counts before and during odor delivery.")
% 
% tic
% 
% % Preallocate memory for new data structure
% beforeCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity
% duringCount = nan(nOdors, nTrialsPerOdor, nUnits); % Create empty 3D matrix for storing total count of spikes per trial, grouped by odorant identity
% 
% startIndex = pointsBefore-pointsDuring; % start counting spikes from 2 seconds in to trial, 
% onsetIndex = startIndex + pointsDuring;
% endIndex = onsetIndex + pointsDuring;
% 
% for iUnit = 1:nUnits
% 
%     disp("Processing unit #" + num2str(iUnit))
% 
%     for iOdorant = 1:nOdors
% 
%         for iTrial = 1:nTrialsPerOdor
%             beforeCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,startIndex:(onsetIndex-1)));
%             duringCount(iOdorant, iTrial, iUnit) = sum(spikeRaster(iOdorant,iTrial,iUnit,onsetIndex:endIndex));
%         end
% 
%     end
% end
% 
% disp("Finished computing spike counts. PART THREE complete.")
% 
% %% PART FOUR: Plotting
% 
% nRows = 4;
% 
% 
% %% PART 4.4: Plot absolute change in spike count during odor delivery
% 
% disp("Plotting absolute change in spike count upon odor delivery...")
% 
% clear duringMetric
% 
% absoluteChangeMean = nan(nUnits,nOdors);
% absoluteChangeStd = nan(nUnits,nOdors);
% 
% signTestPValues = nan(nUnits,nOdors);
% 
% for iUnit = 1:nUnits
% 
%     disp("Processing unit #" + num2str(iUnit))
% 
%     thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
%     thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
%     f = figure('visible','off');
%     sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
%     set(gcf,'Position',[550 50 700 1300])
% 
%     minY = 0;
%     maxY = 0;
%     for iOdorant = 1:nOdors
% 
%         subplot(nRows,nOdors/nRows,iOdorant)
% 
%         countDiff = (duringCount(iOdorant, :, iUnit)-beforeCount(iOdorant, :, iUnit))./timeDuring; % in spikes/sec
%         x = [1 2];
% 
%         for iTrial = 1:nTrialsPerOdor
%             y = [0 countDiff(1,iTrial)];
%             plot(x,y,'-k.')
%             hold on
%         end
% 
%         % get bounds for plotting
%         maxY = max(countDiff(isfinite(countDiff)));
%         minY = min(countDiff(isfinite(countDiff)));
% 
%         % Calculate statistical characteristics of the data
%         absoluteChangeMean(iUnit,iOdorant) = mean(countDiff(isfinite(countDiff)));
%         absoluteChangeStd(iUnit,iOdorant) = std(countDiff(isfinite(countDiff)));
%         % Perform statistical test to evaluate whether this unit's responds
%         % to this odorant:
%         % Sign Test -- evaluates whether the median of the paired sample
%         % differences is zero
%         signTestPValues(iUnit,iOdorant) = signtest(countDiff);
% 
%         % Set plotting parameters
%         xlim([0.5 2.5])
%         if minY==maxY
%             ylim([-10 10])
%         else
%             ylim([minY*1.2 maxY*1.2])
%         end
%         xlabel({'time period relative to', 'odorant delivery'})
%         ylabel('absolute change in spike count (spikes/sec)')
%         xticks([1 2])
%         xticklabels({'before','during'})
%         yline(0,'--')
%         title({odorIdentities{iOdorant}, "sign test p-value: " + sprintf('%.3f',signTestPValues(iUnit,iOdorant))})
%         hold off
% 
%     end
% 
%     if saveImages == true
%         saveas(f, savedirAbsoluteChange + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_absolutechange.png")
%     end
% end
% 
% disp("Finished plotting absolute change in spike counts.")
% 
% %% PART 4.5: Plot bar graph of absolute change in spike count before and after delivery
% 
% if saveImages == true
%     for iUnit = 1:nUnits
%         disp("Processing unit #" + num2str(iUnit))
% 
%         thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;
%         thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
%         f = figure('visible','off');
%         sgtitle("Mouse " + mouseLabel + " - sorted & curated - Unit #" + num2str(iUnit) + ", Ch#" + thisContactNum + ", " + thisAnatomicalRegion)
%         set(gcf,'Position',[550 550 700 500])
% 
%         x = 1:nOdors;
%         bar(x,absoluteChangeMean(iUnit,:))                
%         hold on
%         er = errorbar(x,absoluteChangeMean(iUnit,:),absoluteChangeStd(iUnit,:));    
%         er.Color = [0 0 0];                            
%         er.LineStyle = 'none';  
%         xticks(x)
%         xticklabels(odorIdentities)
%         xlabel('odorant')
%         ylabel({'absolute change in spike count','(error bars 2SD in length)'})
%         hold off
% 
%         saveas(f, savedirAbsoluteChangeBar + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_absolutechange_bargraph-mean-std.png")
% 
%     end
% 
%     disp("Finished plotting bar graph of absolute change in spike counts.")
% end
% 
% %% PART 4.6: Plot percent change in spike count before and during odor delivery
% 
% disp("Plotting percent change in spike count before vs. during odor delivery...")
% 
% clear duringMetric
% 
% meanPercentChange = nan(nUnits,nOdors);
% 
% for iUnit = 1:nUnits
% 
%     disp("Processing unit #" + num2str(iUnit))
% 
%     thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
%     thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
%     f = figure('visible','off');
%     sgtitle({"Mouse " + mouseLabel, "sorted & curated", "Unit #" + num2str(iUnit), "Ch#" + thisContactNum + ", " + thisAnatomicalRegion})
%     set(gcf,'Position',[550 50 700 1300])
% 
% 
%     minY = 0;
%     maxY = 0;
%     for iOdorant = 1:nOdors
% 
%         subplot(nRows,nOdors/nRows,iOdorant)
% 
%         duringMetric = (duringCount(iOdorant, :, iUnit)-beforeCount(iOdorant, :, iUnit))./beforeCount(iOdorant, :, iUnit)*100;
%         x = [1 2];
% 
%         for iTrial = 1:nTrialsPerOdor            
%             y = [0 duringMetric(1,iTrial)];
%             plot(x,y,'-k.')
%             hold on
%         end
% 
%         maxY = max(duringMetric(isfinite(duringMetric)));
%         minY = min(duringMetric(isfinite(duringMetric)));
%         xlim([0.5 2.5])
%         if isempty(minY)
%             ylim([-1 1])
%         elseif minY == maxY
%             ylim([minY-1 maxY+1])
%         else
%             ylim([minY*1.2 maxY*1.2])
%         end
%         xlabel({'time period relative to', 'odorant delivery'})
%         ylabel('% change in spike count')
%         xticks([1 2])
%         xticklabels({'before','during'})
%         yline(0,'--')
%         title(odorIdentities{iOdorant})
%         hold off
% 
%         meanPercentChange(iUnit,iOdorant) = mean(duringMetric(isfinite(duringMetric)));
%         percentChangeStd(iUnit,iOdorant) = std(duringMetric(isfinite(duringMetric)));
% 
%     end
% 
%     if saveImages == true
%         saveas(f, savedirPercentChange + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_percentchange.png")
%     end
% end
% 
% disp("Finished plotting percent change in spike counts.")
% 
% %% PART 4.7: Plot bar graph of percent change in spike count before and after delivery
% 
% if saveImages == true
%     disp("Plotting bar graph of percent change in spike count...")
% 
%     for iUnit = 1:nUnits
% 
%         disp("Processing unit #" + num2str(iUnit))
% 
%         thisContactNum = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.contactNumb;  %getContactNumber(iUnit);
%         thisAnatomicalRegion = unitInfo.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
%         f = figure('visible','off');
%         sgtitle("Mouse " + mouseLabel + " - sorted & curated - Unit #" + num2str(iUnit) + ", Ch#" + thisContactNum + ", " + thisAnatomicalRegion)
%         set(gcf,'Position',[550 550 700 500])
% 
%         x = 1:nOdors;
%         bar(x,meanPercentChange(iUnit,:))                
%         hold on
%         er = errorbar(x,meanPercentChange(iUnit,:),percentChangeStd(iUnit,:));    
%         er.Color = [0 0 0];                            
%         er.LineStyle = 'none';  
%         xticks(x)
%         xticklabels(odorIdentities)
%         xlabel('odorant')
%         ylabel({'percent change in spike count','(error bars 2SD in length)'})
%         hold off
% 
%         saveas(f, savedirPercentChangeBar + "\" + mouseLabel + "_unit-" + num2str(iUnit, "%.3d") + "_beforeduring_percentchange_bargraph-mean-std.png")
% 
%     end
% 
%     disp("Finished plotting bar graph of percent change in spike count.")
% end
% 
% 


