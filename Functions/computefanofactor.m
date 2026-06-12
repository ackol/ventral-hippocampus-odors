function [fanoFactor, binnedSpikes] = computefanofactor(spikeEventIdx, binWidth, nSamples, sampFreq)
%COMPUTE-FANO-FACTOR Provided the indices of spike events and a desired bin 
% width, computes the Fano Factor by reshaping entire experiment into N 
% second bins
%
% Inputs:
%       spikeEventIdx - a 1xN or Nx1 vector containing the sample indices
%           at which spiking events occured.
%       
%       binWidth - integer denoting the width of histogram bins, in units 
%           of milliseconds
%
%       nSamples - integer denoting the total number of samples in the dataset       
%
%       sampFreq - sampling frequency at which data was collected
%
% Outputs:
%       fanoFactor - positive number representing the dispersion of the
%       spiking events (ratio of variance to the mean)
% 
%       binnedSpikes - vector containing integer number of spikes per bin
%
% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: June 11, 2026
% Script last updated: June 11, 2026
% Version 1.0

    spikes = zeros(1,nSamples);
    spikes(spikeEventIdx) =  1;
    nSamplesPerBin = int32((binWidth/1000)*sampFreq);
    totalElements = int64(nSamples-rem(nSamples,nSamplesPerBin));
    spikes = spikes(1:totalElements);
    binnedSpikes = sum(reshape(spikes,nSamplesPerBin,[])).';
    fanoFactor = var(binnedSpikes)/mean(binnedSpikes);

end