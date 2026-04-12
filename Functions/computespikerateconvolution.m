function [spikeRate, convolveSignal, t] = computespikerateconvolution(binarySpikeTrain, sampleFrequency, convolveType, convolveDuration, sigmaSeconds)
%COMPUTE-SPIKE-RATE-CONVOLUTION Compute the firing rate of a single unit
%(putative neuron) from a binary spike train
%
%   Inputs:
%       binarySpikeTrain - a 1xN vector of 0s and 1s, where N is the number
%           of sample points in the recording. 1s denoting the sample
%           points at which a spike peak was detected.
%
%       sampleFrequency - sampling frequency at which data was collected.
%
%       convolveType - string, denoting the type of convolution signal to
%           use. Allowed options are:
%
%           "boxcar" - uses a standard square wave
%
%           "gaussian" - uses a gaussian
%
%       convolveDuration - the length of the convolution signal in units of
%           seconds.
%
%       sigmaSeconds - decimal; only used when "convolveType" is set to 
%           "guassian". Defines the standard deviation of the gaussian
%           kernel (i.e. its spread). 
%
%
%   Outputs:
%       spikeRate - computed continuous firing rate in Hz.
%
%       convolveSignal - the kernel used by the convolution operation. The
%       x axis is in time. 
%   
%       t - the time vector corresponding to convolveSignal. Supplied in
%       order to allow easy plotting of the convolvesignal with the correct
%       time axis.
%   
%
% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: April 10, 2026 (by Anna C. Kolstad)
% Script last updated: April 10, 2026 (by Anna C. Kolstad)
% Version 1.0

% Create a 1-D convolution kernel
if strcmp(convolveType, "boxcar")
    [convolveSignal, t] = createboxcarkernel(convolveDuration, sampleFrequency);
elseif strcmp(convolveType, "gaussian")
    [convolveSignal, t] = creategaussiankernel(convolveDuration, sigmaSeconds, sampleFrequency);
end

% Compute the continuous spike rate using the convolution operator
spikeRate = conv(binarySpikeTrain, convolveSignal,'same').*sampleFrequency; % Hz

end