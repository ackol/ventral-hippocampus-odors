% Homogenous Poisson simulation with refractory period
function spikes = getspiketrainpoissonrefractoryperiod(meanFiringRateHz, sampleRateHz, durationSec, refractoryPeriodMillisec)
%GET-SPIKE-TRAIN-POISSON-REFRACTORY-PERIOD simulates a homogenous poisson 
% spike train with a refractory period. 
% 
% Inputs:
%   meanFiringRateHz - (Hz)
%
%   sampleRateHz - (Hz)
%
%   durationSec - (seconds) whole number representing the total amount of
%   time to simulate in seconds
%
%   refractoryPeriodMillisec - (milliseconds) 
% 
% Outputs:
%   spikes - a vector of time bins, where the value of each bin is 0 when 
%       the neuron does not spike and 1 when the neuron spikes.
%
% Dependencies:
%   convertspiketimestospiketrain.m
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