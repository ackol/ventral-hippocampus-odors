% SMOOTH_RUNNING_AND_SPIKING.m The following script enables conversion 
% of the extracted raw running behavior data into proper metric based data, 
% using the same timescales for smoothing as for spike smoothing
%
% Inputs:
%       USER MUST SPECIFY VIA UI:
%       (1) mouseID
%       (2) base directory
%       (3) [AK0xx]_smoothed_spike_rate_data.mat
%       (4) [AK0xx]_full_session_inst_velocity.mat
%       (5) significantResultsAllMice.mat
%       (6) directory in which to save outputs
%       USER MUST SPECIFY IN-LINE:
%       (7) convolveType - options are "boxcar" or "gaussian"
%       (8) convolveDurationSeconds - total kernel window width (in seconds) 
%       (9) sigmaSeconds - gaussian standard deviation (in seconds) only used when convolveType is set equal to "gaussian"
%       (10) decimateFactor - for downsampling data after smoothing
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
%   PART 02 - Process & smooth the run-wheel data
%
%   PART 03 - Smooth the already pre-processed spiking data
%
% Designed by Anna C. Kolstad
% Adapted from process_raw_behavior_rig_data.m Version 2.1 &
% plot_spike_run_correlation.m Version 1.0.
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 10, 2026 (by Anna Kolstad)
% Script last updated: April 12, 2026 (by Anna Kolstad)
% Version 1.1

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
convolveDurationSeconds = 0.5; % (seconds) 500 milliseconds; total kernel window width (in seconds) 
sigmaSeconds = 0.05; % (seconds) 50 milliseconds; only used when convolveType is set equal to "gaussian"
% Define parameters for plotting decimation
decimateFactor = 10;

% Save smoothing kernel parameters to a structure
kernel = struct();
kernel.convolveType = convolveType;
kernel.convolveDurationSeconds = convolveDurationSeconds; 
if strcmp(kernel.convolveType, "gaussian")
    kernel.sigmaSeconds = sigmaSeconds;
end

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
if ~isfolder(rawDataPath + "\smoothed_run_spike_data")
    mkdir(rawDataPath + "\smoothed_run_spike_data");
    mkdir(rawDataPath + "\smoothed_run_spike_data\figures");
end
savePath = rawDataPath + "\smoothed_run_spike_data";

% ===========================================
% LOAD IN DATA
% ===========================================

% Load in the raw rotary wheel data
fileName = mouseLabel + "_" + sessionLabel + "_full_session_raw_rotaryWheel_data.mat";
if isfile(rawDataPath + "\" + fileName)
   load(rawDataPath + "\" + fileName, "runningRawData", "sampFreq");    
   disp('   Run data loaded.')
end
% Populate running metadata
metadata.parameters.input_run_MAT_file = rawDataPath + "\" + fileName;
metadata.parameters.output_run_MAT_file = [];

% Load in the aligned_phy_unit_data.mat variable file
[file, path] = uigetfile(".mat","Select [AK0xx]_aligned_phy_unit_data.mat file for " + mouseLabel + ".",baseDir);
disp("Loading aligned phy unit data structure...")
load(fullfile(path,file));
% Populate unit metadata
metadata.parameters.input_units_MAT_file = path + "\" + file;
metadata.parameters.output_units_MAT_file = [];

% select path for output figures
baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs (recommend to manually create directory named speed_coding).");
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


%% PART 02 - Process & Smooth Running Data: Compute Continuous Velocity
disp("Processing running data...")

% Physical parameters of the BOURNS Rotary Optical Encoder (ENS1J-B28L00256) 
% attached to a 6-inch diameter running wheel
wheelRadius = 3; % inches
inchPerPulse = 2*pi*wheelRadius/256; % inches per pulse
distancePerPulse = convlength(inchPerPulse, 'in', 'm')*100; % convert distance per pulse to centimeters

% Save parameters to metadata
metadata.parameters.sample_frequency = sampFreq;
metadata.parameters.wheel_radius = wheelRadius;
metadata.parameters.inch_per_pulse = inchPerPulse;
metadata.parameters.convolve_type = convolveType;
metadata.parameters.convolve_duration_seconds = convolveDurationSeconds;
if strcmp(convolveType,"gaussian")
    metadata.parameters.convolve_sigma_seconds = sigmaSeconds;
end

% Compute wheel velocity
[wheelVelocity, directionVect, convolveSignalRun, tConvolveRun] = computewheelvelocityconvolution(runningRawData, distancePerPulse, sampFreq, convolveType, convolveDurationSeconds, sigmaSeconds);
kernel.convolveSignal = convolveSignalRun;
kernel.convolveTimeVector = tConvolveRun;

% Compute decimated velocity by a factor of 10
deciVelocity = decimate(wheelVelocity, decimateFactor);
metadata.parameters.decimate_factor = decimateFactor;

% Save velocity data
disp("Saving velocity data...")
saveVelocityPath = saveDir + "\" + mouseLabel + "_" + sessionLabel + "_paired_full_session_inst_velocity";
save(saveVelocityPath, "wheelVelocity", "deciVelocity", "sampFreq", "kernel", '-v7.3');

% Save velocity metadata
runMetadata.run_info.run_end_time = string(datetime); % get time now (at end of run)
runMetadata.parameters.output_MAT_file = saveVelocityPath + ".mat";
runMetadataFilename = mouseLabel + "_" + sessionLabel + "_paired_full_session_inst_velocity_metadata.json";
% Write metadata to JSON file. If a metadata file of this type already
% exsits, overwrite it. 
jsonString = jsonencode(runMetadata, PrettyPrint=true);
fid = fopen(saveDir + "\" + runMetadataFilename,'w');
fprintf(fid,'%s',jsonString);
fclose(fid);

%% PART 03 - Smooth spiking data for all units (from the same animal)
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
saveSpikeRatePath = saveDir + "\" + mouseLabel + "_" + sessionLabel + "_smoothed_spike_rate_data";
save(saveSpikeRatePath, "smoothedSpikeRateStruct", "kernel", "sampFreq", '-v7.3');
toc

%% END: Close log file

disp('PROCESS RAW BEHAVIOR RIG DATA is complete.');
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