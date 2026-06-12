%% Simulating odor delivery experiment assuming Poisson neurons

% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Citations: This script was adapted from my code written for Intro to 
% Computational Neuroscience Course Assignment 2, Computer Problem 1 and 
% processphyunitdata.m (Version 1.1) from NCCLAB Git repository. 
% Script first created: March 5, 2026
% Script last updated: June 11, 2026
% Version 2.0

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
paddingStart = 60; % (seconds) out of the total duration of extra recording time included in the simulation, allocate 1 minute of it to the start (i.e. first odor presentation happens at 1 minute)
nSamples = recordingDuration * sampleFreq; % total number of samples in recording

% The following section of code loads in data from the empirical recordings, which 
% includes for each neuron:
% - anatomic location
% - anatomic abbreviation
% - mean firing rate
% and renames the data structure to empiricalUnitDataStruct

brainRegion = "CA1"; % "CA1", "CA3", or "DG"

% USER INPUT (1): Use UI to select file containing information about
% units recorded in experiment (from a given brain region)
[file, pathMice] = uigetfile('*.mat','Select '+ brainRegion + 'UnitData.mat file');
load(fullfile(pathMice,file),(brainRegion+"UnitData"),("total"+brainRegion+"Units"));

if strcmp(brainRegion,"CA1")
    empiricalUnitDataStruct = CA1UnitData;
    % get statistics of neural firing (match to empirical data)
    nUnits = totalCA1Units;
elseif strcmp(brainRegion,"CA3")
    empiricalUnitDataStruct = DGUnitData;
    % get statistics of neural firing (match to empirical data)
    nUnits = totalDGUnits;
elseif strcmp(brainRegion,"DG")
    empiricalUnitDataStruct = DGUnitData;
    % get statistics of neural firing (match to empirical data)
    nUnits = totalDGUnits;
end

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

% Set additional parameters for refractory period simulation
refractoryPeriodMillisec = 3; % (milliseconds)
% Set additional parameters for gamma renewal process simulation
k = 2; 

% Extract the quality metric thresholds from the empirical data
isiViolPercentAllowed = empiricalUnitDataStruct.qualityMetricSettings.ISI.minViol;

% USER INPUT (2): Use UI to select directory in which to save the simulated 
% data structure
savePath = uigetdir('','Select directory in which to save the simulated data structure:');

%% Run odor simulation

% Get odor sequence
% IDEA: RATHER THAN GENERATING A LOT OF NEURAL POPULATIONS, I CAN GENERATE 
% MANY ODOR SEQUENCES AND THEN COMPUTE STATISTICS OF A SINGLE SIMULATED
% NEURAL POPULATION AGAINST MANY DIFFERENT ODOR SEQUENCES (SINCE WE ARE
% MODELLING THE CASE IN WHICH TEHRE IS NO INTRINSIC RELATIONSHIP BETWEEN
% ODORS AND SPIKING ACTIVITY)
odorSequence = getRandomOdorSequence(nOdorants, nTrialsPerOdor);

%%

% Create a CA1_full_session_odor_sequence_matrix.mat variable
% variables are: odorSeqMat

% Create Odor Sequence Matrix
disp("Simulating odor data...")

odorSavePath = uigetdir(savePath, 'Select directory to save odor sequence...');

%% Generate odorSeqRawMat (?? NEED TO EXAMINE WHAT THE FORMAT OF THIS IS??)
% TO-DO
% PROBABLY INCLUDES A CODE FOR THE ODOR ID'S
% This is an Nx3 numeric matrix, where N is the number of odor stimuli that
% were presented
% --> Column 1: numeric odor label (1-12)
% --> Column 2: Delay in delivery (seconds) 
% --> Column 3: delivery duration (milliseconds) **NOTE: THE COLUMN ORDER IS
% INCORRECTLY LABELLED IN THE HEADER OF EXTRACTSINGLEDAYRHDDATA.M
odorSeqRawMat = [odorSequence', odorPresentationDuration*1000*ones(nTrials,1), intertrialInterval*ones(nTrials,1)];

% Generate odorSignal vector (value of 1 represents ON and 0 represents OFF)
singleOdorDelivery = [ones(1,odorPresentationDuration*sampleFreq) zeros(1,intertrialInterval*sampleFreq)];
allOdorDeliveries = repmat(singleOdorDelivery,1,nTrials);
odorSignal = [zeros(1,paddingStart*sampleFreq) allOdorDeliveries zeros(1,((paddingDuration-paddingStart)*sampleFreq))];

% DECIMATED SEQUENCE MATRIX
% Decimate the odor signal to get odor onsets in decimated frequency
decimateFactor = 10;
odorMetadata.parameters.decimate_factor = decimateFactor;
deciOdorSignal = odorSignal(1:decimateFactor:end);

% Compute the derivative of the odor signal to identify ON and OFF time
% points
diffOdorSignal = diff(deciOdorSignal);

% Index value + 1 gives the first sample where odor is on
toggleOdorOnIndex = find(diffOdorSignal == 1);

% Index value gives the last sample where odor is on
toggleOdorOffIndex = find(diffOdorSignal == -1);

% Add the ON & OFF time index information to the odor sequence matrix
deciOdorSeqMat = [odorSeqRawMat, (toggleOdorOnIndex+1)', toggleOdorOffIndex'];

% NON-DECIMATED SEQUENCE MATRIX
% Compute the derivative of the odor signal to identify ON and OFF time
% points
diffOdorSignal = diff(odorSignal);

% Index value + 1 gives the first sample where odor is on
toggleOdorOnIndex = find(diffOdorSignal == 1);

% Index value gives the last sample where odor is on
toggleOdorOffIndex = find(diffOdorSignal == -1);

% Add the ON & OFF time index information to the odor sequence matrix
odorSeqMat = [odorSeqRawMat, (toggleOdorOnIndex+1)', toggleOdorOffIndex'];

% Retrieve the parameters of the odor sequence
setSize = nTrials;
nSets = ceil((nTrials)/setSize);
nOdorsPerSet = 12;
for iSet = 1:nSets
    rows = (1:setSize) + (iSet-1)*setSize;
    odorOffset = (iSet - 1) * nOdorsPerSet;
    odorSeqMat(rows,1) = odorSeqMat(rows,1) + odorOffset;
    deciOdorSeqMat(rows,1) = deciOdorSeqMat(rows,1) + odorOffset;
end

% Save the odor sequence matrix data
sampFreq = sampleFreq;
fullOdorSavePath = odorSavePath + "simulation" + "_" + "_full_session_odor_sequence_matrix";
save(fullOdorSavePath, "odorSeqMat", "deciOdorSeqMat", "odorSignal", "sampFreq", '-v7.3')
disp('Odor Sequence Matrix computed.');
            

%% Run spiking simulation
% Simulate a short spike period without odor presentation OR assuming the
% units have no odor tuning

models = ["HomogenousPoisson", "PoissonWithRefractoryPeriod", "GammaRenewalKof2", "gamma with refractory period"];
isiDurationCutoff = empiricalUnitDataStruct.qualityMetricSettings.ISI.timeWindow;

useModel = models(2);

% for debugging only
useNUnits = 5;

% create data structure for unit activity
alignedUnitDataStruct = struct();
for iUnit = 1:useNUnits%nUnits
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSamples = nSamples;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSpikes = nan; % populate later once spike train is generated
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicLocation;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.anatomicAbbrev;
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData = ""; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).qualityMetrics = table; % this will be a 1x4 table with the column headings "ISIViolations", "NumbSpikes","SpikeRate","SNR". Note that in my experiments, I did not use either the NumbSpikes filter or the SNR filter, so these characteristic values are not computed for the unit.
end

tic
for iUnit = 1:useNUnits%nUnits
    disp("Simulating firing of unit #" + iUnit + "...")

    % Homogeneous Poisson Simulation
    if strcmp(useModel,models(1))
        disp("Running a homogenous poisson simulation...")
        spikes = getspiketrainhomogeneouspoisson(meanFiringRates(iUnit,1), sampleFreq, recordingDuration); % get binary spike train
        [~, spikeIndices] = find(spikes==1); % get spike times (note: time is in units of sample points)    
        modelName = models(1);
    % Poisson Simulation with refractory period
    elseif strcmp(useModel, models(2))
        disp("Running a poisson simulation with refractory period...")
        spikes = getspiketrainpoissonrefractoryperiod(meanFiringRates(iUnit,1), sampleFreq, recordingDuration, refractoryPeriodMillisec);
        [~, spikeIndices] = find(spikes==1); % get spike times (note: time is in units of sample points)
        modelName = models(2);
    % Gamma renewal process with k = 2
    elseif strcmp(useModel, models(3))
        disp("Running a gamma renewal process simulation with k = " + k)
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
    
    % Get quality metric values for this unit
    % Create matrix (1 unit x nMetrics) to store metric values for this unit 
    % (populate with NaNs if not calculated due to not enforcing)
    unitMetricValsMat = nan(1,4);

    % Calculate the spike rate across the recording for this unit
    spikeRate = nSpikes/recordingDuration; % [Hz] average spike rate across entire recording

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
    unitMetricValsMat(1,1) = violRatio*100; % [percent]
    unitMetricValsMat(1,2) = nan; % number of spikes not used in my analysis
    unitMetricValsMat(1,3) = spikeRate; % spike rate across the recording
    unitMetricValsMat(1,4) = nan; % snr value not used in my analysis

    % Save spike train to data structure
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSpikes = nSpikes; % total number of simulated spikes
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices = trimmedSpikeIndices; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData = summaryDataProp; % populate later once spike train is generated (based on the neuron its rate is modeled after)
    alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).qualityMetrics = array2table(unitMetricValsMat(1,:), 'VariableNames', {'ISIViolations','NumbSpikes','SpikeRate','SNR'}); % this is a 1x4 table with the column headings "ISIViolations", "NumbSpikes","SpikeRate","SNR". Note that in my experiments, I did not use either the NumbSpikes filter or the SNR filter, so these characteristic values are not computed for the unit. Note that I also did not filter out units that surpass the ISI violation threshold

end
toc

% Save the simulated unit data structure to file 
saveFileName = modelName + "_" + brainRegion + "_simulated_unit_data.mat";
save(fullfile(savePath, saveFileName), "alignedUnitDataStruct", '-v7.3');


% %% Plot summary figure for each unit (matching the format of the figures 
% % generated by processphyunitdata.m)
% 
% % For each unit create a unit summary figure showing:
% % (1) [Blank]
% % (2) The ACG Histogram (-/+ 3ms violation threshold)
% % (3) The ISI (+ 3ms violation threshold)
% % (4) The Firing Rate across the entire recording
% 
% % Create data extraction specific folders if they don't exist already
% savePath = uigetdir();
% if ~isfolder(savePath + "\unit_summary_figures")
%     mkdir(savePath + "\unit_summary_figures");
% end
% saveFigPath = savePath + "\unit_summary_figures";
% 
% % Create a set of different colors to use for visual distinction of units
% colorMatrix = createpastelcolormatrix(nUnits, 1, 0);
% 
% % Save the colorMatrix 
% save(fullfile(savePath, "unitColorMatrix.mat"), "colorMatrix");
% 
% for iUnit = 1:nUnits
% 
%     % Extract the ACG data
%     tempACGCounts = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{1};
%     tempACGEdges = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{2};
% 
%     % Extract the ISI data
%     tempISICounts = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{1};
%     tempISIEdges = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{2};
% 
%     % Extract the Spiking data
%     tempSpikeIndices = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
% 
%     % Compute the spike rate using a 1-second long causal convolution signal
%     tempSpikeRate = histcounts(tempSpikeIndices, 'BinWidth', 30000, 'BinLimits', [0,nSamples]);
%     % tempDeciSpikeRate = decimate(tempSpikeRate,10); % decimate for faster plotting
% 
%     % Initialize the figure
%     unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3902    0.5616    0.3614    0.3669], 'Visible', 'off');
% 
%     % ===========================
%     % Plot a blank average waveform plot
%     % ===========================
%     subplot(3,3,[1,4])
%     plot(1, 1, 'Color', [0.65, 0.65, 0.65, 0.5])
%     xlabel('Time (ms)')
%     ylabel('Voltage (\muV)')
%     xlim([-1,2])
%     title("UNIT" + num2str(iUnit, "%.3d"));
% 
%     % ===========================
%     % Plot the ACG histogram plot
%     % ===========================
%     subplot(3,3,2)
%     tempH = histogram('BinCounts', tempACGCounts, 'BinEdges', tempACGEdges, 'Normalization', 'probability');
%     tempH.FaceColor = colorMatrix(iUnit,:);
%     hold on
%     plot([-3,-3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
%     plot([3,3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
%     violRatio = sum(tempH.Values(tempH.BinEdges >= -3 & tempH.BinEdges <= 3))/sum(tempH.Values);
%     xlabel('Time lag (ms)')
%     ylabel('Probability')
%     title(num2str(violRatio*100) + "%")
% 
%     % ============================
%     % Plot the ISI histogram plot
%     % ============================
%     subplot(3,3,5)
%     isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
%     isiTempHist.FaceColor = colorMatrix(iUnit,:);
%     hold on
%     plot([3,3],[0,max(isiTempHist.Values)+0.005], 'k--', 'LineWidth', 1)
%     xlim([0,50])
%     violRatio = sum(isiTempHist.Values(1:3));
%     xlabel('Interspike interval (ms)')
%     ylabel('Probability')
%     title(num2str(violRatio*100) + "%")
% 
%     % =========================
%     % Plot the Spike Rate plot
%     % =========================
%     subplot(3,3,[7,8])
%     plot((1:numel(tempSpikeRate)), tempSpikeRate, 'k')
%     xlabel('Time (s)');
%     ylabel('Spike Rate (Hz)');
% 
%     % ====================================================================
%     % Plot blank subplots for spacing
%     % ====================================================================    
%     subplot(3,3,[3,6,9])
% 
%     % Save the figure
%     drawnow; % Ensure figure is rendered even if not visible
%     outFilePath = saveFigPath + "\" + modelName + "_" + brainRegion + "_UNIT" + num2str(iUnit,"%.3d") + "_summary.png";
%     exportgraphics(unitSummaryFig, outFilePath, 'Resolution', 300);
% 
%     close(unitSummaryFig);
%     % saveas(unitSummaryFig, saveFigPath + "\" + dataID + "_PHY_UNIT" + num2str(iUnit,"%.3d") + "_summary.png")
% 
% end

%% Plot summary figure for each simulated unit (using a new format)

% For each unit create a unit summary figure showing:
% (1) A histogram of the # of spikes per 1 second bin (w/ Fano Factor)
% (2) The ACG Histogram (-/+ 3ms violation threshold)
% (3) The ISI (+ 3ms violation threshold)
% (4) The Firing Rate across the entire recording

% Create data extraction specific folders if they don't exist already
savePath = uigetdir();
if ~isfolder(savePath + "\unit_summary_figures")
    mkdir(savePath + "\unit_summary_figures");
end
saveFigPath = savePath + "\unit_summary_figures";

% Create a set of different colors to use for visual distinction of units
colorMatrix = createpastelcolormatrix(nUnits, 1, 0);

% Save the colorMatrix 
save(fullfile(savePath, "unitColorMatrix.mat"), "colorMatrix");

tic
for iUnit = 1:useNUnits%nUnits
    
    disp("Plotting summary figure for unit #" + iUnit + "...")

    % Extract the Spiking data
    tempSpikeIndices = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
    tempMeanFiringRate = meanFiringRates(iUnit);

    % Compute the Fano Factor by reshaping entire experiment into 1 second bins
    binWidth = 1000; % [milliseconds]
    [tempFanoFactor, tempBinnedSpikes] = computefanofactor(tempSpikeIndices,binWidth,nSamples,sampleFreq);
    tempMaxRate = max(tempBinnedSpikes); % spikes per second
    nBins = size(tempBinnedSpikes,1);

    % Compute the Fano Factor as a function of bin size
    binWidths = double(round(logspace(1,3,8))); %[10 50 100 200 500 1000];
    nBinWidths = length(binWidths);
    multipleFanoFactors = nan(1,nBinWidths);
    for iBinWidth = 1:nBinWidths
        binWidth = binWidths(iBinWidth);
        [thisFanoFactor, ~] = computefanofactor(tempSpikeIndices,binWidth,nSamples,sampleFreq);
        multipleFanoFactors(iBinWidth) = thisFanoFactor;
    end

    % Extract the ACG data
    tempACGCounts = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{1};
    tempACGEdges = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{2};

    % Extract the ISI data
    tempISICounts = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{1};
    tempISIEdges = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{2};

    % Compute the spike rate using a 1-second long causal convolution signal
    tempSpikeRate = histcounts(tempSpikeIndices, 'BinWidth', 30000, 'BinLimits', [0,nSamples]);
    % tempDeciSpikeRate = decimate(tempSpikeRate,10); % decimate for faster plotting
    
    % Initialize the figure
    unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3792    0.1989    0.3724    0.7156], 'Visible', 'off');
    
    if strcmp(modelName,models(1))
        sgtitle({"Homogenous Poisson", "No odors", brainRegion + " UNIT" + num2str(iUnit, "%.3d") + ", \lambda = " + tempMeanFiringRate + " Hz "})
    elseif strcmp(modelName,models(2))
        sgtitle({"Poisson with Refractory Period", "No odors", brainRegion + " UNIT" + num2str(iUnit, "%.3d") + ", \lambda = " + tempMeanFiringRate + " Hz, RP = " + refractoryPeriodMillisec + " ms"})
    end

    % ===========================
    % Plot the spike count distribution and print fano factor
    % ===========================
    subplot(5,2,[1,3])
    tempH = histogram(tempBinnedSpikes);
    tempH.FaceColor = colorMatrix(iUnit,:);
    hold on
    xlabel('spike count')
    ylabel('number of 1 second bins')
    title({"Fano factor: " + tempFanoFactor})
    xValues = 0:tempMaxRate;
    % Generate poisson distribution
    poissonDist = poisspdf(xValues,tempMeanFiringRate);
    poissonSum = poisscdf(tempMaxRate,tempMeanFiringRate);
    plot(xValues,poissonDist*poissonSum*nBins,'LineWidth',2)
    if strcmp(modelName,models(2))
        % NEED TO WORK ON THIS CODE IF WANT IT TO BE FUNCTIONAL
        % GOAL IS TO PLOT THE THEORETICAL PDF FOR THE DEAD-TIME POISSON
        % DISTRIBUTION
        % % generate dead-time modified Poisson PDF
        % t = linspace(0,tempMaxRate,round(tempMaxRate*(1000/3)));
        % validInx = (t >= refractoryPeriodMillisec);
        % poissonDeadTimePDF = tempMeanFiringRate * exp(-tempMeanFiringRate * (t(validInx) - refractoryPeriodMillisec))
        % poissonDeadTimeDist = 
        % poissonDeadTimeSum = 
        % plot(xValues,poissonDeadTimeDist*poissonDeadTimeSum*nBins,'LineWidth',2)
    else
        legend("simulation","Poisson PDF")
    end
    hold off

    % ===========================
    % Plot the ACG histogram plot
    % ===========================
    subplot(5,2,2)
    tempH = histogram('BinCounts', tempACGCounts, 'BinEdges', tempACGEdges, 'Normalization', 'probability');
    tempH.FaceColor = colorMatrix(iUnit,:);
    hold on
    plot([-3,-3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
    plot([3,3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
    violRatio = sum(tempH.Values(tempH.BinEdges >= -3 & tempH.BinEdges <= 3))/sum(tempH.Values);
    xlabel('Time lag (ms)')
    ylabel('Probability')
    title("ACG violations: " + num2str(violRatio*100) + "%")
    
    % ============================
    % Plot the ISI histogram plot
    % ============================
    subplot(5,2,4)
    isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
    isiTempHist.FaceColor = colorMatrix(iUnit,:);
    hold on
    plot([3,3],[0,max(isiTempHist.Values)+0.005], 'k--', 'LineWidth', 1)
    xlim([0,50])
    violRatio = sum(isiTempHist.Values(1:3));
    xlabel('Interspike interval (ms)')
    ylabel('Probability')
    if violRatio*100 < isiViolPercentAllowed
        title("ISI violations: " + num2str(violRatio*100) + "%   < " + num2str(isiViolPercentAllowed) + "%")
    else
        title("ISI violations: " + num2str(violRatio*100) + "%   > " + num2str(isiViolPercentAllowed) + "%",'Color','r')
    end

    % =========================
    % Plot the fano factor as a function of bin size
    % =========================
    subplot(5,2,[5,6])
    plot(binWidths,multipleFanoFactors,'LineWidth',2,'Color','k')
    hold on
    scatter(binWidths,multipleFanoFactors,'filled','o','MarkerEdgeColor','k','MarkerFaceColor','k')
    yline(1,'r--','LineWidth',2)
    set(gca, 'XScale','log')
    title("Fano factor as a function of bin size")
    xlabel('Bin width (ms)')
    ylabel('Fano factor')
    xlim([0 1000])
    ylim([0 max([2 max(multipleFanoFactors)*1.01])])
    legend("simulation","","Poisson",'Location','northwest')

    % =========================
    % Plot a middle N seconds of the raster plot
    % =========================
    subplot(5,2,[7,8])
    nSeconds = 5;
    startTime = 10; % seconds
    middleNSecondSpikes = tempSpikeIndices(tempSpikeIndices < (startTime + nSeconds)*sampleFreq);
    middleNSecondSpikes = middleNSecondSpikes(middleNSecondSpikes > startTime*sampleFreq);
    scatter(middleNSecondSpikes/sampleFreq,1,'|k','LineWidth',2)
    title(nSeconds + " second(s) of raster plot")
    xlabel('Time (s)')
    ylabel('spike (yes/no)')
    ylim([0.9 1.1])
    xlim(startTime + [0 nSeconds])
    yticklabels([])
    yticks(1)

    % =========================
    % Plot the Spike Rate plot
    % =========================
    subplot(5,2,[9,10])
    plot((1:numel(tempSpikeRate))./60, tempSpikeRate, 'k')
    xlabel('Time (min)');
    ylabel('Spike Rate (Hz)');
    xlim([0 experimentDuration/60])

    % Save the figure
    drawnow; % Ensure figure is rendered even if not visible
    outFilePath = saveFigPath + "\" + modelName + "_" + brainRegion + "_UNIT" + num2str(iUnit,"%.3d") + "_summary.png";
    exportgraphics(unitSummaryFig, outFilePath, 'Resolution', 300);

    close(unitSummaryFig);
    % saveas(unitSummaryFig, saveFigPath + "\" + dataID + "_PHY_UNIT" + num2str(iUnit,"%.3d") + "_summary.png")
    
end
toc

%% Plot summary figure for each empirical unit (using a new format)

% For each unit create a unit summary figure showing:
% (1) A histogram of the # of spikes per 1 second bin (w/ Fano Factor)
% (2) The ACG Histogram (-/+ 3ms violation threshold)
% (3) The ISI (+ 3ms violation threshold)
% (4) The Firing Rate across the entire recording

% Create data extraction specific folders if they don't exist already
savePath = uigetdir();
if ~isfolder(savePath + "\unit_summary_figures")
    mkdir(savePath + "\unit_summary_figures");
end
saveFigPath = savePath + "\unit_summary_figures";

% Create a set of different colors to use for visual distinction of units
colorMatrix = createpastelcolormatrix(nUnits, 1, 0);

% Save the colorMatrix 
save(fullfile(savePath, "unitColorMatrix.mat"), "colorMatrix");

for iUnit = 1:5%nUnits
    
    % Extract the Spiking data
    tempSpikeIndices = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
    tempMeanFiringRate = meanFiringRates(iUnit);

    % Compute the Fano Factor by reshaping entire experiment into 1 second bins
    binWidth = 1000; % [milliseconds]
    [tempFanoFactor, tempBinnedSpikes] = computefanofactor(tempSpikeIndices,binWidth,nSamples,sampleFreq);
    tempMaxRate = max(tempBinnedSpikes); % spikes per second
    nBins = size(tempBinnedSpikes,1);

    % Compute the Fano Factor as a function of bin size
    binWidths = [10 50 100 200 500 1000];
    nBinWidths = length(binWidths);
    multipleFanoFactors = nan(1,nBinWidths);
    for iBinWidth = 1:nBinWidths
        binWidth = binWidths(iBinWidth);
        [thisFanoFactor, ~] = computefanofactor(tempSpikeIndices,binWidth,nSamples,sampleFreq);
        multipleFanoFactors(iBinWidth) = thisFanoFactor;
    end

    % Extract the ACG data
    tempACGCounts = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{1};
    tempACGEdges = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.acgHistCArr{2};

    % Extract the ISI data
    tempISICounts = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{1};
    tempISIEdges = empiricalUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).summaryData.isiHistCArr{2};

    % Compute the spike rate using a 1-second long causal convolution signal
    tempSpikeRate = histcounts(tempSpikeIndices, 'BinWidth', 30000, 'BinLimits', [0,nSamples]);
    % tempDeciSpikeRate = decimate(tempSpikeRate,10); % decimate for faster plotting
    
    % Initialize the figure
    unitSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3792    0.1989    0.3724    0.7156], 'Visible', 'on');
    
    if strcmp(modelName,models(1))
        sgtitle({"Homogenous Poisson", "No odors", "UNIT" + num2str(iUnit, "%.3d") + ", \lambda = " + tempMeanFiringRate + "Hz "})
    elseif strcmp(modelName,models(2))
        sgtitle({"Poisson with Refractory Period", "No odors", "UNIT" + num2str(iUnit, "%.3d") + ", \lambda = " + tempMeanFiringRate + " Hz, RP = " + refractoryPeriodMillisec + " ms"})
    end

    % ===========================
    % Plot the spike count distribution and print fano factor
    % ===========================
    subplot(5,2,[1,3])
    tempH = histogram(tempBinnedSpikes);
    tempH.FaceColor = colorMatrix(iUnit,:);
    hold on
    xlabel('spike count')
    ylabel('number of 1 second bins')
    title({"Fano factor: " + tempFanoFactor})
    xValues = 0:tempMaxRate;
    poissonDist = poisspdf(xValues,tempMeanFiringRate);
    poissonSum = poisscdf(tempMaxRate,tempMeanFiringRate);
    plot(xValues,poissonDist*poissonSum*nBins,'LineWidth',2)
    legend("recorded","Poisson PDF")
    hold off

    % ===========================
    % Plot the ACG histogram plot
    % ===========================
    subplot(5,2,2)
    tempH = histogram('BinCounts', tempACGCounts, 'BinEdges', tempACGEdges, 'Normalization', 'probability');
    tempH.FaceColor = colorMatrix(iUnit,:);
    hold on
    plot([-3,-3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
    plot([3,3],[0,max(tempH.Values)+0.005], 'k--', 'LineWidth', 1)
    violRatio = sum(tempH.Values(tempH.BinEdges >= -3 & tempH.BinEdges <= 3))/sum(tempH.Values);
    xlabel('Time lag (ms)')
    ylabel('Probability')
    title("ACG violations: " + num2str(violRatio*100) + "%")
    
    % ============================
    % Plot the ISI histogram plot
    % ============================
    subplot(5,2,4)
    isiTempHist = histogram('BinCounts', tempISICounts, 'BinEdges', tempISIEdges, 'Normalization', 'probability');
    isiTempHist.FaceColor = colorMatrix(iUnit,:);
    hold on
    plot([3,3],[0,max(isiTempHist.Values)+0.005], 'k--', 'LineWidth', 1)
    xlim([0,50])
    violRatio = sum(isiTempHist.Values(1:3));
    xlabel('Interspike interval (ms)')
    ylabel('Probability')
    if violRatio*100 < isiViolPercentAllowed
        title("ISI violations: " + num2str(violRatio*100) + "%   < " + num2str(isiViolPercentAllowed) + "%")
    else
        title("ISI violations: " + num2str(violRatio*100) + "%   > " + num2str(isiViolPercentAllowed) + "%",'Color','r')
    end

    % =========================
    % Plot the fano factor as a function of bin size
    % =========================
    subplot(5,2,[5,6])
    plot(binWidths,multipleFanoFactors,'LineWidth',2,'Color','k')
    hold on
    scatter(binWidths,multipleFanoFactors,'filled','o','MarkerEdgeColor','k','MarkerFaceColor','k')
    yline(1,'r--','LineWidth',2)
    set(gca, 'XScale','log')
    title("Fano factor as a function of bin size")
    xlabel('Bin width (ms)')
    ylabel('Fano factor')
    xlim([0 1000])
    ylim([0 max([2 max(multipleFanoFactors)*1.01])])
    legend("recorded","","Poisson")

    % =========================
    % Plot a middle N seconds of the raster plot
    % =========================
    subplot(5,2,[7,8])
    nSeconds = 5;
    startTime = 10; % seconds
    middleNSecondSpikes = tempSpikeIndices(tempSpikeIndices < (startTime + nSeconds)*sampleFreq);
    middleNSecondSpikes = middleNSecondSpikes(middleNSecondSpikes > startTime*sampleFreq);
    scatter(middleNSecondSpikes/sampleFreq,1,'|k','LineWidth',2)
    title(nSeconds + " second(s) of raster plot")
    xlabel('Time (s)')
    ylabel('spike (yes/no)')
    ylim([0.9 1.1])
    xlim(startTime + [0 nSeconds])
    yticklabels([])
    yticks(1)

    % =========================
    % Plot the Spike Rate plot
    % =========================
    subplot(5,2,[9,10])
    plot((1:numel(tempSpikeRate))./60, tempSpikeRate, 'k')
    xlabel('Time (min)');
    ylabel('Spike Rate (Hz)');
    xlim([0 experimentDuration/60])

    % Save the figure
    drawnow; % Ensure figure is rendered even if not visible
    outFilePath = saveFigPath + "\" + modelName + "_" + brainRegion + "_UNIT" + num2str(iUnit,"%.3d") + "_summary.png";
    exportgraphics(unitSummaryFig, outFilePath, 'Resolution', 300);

    close(unitSummaryFig);
    % saveas(unitSummaryFig, saveFigPath + "\" + dataID + "_PHY_UNIT" + num2str(iUnit,"%.3d") + "_summary.png")
    
end

          

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




%% LOCAL FUNCTION DEFINITONS

% % Homogenous Poisson simulation with refractory period
% function spikes = getspiketrainpoissonrefractoryperiod(meanFiringRateHz, sampleRateHz, durationSec, refractoryPeriodMillisec)
% % GETPOISSONSPIKETRAIN is a local function which produces a homogenous 
% % poisson spike train with a refractory period. 
% % 
% % Parameters:
% %   meanFiringRateHz -   
% %   sampleRateHz - 
% %   durationSec - whole number - total amount of time to simulate (in seconds)
% % 
% % The function returns a vector of time bins, where the value of each bin
% % is 0 when the neuron does not spike and 1 when the neuron spikes. 
% 
%     % calculate mean ISI needed to acheive target spike rate
%     meanISI = 1/meanFiringRateHz; % (seconds) 1 second / (10 spikes/second) = 0.1 seconds/spike = 0.1 second ISI
% 
%     % convert the refractory period into seconds
%     refractoryPeriodSec = refractoryPeriodMillisec/1000;
% 
%     % simulate spike train
%     exponentialSpikeTimes = exprnd(meanISI); % (seconds) spike times generated from an exponential distribution
%     nSpike = 1;
%     while exponentialSpikeTimes(end) < durationSec
%         nextISI = exprnd(meanISI);
%         while nextISI < refractoryPeriodSec
%             nextISI = exprnd(meanISI);
%         end
%         exponentialSpikeTimes = [exponentialSpikeTimes (exponentialSpikeTimes(end) + nextISI)]; % (get next ISI)
%         nSpike = nSpike + 1;
%     end
% 
%     % convert the spike times into a spike train of 0's and 1's
%     spikes = convertspiketimestospiketrain(exponentialSpikeTimes, sampleRateHz, durationSec);
% 
% end

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

function odorSequence = getRandomOdorSequence(nOdors, nTrials)
% GETRANDOMODORSEQUENCE is a local function which produces a sequence of 
% simulated odorant stimuli.   
    odorSequence = repmat(1:nOdors, 1, nTrials);
    odorSequence = odorSequence(randperm(nOdors*nTrials));
end