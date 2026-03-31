function [baseDir] = getbasedirectory()
% GET-BASE-DIRECTORY This short function allows the user to select a base 
%       directory from which to do all their file navigation.  
%
%       INPUTS:
%       
%           USER MUST SPECIFY VIA UI:
%           (1) directory
%
%       OUTPUTS:
%           baseDir - string representing directory location
%
% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: February 4, 2026
% Script last updated: February 4, 2026
% Version 1.0

% Select base directory from which to navigate
baseDir = uigetdir('',"Select base directory from which to navigate.");
