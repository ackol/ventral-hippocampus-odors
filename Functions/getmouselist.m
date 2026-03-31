function [mice, nMice] = getmouselist(baseDir)
% GET-MOUSE-LIST This short function allows the user to select the 
%       pre-specified list of mice they would like to analyze.
%
%       INPUTS:
%       
%           (1) miceToAnalyze.mat
%
%       OUTPUTS:
%           (1) mice - cell array listing ID's of selected mice
%           (2) nMice - total number of mice
%
% Created by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: February 4, 2026
% Script last updated: February 4, 2026
% Version 1.0

% Select list of mice to analyze
[file, path] = uigetfile(".mat","Select miceToAnalyze.mat",baseDir);
load(fullfile(path,file),"mice","nMice");