

% plot_all_probe_waveforms.m - This code is designed to plot the mean
% waveform for all units on each contact
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: November 12, 2025
% Script last updated: April 12, 2026
% Version 2.0

%% Load data

clear all 
clc

% Manually specify Mouse ID
mouseLabel = inputdlg('Enter animal ID','User input');

% Manually specify the sample frequency of the ephys recording
sampFreq = 30000;

% select base directory from which to navigate
baseDir = uigetdir('',"Select base directory for this animal.");

% load spike variable
[unitDataFileName, unitDataFilePath] = uigetfile(".mat","Select .mat file containing alignedUnitDataStruct variable for " + mouseLabel + ".",baseDir);
tic
disp("Loading aligned units data structure...")
load(fullfile(unitDataFilePath,unitDataFileName),"alignedUnitDataStruct"); % note: took <3 mins
toc

baseOutputPath = uigetdir(baseDir,"Select base directory in which to save outputs.");


%% Get the probe geometry

[probeConfigFileName, probeConfigFilePath] = uigetfile("*.mat","Select probe config");
fullProbeConfigPath = fullfile(probeConfigFilePath,probeConfigFileName);
% Load the probe configuration file
load(fullProbeConfigPath);
remappedProbeMat = intanProbeRemap; originalProbeMat = probeLayout;
clear intanProbeRemap probeLayout;

% Set the data identifier prefix based off of the ephys data file name
dataID = strsplit(unitDataFileName, "_");
dataID = dataID{1};

%% Plot the mean waveforms

% % Create data extraction specific folders if they don't exist already
% if ~isfolder(unitDataFilePath + "\unit_summary_figures")
%     mkdir(unitDataFilePath + "\unit_summary_figures");
% end
% saveFigPath = unitDataFilePath + "\unit_summary_figures";

if exist("alignedUnitDataStruct",'var')
    unitDataStruct = alignedUnitDataStruct;
end

% Define the total number of units
nUnits = numel(fieldnames(unitDataStruct))-1; % Calculate the total number of units

% Create a set of different colors to use for visual distinction of units
colorMatrix = createpastelcolormatrix(nUnits, 1, 0);

% % Save the colorMatrix 
% save(fullfile(unitDataFilePath, "unitColorMatrix.mat"), "colorMatrix");
% 

% Initialize the figure
%probeSummaryFig = figure('Color','white', 'Units', 'normalized', 'Position', [0.3902    0.5616    0.3614    0.3669], 'Visible', 'on');
probeSummaryFig = figure('Color','white', 'Units', 'normalized',  'Visible', 'on');


for iUnit = 1:nUnits
    nSamples = unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.nSamples;

    % Extract the unit waveform data
    tempWaveformMatrix = unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.waveformMatrix;
    tempWaveformTimeVector = unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.waveformTimeVector;


    % ====================================================================
    % Plot the mean waveforms of the unit on the main electrode
    % ====================================================================    

    % ====== NEURONEXUS ======
    if strcmp(probeID, "NeuroNexusA4x16")
        % Geometrically define contact positions
        xPos = [repelem(150, 16)', repelem(350,16)', repelem(550,16)', repelem(750,16)'];
        yPos = repmat(flipud((100:50:(100+50*15))'),1,4);
        plot(xPos, yPos, '.', 'Color', [0.5, 0.5, 0.5], 'MarkerSize', 10); ylim([0,1000]); xlim([0, 900]);
        hold on

        [arrayRowPos, arrayColPos] = find(remappedProbeMat == unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.chanNumb);

    % ========================

    % ====== NEURONEXUS Buzsaki64spL ======
    elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
        % Geometrically define contact positions. Note: The
        % electrode placement drawn here does NOT precisely match
        % the layout on the actual probe. Instead, this is a more
        % abstract representation that captures some features of
        % relative electrode placement, removing the x-axis offsets
        % of contacts within each shank, and dramatically shrinking
        % the vertical distance between the four extra contacts on
        % shank four for the purposes of easier visualization. 
        xPos = [repelem(100, 10)', repelem(200,10)', repelem(300,10)', repelem(400,10)', repelem(500,10)', repelem(600,10)'];
        xPosExtra = [repelem(400,4)'];
        yPos = repmat(flipud((0:20:(20*9))'),1,6);
        yPosExtra = [flipud((220:40:340)')];
        plot(xPos, yPos, '.', 'Color', [0.5, 0.5, 0.5], 'MarkerSize', 10); ylim([0,500]); xlim([0, 700]);
        hold on
        plot(xPosExtra, yPosExtra, '.', 'Color', [0.5, 0.5, 0.5], 'MarkerSize', 10); ylim([-30,380]); xlim([0, 700]);
        % Consolidate the position matrices to facilitate later 
        % plotting of waveforms
        xPos = [repelem(100, 14)', repelem(200,14)', repelem(300,14)', repelem(400,14)', repelem(500,14)', repelem(600,14)'];
        yPos = repmat(flipud(([0:20:(20*9) 220:40:340])'),1,6);

        [arrayRowPos, arrayColPos] = find(remappedProbeMat == unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).info.chanNumb);
            
    % ========================
    end

    % % Extract their waveforms at the spike times of the main unit channel
    % windowSize = sampFreq*0.003; % set to be 3 ms
    % prePeak = (windowSize/3)-1; % set to be ~ 1ms BEFORE peak
    % postPeak = (windowSize/3); % set to be ~ 2ms AFTER peak
    if strcmp(probeID, "NeuroNexusA4x16")
        waveformLength = 175;
    elseif strcmp(probeID, "NeuroNexusBuzsaki64spL")
        waveformLength = 75;
    end

    % tempSpikeIndices = unitDataStruct.("UNIT" + num2str(iUnit, "%.3d")).eventData.spikeIndices;
    % tempSpikeIndicesMatrix = bsxfun(@plus, tempSpikeIndices, -prePeak:postPeak);
    % tempGrpWaveformMatrix = [];
    % for iGrpUnit = 1:numel(tempGrpChanNumbs)
    %     tempGrpCrudeWaveformMatrix = fullSessionPreProcData(tempGrpChanNumbs(iGrpUnit)+1, tempSpikeIndicesMatrix');
    %     tempGrpWaveformMatrix(:,:,iGrpUnit) = permute(reshape(tempGrpCrudeWaveformMatrix, [], windowSize, size(tempSpikeIndicesMatrix,1)), [3, 2, 1]);
    % end
    % 
    % % Plot their avg. waveforms at the specific electrode points along the
    % % array
    % for iGrpUnit = 1:size(tempGrpWaveformMatrix,3)
    %     meanWaveform = mean(tempGrpWaveformMatrix(:,:,iGrpUnit));
    %     xStartPt = xPos(tempGrpRowIdx(iGrpUnit), arrayColPos);
    %     xVector = linspace(xStartPt, xStartPt+waveformLength, 90);
    %     yVector = yPos(tempGrpRowIdx(iGrpUnit))+meanWaveform*.15;
    %     plot(xVector, yVector, 'Color', colorMatrix(iUnit,:))
    % end
    
                
    % Plot the unit main channel avg. waveform at the specific electrode
    % point along the array
    % yScaleFactors: AK012: 0.28; AK013: 0.80; AK014: 0.37; AK015: 0.8; AK024: 0.9; AK025: 0.75; AK026: 0.1;
    if strcmp(string(mouseLabel),"AK012")
        yScaleFactor = 0.28;
    elseif strcmp(string(mouseLabel),"AK013")
        yScaleFactor = 3.5;  
    elseif strcmp(string(mouseLabel),"AK014")
        yScaleFactor = 0.37;
    elseif strcmp(string(mouseLabel),"AK015")
        yScaleFactor = 0.8; 
    elseif strcmp(string(mouseLabel),"AK024")
        yScaleFactor = 0.9;
    elseif strcmp(string(mouseLabel),"AK025")
        yScaleFactor = 0.75;
    elseif strcmp(string(mouseLabel),"AK026")
        yScaleFactor = 0.10;
    else
        yScaleFactor = 0.10;
    end

    meanWaveform = yScaleFactor*mean(tempWaveformMatrix);
    meanWaveform = meanWaveform(1:ceil(3/4*length(meanWaveform)));
    xStartPt = xPos(arrayRowPos, arrayColPos);
    xVector = linspace(xStartPt, xStartPt+waveformLength, length(meanWaveform));
    yVector = yPos(arrayRowPos)+meanWaveform*.15;
    plot(xVector, yVector, 'Color', colorMatrix(iUnit,:), 'LineWidth', 1.2)
    plot(xPos(arrayRowPos, arrayColPos), yPos(arrayRowPos, arrayColPos), 'o', 'MarkerFaceColor', colorMatrix(iUnit,:), 'MarkerSize', 5, 'MarkerEdgeColor','k')

end

xlabel('Distance (\mum)')
ylabel('Distance (\mum)')
title(dataID + " probe waveforms")
axis equal

% Save the figure
saveas(probeSummaryFig, baseOutputPath + "\" + dataID + "_probewaveforms.png")
saveas(probeSummaryFig, baseOutputPath + "\" + dataID + "_probewaveforms.svg")
