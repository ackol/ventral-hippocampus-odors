% validate_which_RHDfile_contains_final_odor_delivery.m - This script
% determines which RHD files from a session recording contain odor delivery
% periods
%
%   Inputs: 
%       
%       (1) baseDir [UI] - directory from which to do file navigation
%       
%       (2) miceToAnalyze.mat - list of mouse ID's that you wish to process 
%           data for
%
%       The following input is needed for EACH animal:
%       (3+) [ANIMAL]_[DAY]_full_session_odor_sequence_matrix.mat - data
%           containing timing for all odorant deliveries for one recording
%           session (typically located in analyzed_behavior_data -->
%           processed_raw_data folder for each animal)
%
%   Outputs:
%       numberOfRHDfilesToAnalyze.mat - file containing the following
%       variables:
%           numberFilesToUse - number of RHD files to use from ephys
%                               recording
%           perAnimalFinalOdorDeliveryInformation - table showing
%                               calculations used to determine the 
%                               value of numberFileToUse 
%           durationPerRHDFileMinutes - parameter of recording
%           bufferSeconds - user specified analysis parameter
%
%   Dependencies:
%       getbasedirectory.m
%       getmouselist.m
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: February 3, 2026 (Version 1.0)
% Script last updated: February 9, 2026
% Version 1.0. 

%% Provide initial user inputs
clear all
clc

% Select base directory from which to navigate
baseDir = getbasedirectory();

% Select list of mice to analyze
[mice, nMice] = getmouselist(baseDir);

%% Define recording & experimental parameters
durationPerRHDFileMinutes = 7; % [minutes]
bufferSeconds = 30; % [seconds] duration of recorded time after final odor turns off that must be included for analysis purposes

%% Get data for each mouse

% Define variables for table
fileName = strings(0,nMice);
fileNum = nan(nMice,1);
fileNumWithBuffer = nan(nMice,1);
lastFile = nan(nMice,1);

% Extract data from behavior .mat files
for iMouse = 1:nMice
    % Load odor sequence information from Intan recording
    [file, path] = uigetfile(".mat","Select " + mice{iMouse} + "_D[#]_full_session_odor_sequence_matrix.mat",baseDir);
    load(fullfile(path,file)); % note: took <3 mins
    fileName{iMouse} = file;
    
    timeFinalOdorOffSeconds = odorSeqMat(144,5)/sampFreq; % [seconds]

    fileNum(iMouse) = timeFinalOdorOffSeconds/60/durationPerRHDFileMinutes;
    fileNumWithBuffer(iMouse) = (timeFinalOdorOffSeconds + bufferSeconds)/60/durationPerRHDFileMinutes;
    lastFile(iMouse) = ceil(fileNum(iMouse));

    clear odorSeqMat
end

% Compile calculated results into table
perAnimalFinalOdorDeliveryInformation = table(mice',fileName',fileNum,fileNumWithBuffer,lastFile,'VariableNames',{'Mouse ID','Data source','File index for final odor delivery','File index for final odor delivery with buffer','File containing final odor delivery'});

% Determine the number of RHD recording files to analyze for all animals
numberFilesToUse = max(lastFile);

%% Save to a data structure for future reference

% Export variables in .mat file format
save(baseDir + "\" + "numberOfRHDfilesToAnalyze", "numberFilesToUse","perAnimalFinalOdorDeliveryInformation","durationPerRHDFileMinutes","bufferSeconds",'-v7.3');