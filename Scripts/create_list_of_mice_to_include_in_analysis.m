% create_list_of_mice_to_include_in_analysis.m - This script saves a list 
% of the mice to analyze. This will allow you to read in the list of mice 
% to iterate over when running other scripts.
%
%   Inputs:
%       
%       USER MUST SPECIFY IN-LINE:
%       (1) list of ID's of the mice you wish to process data for
%
%       USER MUST SPECIFY VIA UI:
%       (2) directory within which to save the mouse list
%
%   Outputs:
%
%       (1) miceToAnalyze.mat - contains two variables:
%               mice - a cell array containing the ID's of the animals
%               nMice - an integer denoting the total number of mice
%
%   Dependencies: none
%
% Designed by Anna C. Kolstad
% Author contact email: anna_kolstad@urmc.rochester.edu
% Padmanabhan Lab, University of Rochester School of Medicine
% PI contact email: krishnan_padmanabhan@urmc.rochester.edu
% Script first created: February 4, 2026 (Version 1.0)
% Script last updated: February 4, 2026
% Version 1.0.

% USER INPUT (1): Manually specify the mouse IDs in-line
mice = {"AK012", "AK013", "AK014", "AK015", "AK024","AK025","AK026","AK027"};

% Get the total number of mice
nMice = length(mice);

% Save to a data structure for future use
% USER INPUT (2): Use UI to select directory in which to save file
saveDir = uigetdir('',"Select directory to save mouse list to.");
% Export variables in .mat file format
save(saveDir + "\" + "miceToAnalyze", "mice","nMice",'-v7.3');

