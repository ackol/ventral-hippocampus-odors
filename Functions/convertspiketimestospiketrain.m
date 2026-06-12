function spikes = convertspiketimestospiketrain(spikeTimes, sampleRateHz, durationSec)
% CONVERTSPIKETIMESTOSPIKETRAIN is a local function that converts a set of
% spike times (expressed in seconds) into a binary spike train of 0's and
% 1's. This is particularly useful when generating simulations that match
% recorded empirical data sets.
%
% Inputs:
%   spikeTimes - spike times in units of seconds
%   
%   sampleRateHz - 
%
%   durationSec - 
%
% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% History: Was originally developed as a local function within
% poissonSimulation.m
% Script first created: June 11, 2026
% Script last updated: June 11, 2026
% Version 1.0

    binsPerSecond = sampleRateHz; % (bins/second)
    nElements = durationSec*binsPerSecond;
    
    spikes = zeros(1,nElements);
    temp = round(spikeTimes*binsPerSecond); % seconds * bins/second = bin index
    spikes(temp) = 1;
    spikes = spikes(1:nElements);

end