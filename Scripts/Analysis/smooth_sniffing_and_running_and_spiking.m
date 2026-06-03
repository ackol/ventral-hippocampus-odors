% SMOOTH_SNIFFING_AND_RUNNING_AND_SPIKING.m The following script enables 
% conversion of the extracted sniff traces, raw running behavior data, and 
% spike rasters into continuous time-varying rates with matched effective 
% timescales.
%
% Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_full_session_raw_sniffTrace_data.mat
%       (4) [AK0xx]_full_session_inst_velocity.mat
%       (5) [AK0xx]_aligned_phy_unit_data.mat
%       (6) significantResultsAllMice.mat
%       (7) directory in which to save outputs
%       USER MUST SPECIFY IN-LINE:
%       (8) convolveType - options are "boxcar" or "gaussian"
%       (9) convolveDurationSeconds - total kernel window width (in seconds) 
%       (10) sigmaSeconds - gaussian standard deviation (in seconds) only used when convolveType is set equal to "gaussian"
%       (11) decimateFactor - for downsampling data after smoothing
%
% Outputs:
%       (1) [AK###]_D#_paired_full_session_inst_velocity.mat
%       (2) [AK###]_D#_smoothed_spike_rate_data.mat
%
% Dependencies:
%   The script (specifically, PART 02) relies upon the following dependencies:
%       MATLAB Aerospace Toolbox
%       MATLAB Signal Processing Toolbox
%   Ensure these add-ons are installed prior to running the script.
% 
% Structure: The script is split into the following parts:
%
%   PART 01 - Provide user inputs, set directory paths, create log file, and load needed data
%
%   PART 02 - Process & smooth the sniffing data
%
%   PART 03 - Process & smooth the run-wheel data
%
%   PART 04 - Smooth the pre-processed spiking data
%
% Designed by Anna C. Kolstad
% Adapted from smooth_running_and_spiking.m which was itself adapted from
% process_raw_behavior_rig_data.m Version 2.1 &
% plot_spike_run_correlation.m Version 1.0.
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: May 19, 2026 (by Anna Kolstad)
% Script last updated: May 19, 2026 (by Anna Kolstad)
% Version 1.0

%% PART 01.0 - Provide user inputs (directory paths, smoothing parameters, etc.)
clear vars
clc
scriptStartTime = datetime;

% Define metadata structure
metadata.run_info.run_start_time = string(scriptStartTime); % get time now (at start of script running)
metadata.run_info.run_end_time = [];
metadata.script_info.script_name = [mfilename '.m']; % get script name
metadata.script_info.script_location = [mfilename('fullpath') '.m']; % get script location
metadata.script_info.git_local_repo = getlocalgitrepo(mfilename('fullpath')); % get git local repo name
metadata.script_info.git_remote_repo = getremotegitrepo(mfilename('fullpath')); % get git remote repo name
metadata.script_info.git_branch = getgitbranchname(mfilename('fullpath')); % get git branch
metadata.script_info.git_commit = getgitcommit(mfilename('fullpath')); % get id for most recent git commmit
metadata.script_info.git_commit_date = getgitcommitdate(mfilename('fullpath')); % get date of most recent git commmit

% ===========================================
% PROVIDE USER INPUT TO SPECIFY PARAMTERS (INLINE)
% ===========================================
% USER DEFINED (IN-LINE): Define parameters for smoothing kernel 
convolveType = "gaussian"; % options are "boxcar" or "gaussian"
convolveDurationSeconds = 3; % (seconds) total kernel window width (in seconds) 
sigmaSeconds = 0.5; % (seconds) only used when convolveType is set equal to "gaussian"
% Define parameters for plotting decimation
decimateFactor = 10;
decimateSampFreq = sampFreq/decimateFactor;

% Compute timescales for reference
effectiveTimescale2sigma = sigmaSeconds*2*2;
effectiveTimescale3sigma = sigmaSeconds*3*2;
% Approximate -3dB cutoff frequency (i.e. the frequency at which 
% power is halved). Frequencies in the original signal that fall
% above this cutoff frequency will be significantly attenuated. 
frequencyCutoff = 1 / (2*pi*sigmaSeconds); % (Hz) 

% Save smoothing kernel parameters to a structure
kernel = struct();
kernel.convolveType = convolveType;
kernel.convolveDurationSeconds = convolveDurationSeconds; 
if strcmp(kernel.convolveType, "gaussian")
    kernel.sigmaSeconds = sigmaSeconds;
end

% Save smoothing kernel parameters to metadata
metadata.kernel.convolve_type = convolveType;
metadata.kernel.convolve_duration_seconds = convolveDurationSeconds;
metadata.kernel.convolve_sigma_seconds = sigmaSeconds;
metadata.kernel.effective_timescale_2sigma_seconds = effectiveTimescale2sigma;
metadata.kernel.effective_timescale_3sigma_seconds = effectiveTimescale3sigma;
metadata.kernel.minus_3dB_cutoff_frequency_Hz = frequencyCutoff;

% ===========================================
% PROVIDE USER INPUT TO SPECIFY PARAMTERS (VIA GUI)
% ===========================================

% Enter the mouse label to be associated with analysis files
mouseLabel = cell2mat(inputdlg('Enter the mouse ID (E.g. KS030):', 'Mouse ID Input', [1 75]));
metadata.parameters.mouse_label = mouseLabel;

% Enter the session label (e.g. day label or other unique identifier) to be associated with analysis files
sessionLabel = cell2mat(inputdlg('Enter the session label (e.g. D# or other unique identifier):', 'Session ID Input', [1 75]));
metadata.parameters.session_label = sessionLabel;

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% Set directory where extracted raw data is located
rawDataPath = uigetdir(baseDir,"Select directory where extracted raw data is located (for one day of one animal)");

% Create data extraction specific folders if they don't exist already
if ~isfolder(rawDataPath + "\smoothed_sniff_run_spike_data")
    mkdir(rawDataPath + "\smoothed_sniff_run_spike_data");
    mkdir(rawDataPath + "\smoothed_sniff_run_spike_data\figures");
end
savePath = rawDataPath + "\smoothed_sniff_run_spike_data";

% ===========================================
% LOAD IN DATA
% ===========================================

% Load in the raw sniff data
fileName = mouseLabel + "_" + sessionLabel + "_full_session_raw_sniffTrace_data.mat";
if isfile(rawDataPath + "\" + fileName)
    load(rawDataPath + "\" + fileName, "sniffRawData", "sampFreq");
    disp('   Sniff data loaded.')
else
    error('   Detected missing sniff data.')
end
% Populate sniffing metadata
metadata.parameters.sniff.input_MAT_file = rawDataPath + "\" + fileName;
metadata.parameters.sniff.output_MAT_file = [];

% Load in the raw rotary wheel data
fileName = mouseLabel + "_" + sessionLabel + "_full_session_raw_rotaryWheel_data.mat";
if isfile(rawDataPath + "\" + fileName)
   load(rawDataPath + "\" + fileName, "runningRawData", "sampFreq");    
   disp('   Run data loaded.')
end
% Populate running metadata
metadata.parameters.run.input_MAT_file = rawDataPath + "\" + fileName;
metadata.parameters.run.output_MAT_file = [];

% select full_session_epoch_labels.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_full_session_epoch_labels.mat file for " + mouseLabel + ".",rawDataPath);
disp("Loading locomotion epoch data structure...")
load(fullfile(path,file),"decimatedFinalEpochLabels","minEpochDuration","velocityThreshold");

% Load in the aligned_phy_unit_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_aligned_phy_unit_data.mat file for " + mouseLabel + ".",baseDir);
disp("Loading aligned phy unit data structure...")
load(fullfile(path,file));
% Populate unit metadata
metadata.parameters.units.input_MAT_file = path + "\" + file;
metadata.parameters.units.output_MAT_file = [];

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs (recommend to manually create directory named sniff_run_spike).");
saveDir = baseOutputPath + "\" + "smoothed_data";
% make new folders if they do not already exist
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% PART 01.1 - Create log file
% ===========================================
% CREATE LOG (NO USER INPUT REQUIRED)
% ===========================================

% Create log to save command line output
logname = sprintf("%s_%s_processbehavior_%s.log",string(mouseLabel),string(sessionLabel),datestr(scriptStartTime,'yyyy-mm-dd_HH-MM-SS'));
diary(fullfile(savePath,logname))

clc;
% Print log header
disp("================ PROCESS RAW BEHAVIOR RIG DATA =================")
disp("Processing workflow initialized...")
disp("...DATETIME: " + string(scriptStartTime))
disp("...SCRIPT:  " + metadata.script_info.script_name)
disp("...LOCATION:  " + metadata.script_info.script_location)
disp("Logging git-version control credentials...")
disp("...LOCAL-REPO:  " + metadata.script_info.git_local_repo)
disp("...REMOTE-REPO:  " + metadata.script_info.git_remote_repo)
disp("...BRANCH:  " + metadata.script_info.git_branch)
disp("...COMMIT: " + metadata.script_info.git_commit + ", (" + metadata.script_info.git_commit_date + ")") 
disp("Defining workflow parameters...")
disp("...MOUSE LABEL: " + mouseLabel)
disp("...SESSION LABEL: " + sessionLabel)
disp("...INPUT-PATH: " + rawDataPath)
disp("...SAVE-PATH: " + rawDataPath + "\smoothed_run_spike_data")
disp("================================================================")


%% PART 02 - Process & Smooth Sniffing Data
disp("Processing sniffing data...")

tic

% Decimate the raw sniff data by a factor of 10 (30000 --> 3000Hz)
% Note: Decimate function applies a Chebyshev Type 1 lowpass filter 
% before downsampling, to prevent aliasing. Note that this filter 
% has a nonlinear phase response, so it may distort sharp transient 
% changes in the data. Decimating also limits the temporal resolution 
% of the breathing data to 0.33 ms per sample (when decimateFactor 
% is set to 10). 
decimateSniffData = decimate(sniffRawData, decimateFactor); 
% decimateSniffData = max(decimateSniffData)-decimateSniffData;
% Save decimate parameters to metadata
metadata.parameters.sniff.decimate_factor = decimateFactor;
metadata.parameters.sniff.decimate_sample_frequency = decimateSampFreq;

% Initialize a breathmetric object with the raw sniff data
bmObj = breathmetrics(decimateSniffData, decimateSampFreq, "rodentAirflow");
        
% Set parameters for feature estimation
zScore = 1; % parameter to normalize the data in bmObj
baselineCorrectionMethod = 'sliding'; % parameter to determine type of baseline correction
simplifyOpt = 1; % parameter to set nInhales = nExhales
verboseOpt = 1; % parameter to set sub-function outputs to visible as feature estimation is performed
% Save parameters to metadata
metadata.parameters.sniff.z_score = zScore;
metadata.parameters.sniff.baseline_correction_method = baselineCorrectionMethod;
metadata.parameters.sniff.simplify_option = simplifyOpt;

% Perform feature estimation on the sniff trace signal using above
% parameters
bmObj.estimateAllFeatures(zScore, baselineCorrectionMethod, simplifyOpt, verboseOpt);
        
% ===========================================
% COMPUTE SNIFF RATE VIA CONVOLUTION FUNCTION
% ===========================================
% Create a binary vector of inhale peaks
sniffBinaryVector = zeros(1, length(decimateSniffData));
sniffBinaryVector(bmObj.inhalePeaks) = 1;

% ***NEED TO CHECK THIS PART OF THE CODE!! IT LOOKS LIKE smoothSniffRate
% ends up with one more sample point than either deciVelocity or
% smoothedSpikes
% Compute smoothed sniff rate via convolution
[smoothSniffRate, convolveSignalSniff, tConvolveSniff] = computesniffrateconvolution(sniffBinaryVector, decimateSampFreq, convolveType, convolveDurationSeconds, sigmaSeconds); 
kernel.sniff.convolveSignal = convolveSignalSniff;
kernel.sniff.convolveTimeVector = tConvolveSniff;

% Create smoothed (convolved) sniff rate plot
sniffFig = figure('Color', 'white', 'Units', 'normalized', 'Position', [0.4276    0.6532    0.2242    0.2134], 'Visible', 'on');
plot((0:length(smoothSniffRate)-1)/decimateSampFreq/60, smoothSniffRate, 'k-');
xlabel('Time (min)')
ylabel('Sniff Rate (Hz)')
xlim([0 (length(smoothSniffRate)-1)/decimateSampFreq/60])
ylim([min(smoothSniffRate)-0.25 max(smoothSniffRate)+0.25])
title(mouseLabel + " " + sessionLabel + " - Sniff Rate (Convolution: " + convolveType + ", \sigma = " + sigmaSeconds + " sec, window: " + convolveDurationSeconds + " sec)");

% Save smoothed (convolved) sniff rate plot
figFileName = mouseLabel + "_" + sessionLabel + "_full_session_sniff_rate.png";
saveFigPath = rawDataPath + "\smoothed_sniff_run_spike_data\figures\";
saveas(sniffFig, saveFigPath + figFileName);
close all

% ===========================================
% SAVE SNIFF RATE DATA
% ===========================================
% Save the smoothed (convolved) sniff rate data
fullSavePath = rawDataPath + "\smoothed_sniff_run_spike_data\" + mouseLabel + "_" + sessionLabel + "_smoothed_sniff_rate";
save(fullSavePath, "smoothSniffRate", "bmObj", "decimateSampFreq", "decimateFactor", "convolveType","convolveDurationSeconds", "sigmaSeconds", '-v7.3');
disp('Section 02 successfully ran. Sniff rate & BreathMetric object computed.')

toc

%% PART 03 - Process & Smooth Running Data: Compute Continuous Velocity
disp("Processing running data...")

tic

% Physical parameters of the BOURNS Rotary Optical Encoder (ENS1J-B28L00256) 
% attached to a 6-inch diameter running wheel
wheelRadius = 3; % inches
inchPerPulse = 2*pi*wheelRadius/256; % inches per pulse
distancePerPulse = convlength(inchPerPulse, 'in', 'm')*100; % convert distance per pulse to centimeters

% Save parameters to metadata
metadata.parameters.run.sample_frequency = sampFreq;
metadata.parameters.run.wheel_radius = wheelRadius;
metadata.parameters.run.inch_per_pulse = inchPerPulse;
metadata.parameters.run.convolve_type = convolveType;
metadata.parameters.run.convolve_duration_seconds = convolveDurationSeconds;
if strcmp(convolveType,"gaussian")
    metadata.parameters.run.convolve_sigma_seconds = sigmaSeconds;
end

% Compute wheel velocity
[wheelVelocity, directionVect, convolveSignalRun, tConvolveRun] = computewheelvelocityconvolution(runningRawData, distancePerPulse, sampFreq, convolveType, convolveDurationSeconds, sigmaSeconds);
kernel.run.convolveSignal = convolveSignalRun;
kernel.run.convolveTimeVector = tConvolveRun;

% Compute decimated velocity by a factor of 10
deciVelocity = decimate(wheelVelocity, decimateFactor);
metadata.parameters.run.decimate_factor = decimateFactor;

% Compute decimated speed
deciSpeed = abs(deciVelocity);

% Create velocity trace plot
velocityFig = figure('Color', 'white', 'Units', 'normalized', 'Position', [0.4276    0.6532    0.2242    0.2134], 'Visible', 'on');
plot((0:length(deciVelocity)-1)/decimateSampFreq/60, deciVelocity, 'k-');
xlabel('Time (min)')
ylabel('Velocity (cm/s)')
xlim([0 (length(deciVelocity)-1)/decimateSampFreq/60])
title(mouseLabel + " " + sessionLabel + " - Decimated Velocity");

% Save velocity trace plot figure
figFileName = mouseLabel + "_" + sessionLabel + "_full_session_velocity.png";
saveFigPath = rawDataPath + "\smoothed_sniff_run_spike_data\figures\";
saveas(velocityFig, saveFigPath + figFileName);
close all

% Create speed trace plot
speedFig = figure('Color', 'white', 'Units', 'normalized', 'Position', [0.4276    0.6532    0.2242    0.2134], 'Visible', 'on');
plot((0:length(deciSpeed)-1)/decimateSampFreq/60, deciSpeed, 'k-');
xlabel('Time (min)')
ylabel('Velocity (cm/s)')
xlim([0 (length(deciSpeed)-1)/decimateSampFreq/60])
title(mouseLabel + " " + sessionLabel + " - Decimated Speed");

% Save speed trace plot figure
figFileName = mouseLabel + "_" + sessionLabel + "_full_session_speed.png";
saveFigPath = rawDataPath + "\smoothed_sniff_run_spike_data\figures\";
saveas(speedFig, saveFigPath + figFileName);
close all

% Create speed trace plot overlaid with running epochs

% find start/end indices for running epochs
difference = diff([0 decimatedFinalEpochLabels 0]);
starts = find(difference == 1)./decimateSampFreq./60;
ends = (find(difference == -1)-1)./decimateSampFreq./60;

% Plot running epochs
speedFig = figure('Color', 'white', 'Units', 'normalized', 'Position', [0.0276    0.6532    0.8242    0.2134], 'Visible', 'on');
plot((0:length(deciSpeed)-1)/decimateSampFreq/60, deciSpeed, 'k-');
hold on
% get y limits
ylimits = ylim;
% shade in running epochs
for iEpoch = 1:length(starts)
    patch([starts(iEpoch) ends(iEpoch) ends(iEpoch) starts(iEpoch)],...
        [ylimits(1) ylimits(1) ylimits(2) ylimits(2)],...
        'green',...
        'FaceAlpha',0.3,...
        'EdgeColor','none');
end
%plot((0:length(decimatedFinalEpochLabels)-1)/decimateSampFreq/60,decimatedFinalEpochLabels*maxSpeed*1.05)
xlabel('Time (min)')
ylabel('Velocity (cm/s)')
xlim([0 (length(deciSpeed)-1)/decimateSampFreq/60])
title(mouseLabel + " " + sessionLabel + " - Decimated Speed and Running Epochs");

% Save speed trace plot w/ running epochs overlaid figure
figFileName = mouseLabel + "_" + sessionLabel + "_full_session_speed_epochs.png";
saveFigPath = rawDataPath + "\smoothed_sniff_run_spike_data\figures\";
saveas(speedFig, saveFigPath + figFileName);
close all

% Save velocity data
disp("Saving velocity data...")
saveVelocityPath = rawDataPath + "\smoothed_sniff_run_spike_data\" + mouseLabel + "_" + sessionLabel + "_smoothed_run_speed";
save(saveVelocityPath, "wheelVelocity", "deciVelocity", "deciSpeed","decimateSampFreq","decimatedFinalEpochLabels","minEpochDuration","velocityThreshold","sampFreq","kernel", '-v7.3');

toc

%% PART 04 - Smooth spiking data for all units (from the same animal)
tic

% Determine total number of unit
nUnits = numel(fieldnames(alignedUnitDataStruct)) - 1;
sampFreq = 30000; % Hz

% Create structure for storing smoothed spike rates
smoothedSpikeRateStruct = struct();

% Compute continuous spike rates
for iUnit = 1:nUnits
    disp("Processing unit #" + iUnit + "/" + nUnits)

    % Copy unit info to the new data structure
    smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info;
    smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).info.overallSpikeRate = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).qualityMetrics.SpikeRate;

    % Reconstruct binary spike train
    targetSpikeIndices = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
    totalSamplePoints = alignedUnitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSamples;
    binarySpikeTrain = zeros(totalSamplePoints,1);
    binarySpikeTrain(targetSpikeIndices) = 1;
    
    % Compute spike rate & save to new data structure
    [spikeRate, convolveSignalSpike, tConvolveSpike] = computespikerateconvolution(binarySpikeTrain, sampFreq, convolveType, convolveDurationSeconds, sigmaSeconds);
    smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).continuousFiringRate = spikeRate;

    % Compute decimated spike rate & save to new data structure
    deciSpikeRate = decimate(spikeRate, decimateFactor);
    smoothedSpikeRateStruct.("UNIT" + num2str(iUnit, "%.3d")).decimatedFiringRate = deciSpikeRate;

end
kernel.convolveSignal = convolveSignalSpike;
kernel.convolveTimeVector = tConvolveSpike;
toc

tic
% Save smoothed spike rate data
disp("Saving smoothed spike rate data...")
saveSpikeRatePath = rawDataPath + "\smoothed_sniff_run_spike_data\" + mouseLabel + "_" + sessionLabel + "_smoothed_spike_rates";
save(saveSpikeRatePath, "smoothedSpikeRateStruct", "kernel", "sampFreq", '-v7.3');
toc

%% END: Close log file

% Save  metadata
metadata.run_info.run_end_time = string(datetime); % get time now (at end of run)
metadata.parameters.output_MAT_file = saveVelocityPath + ".mat";
metadataFilename = mouseLabel + "_" + sessionLabel + "_paired_full_session_inst_velocity_metadata.json";
% Write metadata to JSON file. If a metadata file of this type already
% exsits, overwrite it. 
jsonString = jsonencode(metadata, PrettyPrint=true);
fid = fopen(saveDir + "\" + metadataFilename,'w');
fprintf(fid,'%s',jsonString);
fclose(fid);

disp('SMOOTH RUNNING AND SPIKING script is complete.');
diary off

%% ----------------------------------------------------------------
%% LOCAL FUNCTIONS
function [nOdors, nTrials, nOdorsPerSet] = getodorsequenceparameters()
    % Popup to get numeric inputs for 3 experiment parameters

    labels = {'Number of Odors:', ...
              'Number of Trials per Odor:', ...
              'Number of Odors per Set:'};

    nFields = numel(labels);
    defaultVals = {'24', '12', '12'};
    inputs = gobjects(nFields, 1);

    figWidth = 300;
    figHeight = 60 + nFields * 40;

    f = figure('Name', 'Experiment Parameters', ...
               'MenuBar', 'none', ...
               'ToolBar', 'none', ...
               'NumberTitle', 'off', ...
               'Resize', 'off', ...
               'Position', [500, 400, figWidth, figHeight]);

    % Create text labels and input boxes
    for i = 1:nFields
        uicontrol(f, 'Style', 'text', ...
            'String', labels{i}, ...
            'HorizontalAlignment', 'left', ...
            'Position', [20, figHeight - i*40, 180, 20]);

        inputs(i) = uicontrol(f, 'Style', 'edit', ...
            'String', defaultVals{i}, ...
            'Position', [200, figHeight - i*40, 70, 25]);
    end

    % Submit button
    uicontrol(f, 'Style', 'pushbutton', ...
        'String', 'Submit', ...
        'Position', [(figWidth-80)/2, 15, 80, 30], ...
        'Callback', @(src, event) uiresume(f));

    uiwait(f);

    % Extract numeric values
    nOdors       = str2double(inputs(1).String);
    nTrials      = str2double(inputs(2).String);
    nOdorsPerSet  = str2double(inputs(3).String);

    delete(f);
end