
% Require EEGLAB, EEG data, AMICA results (in a folder)
% Output:
%   output_iclabel_amica: a structure containing ICLabel results for mmAMICA

%% setting environment
eeglab % require EEGLAB

addpath(genpath('ICLabel1.1'))  % disable if ICLabel plugin installed
addpath('postAmicaUtility2.01') % disable if postAMICAUtility plugin installed

%% define parameters
% number of AMICA model
numMod = 20;

% version of ICLabel:
%   0: lite
%   1: default (more accurate but require more memory and time)
version = 0;

% define model index that ICLabel applies
model_idx = 1:20;

% define file path and file name for EEG
filepath = '/data/projects/Shawn/2019_Emogery/';
filename = 'EEG_Subj_1.set';

% define file path and folder name for AMICA output
filepath_amica = '/data/projects/Shawn/2019_Emogery/';
foldername_amica = 'amicaout';


%% run ICLabel for multi-model AMICA
disp 'Running ICLabel for multi-model AMICA...'

% load EEG data
EEG = pop_loadset('filename',filename,'filepath',filepath);

% load AMICA output forlder
outdir = [filepath_amica, foldername_amica];
EEG = pop_loadmodout(EEG,outdir);

% ICLabel for multi-model AMICA
if version
    EEG = iclabel_amica(EEG, model_idx, 'default');
else
    EEG = iclabel_amica(EEG, model_idx, 'lite');
end

% read output
output_iclabel_amica = EEG.etc.amica.ICLabel;

