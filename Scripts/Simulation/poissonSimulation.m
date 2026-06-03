%% Simulating odor delivery experiment assuming Poisson neurons
% Modified from: Intro to Computational Neuroscience: Assignment 2, Computer Problem 1
% Anna Kolstad

% First created: March 5, 2026
% Last revised: May 26, 2026

%% Check in my data: 

% what is the mean firing rate distribution?
% Technically, for the purpose of this simulation, should determine mean
% firing rate based only on the intertrial intervals

% does the mean firing rate actually equal the FR variance? 

%% Set experimental parameters

clc
clear vars

% Define structure of experiment
nOdorants = 12;
nTrialsPerOdor = 12;
nTrials = nOdorants*nTrialsPerOdor;
odorPresentationDuration = 3; % seconds
intertrialInterval = 15; % seconds
sampleFreq = 30000; % Hz
minPerFile = 7;
nFiles = 7;
recordingDuration = nFiles * minPerFile * 60; % total recording duration in seconds
experimentDuration = nTrials*(odorPresentationDuration + intertrialInterval); % (seconds) total duration of experiment trials
paddingDuration = recordingDuration - experimentDuration; % (seconds) total duration of extra recording time included in analysis
nSamples = recordingDuration * sampleFreq; % total number of samples in recording

% LOAD IN DATA FROM EMPIRICAL RECORDING, including for each neuron:
% anatomic location
% anatomic abbreviation
% mean firing rate
% RENAME the data structure to empiricalUnitDataStruct

% USER INPUT (1): Use UI to select file containing information about
% units recorded in experiment (from a given brain region)
[file, pathMice] = uigetfile('*.mat','Select CA1UnitData.mat file');
load(fullfile(pathMice,file),"CA1UnitData","totalCA1Units");

empiricalUnitDataStruct = CA1UnitData;

% get empirical statistics of neural firing (empirically determined)
nUnits = totalCA1Units;

% calculate mean firing rate for each unit
% NOTE: IDEALLY THIS SHOULD BE OBTAINED FROM THE MEAN ITI SPIKE RATE, NOT
% THE OVERALL SPIKE RATE. IN THE CURRENT IMPLEMENTATION IT IS STILL
% DETERMINED FROM THE OVERALL SPIKE RATE.
meanFiringRates = nan(nUnits,1);
for iUnit = 1:nUnits
    nSpikes = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSpikes;
    durationSamples = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSamples;
    durationSeconds = durationSamples./sampleFreq;
    meanFiringRates(iUnit,1) = nSpikes/durationSeconds; % (Hz) 
end

refractoryPeriodMillisec = 3; % (milliseconds)
k = 2; 


% create data structure for unit activity
alignedUnitDataStruct = struct();
for iUnit = 1:nUnits
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSamples = nSamples;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSpikes = nan; % populate later once spike train is generated
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).qualityMetrics = table; % this will be a 1x4 table with the column headings "ISIViolations", "NumbSpikes","SpikeRate","SNR". Note that in my experiments, I did not use either the NumbSpikes filter or the SNR filter, so these characteristic values are not computed for the unit.
end

%% Confirm that each simulation runs as expected
% Simulate a short spike period without odor presentation 
% Assess fano factor

models = ["Homogenous Poisson", "Poisson with Refractory Period", "Gamma Renewal k = 2", "gamma with refractory period"];

useModel = models(1);

for iUnit = 1:nUnits
    disp("Simulating firing of unit #" + iUnit + "...")

    tic
    % Homogeneous Poisson Simulation
    if strcmp(useModel,models(1))
        spikes = getspiketrainhomogeneouspoisson(meanFiringRates(iUnit,1), sampleFreq, recordingDuration); % get binary spike train
        [~, spikeIndices] = find(spikes==1); % get spike times (note: time is in units of sample points)    
        modelName = models(1);
    % Poisson Simulation with refractory period
    elseif strcmp(useModel, models(2))
        spikes = getspiketrainpoissonrefractoryperiod(meanFiringRates(iUnit,1), sampleFreq, recordingDuration, refractoryPeriodMillisec);
        [~, spikeIndices] = find(spikes==1); % get spike times (note: time is in units of sample points)
        modelName = models(2);
    % Gamma renewal process with k = 2
    elseif strcmp(useModel, models(3))
        spikes = getspiketraingammaprocess(meanFiringRates(iUnit,1), k, sampleFreq, recordingDuration, refractoryPeriodMillisec);
        [~, spikeIndices] = find(spikes==1); % get spike times (note: time is in units of sample points)
        modelName = models(3);
    end
    
    % Remove any spikes that occur in the first or last second of the recording
    % (since this is how the spike indices are defined in processphyunitdata.m)
    trimmedSpikeIndices = spikeIndices(spikeIndices > sampleFreq & spikeIndices < (nSamples-sampleFreq));
    nSpikes = length(trimmedSpikeIndices);

    % Compute the ISI histogram
    binWidth = 1; % [milliseconds] chosen to match the hard-coded value used by processphyunitdata.m
    [isiCounts, isiBinEdges] = computeISIhistogram(trimmedSpikeIndices, binWidth, sampleFreq);

    % NEED TO FIX THE BUG IN THE COMPUTEACGHISTOGRAM FUNCTION IN THE FIRST
    % IF STATEMENT (SEE SCREENSHOT ON PHONE)
    % Compute the ACG histogram
    binWidth = 1; % [milliseconds] chosen to match the hard-coded value used by processphyunitdata.m
    maxLag = 25; % [milliseconds] the max time lag (in ms) to use in 
                    % the negative and positive direction when 
                    % computing the histogram
    [acgCounts, acgBinEdges] = computeACGhistogram(trimmedSpikeIndices, binWidth, maxLag, sampleFreq);

    % Add the ISI, ACG, and spike rate data to the property
    summaryDataProp = struct();
    summaryDataProp.isiHistCArr = {isiCounts; isiBinEdges};
    summaryDataProp.acgHistCArr = {acgCounts; acgBinEdges};

    % Update the SUMMARY DATA property
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData = summaryDataProp;



    
    % Calculate the spike rate across the recording for this unit
    spikeRate = nSpikes/recordingDuration; % [Hz] average spike rate across entire recording

    % Get quality metric values for this unit
    % Create matrix (1 unit x nMetrics) to store metric values for this unit 
    % (populate with NaNs if not calculated due to not enforcing)
    unitMetricValsMat = nan(1,4);
    % ============================
    % Check for ISI violation
    % ============================ 
    % Extract the ISI data
    tempISICounts = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{1};
    tempISIEdges = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{2};

    % Compute the ISI violation ratio from the histogram w/ binsize
    % of 1ms
    isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
    violRatio = sum(isiTempHist.Values(1:isiDurationCutoff));
    
    % Set and store whether metric passes threshold
    unitMetricValsMat(1,1) = violRatio*100;
    
    unitMetricValsMat(1,2) = nan; % number of spikes not used in my analysis
    unitMetricValsMat(iUnit,3) = spikeRate; % spike rate across the recording
    unitMetricValsMat(1,4) = nan; % snr value not used in my analysis

    % Save spike train to data structure
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSpikes = nSpikes; % total number of simulated spikes
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).qualityMetrics = array2table(unitMetricValsMat(1,:), 'VariableNames', {'ISIViolations','NumbSpikes','SpikeRate','SNR'});; % this is a 1x4 table with the column headings "ISIViolations", "NumbSpikes","SpikeRate","SNR". Note that in my experiments, I did not use either the NumbSpikes filter or the SNR filter, so these characteristic values are not computed for the unit.

end


toc
%% Plot ISI and ACG histograms (in same way as data processing, per
% processphyunitdata.m)

% Compute the ISI histogram
[isiCounts, isiBinEdges] = computeISIhistogram(trimmedSpikeIndices, 1, sampleFreq);
tempISICounts = isiCounts;
tempISIEdges = isiBinEdges;


    


% Compute the ACG histogram
[acgCounts, acgBinEdges] = computeACGhistogram(trimmedSpikeIndices, 1, 25, sampleFreq);
tempACGCounts = acgCounts;
tempACGEdges = acgBinEdges;

% Compute the spike rate using a 1-second long causal convolution signal
tempSpikeIndices = spikeIndices;
tempSpikeRate = histcounts(tempSpikeIndices, 'BinWidth', sampleFreq, 'BinLimits', [0,nSamples]);

% Compute the Fano Factor by reshaping entire experiment into 1 second bins
binnedSpikes = sum(reshape(spikes,sampleFreq,[])).';
maxRate = max(binnedSpikes); % spikes per second
nBins = size(binnedSpikes,1);
fanoFactor = var(binnedSpikes)/mean(binnedSpikes);
            
%% Initialize the figure
%unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3902    0.5616    0.3614    0.3669], 'Visible', 'on');
unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3792    0.2989    0.3724    0.5725], 'Visible', 'on');
probeID = "NeuroNexusA4x16";
nUnits = 1;
iUnit = 1;
% Create a set of different colors to use for visual distinction of units
colorMatrix = createpastelcolormatrix(nUnits, 1, 0);
if strcmp(modelName,models(1))
    sgtitle({modelName, "\lambda = " + meanFiringRate + "Hz; " + experimentDuration/60 + "min simulation, no odors"})
elseif strcmp(modelName,models(2))
    sgtitle({modelName, "\lambda = " + meanFiringRate + " Hz, RP = " + refractoryPeriodMillisec + " ms", experimentDuration/60 + "min simulation, no odors"})
end
% ===========================
% Plot the spike count distribution and print fano factor
% ===========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,[1,4])
    subplot(4,2,[1,3])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,2)
end
tempH = histogram(binnedSpikes);
tempH.FaceColor = colorMatrix(iUnit,:);
hold on
xlabel('spike count')
ylabel('number of 1 second bins')
title({"Fano factor: " + fanoFactor})
xValues = 0:maxRate;
poissonDist = poisspdf(xValues,meanFiringRate);
poissonSum = poisscdf(maxRate,meanFiringRate);
plot(xValues,poissonDist*poissonSum*nBins,'LineWidth',2)
legend("simulated","Poisson PDF")
hold off

% ===========================
% Plot the ACG histogram plot
% ===========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,2)
    subplot(4,2,2)
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,2)
end
tempH = histogram('BinCounts', tempACGCounts, 'BinEdges', tempACGEdges, 'Normalization', 'probability');
tempH.FaceColor = colorMatrix(iUnit,:);
hold on
plot([-3,-3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
plot([3,3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
violRatio = sum(tempH.Values(tempH.BinEdges >= -3 & tempH.BinEdges <= 3))/sum(tempH.Values);
xlabel('Time lag (ms)')
ylabel('Probability')
title("ACG violations: " + num2str(violRatio*100) + "%")
% =========================
% Plot the ISI histogram plot
% ============================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,5)
    subplot(4,2,4)
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,6)
end
isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
isiTempHist.FaceColor = colorMatrix(iUnit,:);
hold on
plot([3,3],[0,max(isiTempHist.Values)+0.005], 'k--', 'LineWidth', 1)
xlim([0,50])
violRatio = sum(isiTempHist.Values(1:3));
xlabel('Interspike interval (ms)')
ylabel('Probability')
title("ISI violations: " + num2str(violRatio*100) + "%")
% =========================
% Plot the first N seconds of the raster plot
% =========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,5)
    subplot(4,2,[5,6])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,6)
end
nSeconds = 5;
firstNSecondSpikes = spikeIndices(spikeIndices < nSeconds*sampleFreq);
scatter(firstNSecondSpikes/sampleFreq,1,'|k','LineWidth',2)
title("First " + nSeconds + " second(s) of raster plot")
xlabel('Time (s)')
ylabel('spike (yes/no)')
ylim([0.9 1.1])
xlim([0 nSeconds])
yticklabels([])
yticks(1)
% =========================
% Plot the Spike Rate plot
% =========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,[7,8])
    subplot(4,2,[7,8])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,[9,10])
end
plot((1:numel(tempSpikeRate)), tempSpikeRate, 'k')
xlabel('Time (s)');
ylabel('Spike Rate (Hz)');
xlim([0 experimentDuration])



%% Define tuning curve properties

% Assume the neuron is selective for 1 out of the 11 odors (odorant #3)
selectiveForOdorant = 3;
effectSize = 1.5; % multiplicative factor on mean firing rate % SHOULD ALSO SIMULATE SUPPRESSIVE RESPONSES! e.g. effectSize = 0.8;

% Create tuning curve (mean spike rate as a function of odorant) 
expectedSpikeRate = ones(1,nOdorants)*meanFiringRate;
expectedSpikeRate(1,selectiveForOdorant) = meanFiringRate*effectSize;

% % Normalize max firing rate -- not sure what the goal of this is? to
% % compare multiple neurons? 
% maxFR = 50; % Hz, ** Determine empirically from my dataset!!
% peakValue = max(spikeRate);
% spikeRate = spikeRate*(maxFR/peakValue);

%% Simulate experiment

odorSequence = getRandomOdorSequence(nOdorants, nTrialsPerOdor);

tic
spikes = []; 
for iTrial = 1:nTrials
    clear spikesIntertrial spikesOdorPresentation
   
    disp("Simulating trial # " + iTrial)

    % simulate intertrial interval
    if strcmp(useModel, models(1)) 
        spikesIntertrial = getspiketrainhomogeneouspoisson(meanFiringRate, sampleFreq, intertrialInterval);
    elseif strcmp(useModel, models(2))
        spikesIntertrial = getspiketrainpoissonrefractoryperiod(meanFiringRate, sampleFreq, intertrialInterval, refractoryPeriodMillisec);
    end

    % simulate odor delivery
    thisOdor = odorSequence(iTrial);
    if strcmp(useModel, models(1)) 
        spikesOdorPresentation = getspiketrainhomogeneouspoisson(expectedSpikeRate(thisOdor), sampleFreq, odorPresentationDuration);
    elseif strcmp(useModel, models(2))
        spikesOdorPresentation = getspiketrainpoissonrefractoryperiod(expectedSpikeRate(thisOdor), sampleFreq, odorPresentationDuration, refractoryPeriodMillisec);
    end
  
    % combine spike rate across entire trial
    spikes = [spikes spikesIntertrial spikesOdorPresentation];
end
toc


%% Calculate ISI and ACG histograms (in same way as data processing, per
% processphyunitdata.m)

nSamples = experimentDuration*sampleFreq;
trimmedSpikeIndices = spikeIndices(spikeIndices > sampleFreq & spikeIndices < (nSamples-sampleFreq));

% Compute the ISI histogram
[isiCounts, isiBinEdges] = computeISIhistogram(trimmedSpikeIndices, 1, sampleFreq);
tempISICounts = isiCounts;
tempISIEdges = isiBinEdges;

% Compute the ACG histogram
[acgCounts, acgBinEdges] = computeACGhistogram(trimmedSpikeIndices, 1, 25, sampleFreq);
tempACGCounts = acgCounts;
tempACGEdges = acgBinEdges;

% Compute the spike rate using a 1-second long causal convolution signal
tempSpikeIndices = spikeIndices;
tempSpikeRate = histcounts(tempSpikeIndices, 'BinWidth', sampleFreq, 'BinLimits', [0,nSamples]);

% Compute the Fano Factor by reshaping entire experiment into 1 second bins
binnedSpikes = sum(reshape(spikes,sampleFreq,[])).';
maxRate = max(binnedSpikes); % spikes per second
nBins = size(binnedSpikes,1);
fanoFactor = var(binnedSpikes)/mean(binnedSpikes);
            
%% Initialize the figure
%unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3902    0.5616    0.3614    0.3669], 'Visible', 'on');
unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3792    0.2989    0.3724    0.5725], 'Visible', 'on');
probeID = "NeuroNexusA4x16";
nUnits = 1;
iUnit = 1;
% Create a set of different colors to use for visual distinction of units
colorMatrix = createpastelcolormatrix(nUnits, 1, 0);
if strcmp(modelName,models(1))
    sgtitle({modelName, "\lambda = " + meanFiringRate + "Hz; " + experimentDuration/60 + "min simulation, no odors"})
elseif strcmp(modelName,models(2))
    sgtitle({modelName, "\lambda = " + meanFiringRate + " Hz, RP = " + refractoryPeriodMillisec + " ms", experimentDuration/60 + "min simulation, no odors"})
end
% ===========================
% Plot the spike count distribution and print fano factor
% ===========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,[1,4])
    subplot(4,2,[1,3])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,2)
end
tempH = histogram(binnedSpikes);
tempH.FaceColor = colorMatrix(iUnit,:);
hold on
xlabel('spike count')
ylabel('number of 1 second bins')
title({"Fano factor: " + fanoFactor})
xValues = 0:maxRate;
poissonDist = poisspdf(xValues,meanFiringRate);
poissonSum = poisscdf(maxRate,meanFiringRate);
plot(xValues,poissonDist*poissonSum*nBins,'LineWidth',2)
legend("simulated","Poisson PDF")
hold off

% ===========================
% Plot the ACG histogram plot
% ===========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,2)
    subplot(4,2,2)
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,2)
end
tempH = histogram('BinCounts', tempACGCounts, 'BinEdges', tempACGEdges, 'Normalization', 'probability');
tempH.FaceColor = colorMatrix(iUnit,:);
hold on
plot([-3,-3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
plot([3,3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
violRatio = sum(tempH.Values(tempH.BinEdges >= -3 & tempH.BinEdges <= 3))/sum(tempH.Values);
xlabel('Time lag (ms)')
ylabel('Probability')
title("ACG violations: " + num2str(violRatio*100) + "%")
% =========================
% Plot the ISI histogram plot
% ============================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,5)
    subplot(4,2,4)
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,6)
end
isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
isiTempHist.FaceColor = colorMatrix(iUnit,:);
hold on
plot([3,3],[0,max(isiTempHist.Values)+0.005], 'k--', 'LineWidth', 1)
xlim([0,50])
violRatio = sum(isiTempHist.Values(1:3));
xlabel('Interspike interval (ms)')
ylabel('Probability')
title("ISI violations: " + num2str(violRatio*100) + "%")
% =========================
% Plot the first N seconds of the raster plot
% =========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,5)
    subplot(4,2,[5,6])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,6)
end
nSeconds = 5;
firstNSecondSpikes = spikeIndices(spikeIndices < nSeconds*sampleFreq);
scatter(firstNSecondSpikes/sampleFreq,1,'|k','LineWidth',2)
title("First " + nSeconds + " second(s) of raster plot")
xlabel('Time (s)')
ylabel('spike (yes/no)')
ylim([0.9 1.1])
xlim([0 nSeconds])
yticklabels([])
yticks(1)
% =========================
% Plot the Spike Rate plot
% =========================
if strcmp(probeID, "NeuroNexusA4x16")
    %subplot(3,3,[7,8])
    subplot(4,2,[7,8])
elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
    subplot(3,4,[9,10])
end
plot((1:numel(tempSpikeRate)), tempSpikeRate, 'k')
xlabel('Time (s)');
ylabel('Spike Rate (Hz)');
xlim([0 experimentDuration])

%% FORMAT DATA IN THE SAME WAY AS EXPERIMENTAL DATA

% experimental spikes are currently stored as: 4D matrix
% maybe it will actually be better to store them as cell arrays with the
% spike times for each spike (and subtract the start time) --> then I can
% process all the animals together, perhaps




%% FUNCTION DEFINITONS

% Homogenous Poisson Simulation: Draw from Exponential ISI
function spikes = getspiketrainhomogeneouspoisson(meanFiringRateHz, sampleRateHz, durationSec)
% GETPOISSONSPIKETRAIN is a local function which produces a homogenous 
% poisson spike train. 
% 
% Parameters:
%   meanFiringRateHz -   
%   sampleRateHz - 
%   durationSec - whole number - total amount of time to simulate (in seconds)
% 
% The function returns a vector of time bins, where the value of each bin
% is 0 when the neuron does not spike and 1 when the neuron spikes. 

    % calculate mean ISI needed to acheive target spike rate
    meanISI = 1/meanFiringRateHz; % (seconds) 1 second / (10 spikes/second) = 0.1 seconds/spike = 0.1 second ISI

    % simulate spike train
    exponentialSpikeTimes = exprnd(meanISI); % (seconds) spike times generated from an exponential distribution
    nSpike = 1;
    while exponentialSpikeTimes(end) < durationSec
        nextISI = exprnd(meanISI);
        exponentialSpikeTimes = [exponentialSpikeTimes (exponentialSpikeTimes(end) + nextISI)]; % (get next ISI
        nSpike = nSpike + 1;
    end
    
    % convert the spike times into a spike train of 0's and 1's
    spikes = convertspiketimestospiketrain(exponentialSpikeTimes, sampleRateHz, durationSec);

end

% Homogenous Poisson simulation with refractory period
function spikes = getspiketrainpoissonrefractoryperiod(meanFiringRateHz, sampleRateHz, durationSec, refractoryPeriodMillisec)
% GETPOISSONSPIKETRAIN is a local function which produces a homogenous 
% poisson spike train with a refractory period. 
% 
% Parameters:
%   meanFiringRateHz -   
%   sampleRateHz - 
%   durationSec - whole number - total amount of time to simulate (in seconds)
% 
% The function returns a vector of time bins, where the value of each bin
% is 0 when the neuron does not spike and 1 when the neuron spikes. 

    % calculate mean ISI needed to acheive target spike rate
    meanISI = 1/meanFiringRateHz; % (seconds) 1 second / (10 spikes/second) = 0.1 seconds/spike = 0.1 second ISI
    
    % convert the refractory period into seconds
    refractoryPeriodSec = refractoryPeriodMillisec/1000;

    % simulate spike train
    exponentialSpikeTimes = exprnd(meanISI); % (seconds) spike times generated from an exponential distribution
    nSpike = 1;
    while exponentialSpikeTimes(end) < durationSec
        nextISI = exprnd(meanISI);
        while nextISI < refractoryPeriodSec
            nextISI = exprnd(meanISI);
        end
        exponentialSpikeTimes = [exponentialSpikeTimes (exponentialSpikeTimes(end) + nextISI)]; % (get next ISI)
        nSpike = nSpike + 1;
    end
    
    % convert the spike times into a spike train of 0's and 1's
    spikes = convertspiketimestospiketrain(exponentialSpikeTimes, sampleRateHz, durationSec);

end

% Gamma spike train
function spikes = getspiketraingammaprocess(meanFiringRateHz, k, sampleRateHz, durationSec, refractoryPeriodMillisec)
% GETSPIKETRAINGAMMAPROCESS is a local function which produces a gamma 
% renewal spike train. k is the shape parameter which controls the
% regularity of the spiking. Theta is the time scale parameter which sets
% the average spacing between spikes (i.e. the ITI). 
%   mean firing rate = 1/(k*theta)
%   mean ISI = k*theta
%   variance of ISI = k*theta^2
%   coefficient of variation (CV) = 1/sqrt(k)
%   Fano factor = CV^2 = 1/k
% 
% Parameters of gamma function:
%   k - shape parameter - 
%       when k = 1, this is a poisson process.
%       when k > 1, this produces more regular firing
%       when k < 1, this produces bursting
%   theta - average interval length; controls the average ISI
%   sampleRateHz - 
%   durationSec - whole number - total amount of time to simulate (in seconds)
% 
% The function returns a vector of time bins, where the value of each bin
% is 0 when the neuron does not spike and 1 when the neuron spikes. 

    % calculate theta
    theta = 1/(meanFiringRateHz*k);

    % calculate mean ISI needed to acheive target spike rate
    meanISI = 1/meanFiringRateHz; % (seconds) 1 second / (10 spikes/second) = 0.1 seconds/spike = 0.1 second ISI
    
    % convert the refractory period into seconds
    refractoryPeriodSec = refractoryPeriodMillisec/1000;

    % simulate spike train
    exponentialSpikeTimes = exprnd(meanISI); % (seconds) spike times generated from an exponential distribution
    nSpike = 1;
    while exponentialSpikeTimes(end) < durationSec
        nextISI = exprnd(meanISI);
        while nextISI < refractoryPeriodSec
            nextISI = exprnd(meanISI);
        end
        exponentialSpikeTimes = [exponentialSpikeTimes (exponentialSpikeTimes(end) + nextISI)]; % (get next ISI)
        nSpike = nSpike + 1;
    end
    
    % convert the spike times into a spike train of 0's and 1's
    spikes = convertspiketimestospiketrain(exponentialSpikeTimes, sampleRateHz, durationSec);

end

function spikes = convertspiketimestospiketrain(spikeTimes, sampleRateHz, durationSec)
% CONVERTSPIKETIMESTOSPIKETRAIN is a local function that converts a set of
% spike times into a binary spike train of 0's and 1's

    binsPerSecond = sampleRateHz; % (bins/second)
    nElements = durationSec*binsPerSecond;
    
    spikes = zeros(1,nElements);
    temp = round(spikeTimes*binsPerSecond); % seconds * bins/second = bin index
    spikes(temp) = 1;
    spikes = spikes(1:nElements);
end

function odorSequence = getRandomOdorSequence(nOdors, nTrials)
% GETRANDOMODORSEQUENCE is a local function which produces a sequence of 
% simulated odorant stimuli.   
    odorSequence = repmat(1:nOdors, 1, nTrials);
    odorSequence = odorSequence(randperm(nOdors*nTrials));
end