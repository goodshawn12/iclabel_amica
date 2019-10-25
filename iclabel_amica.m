function EEG = iclabel_amica(EEG, model, version)
%ICLABEL Function for EEG IC labeling
%   Label independent components using ICLabel.  Go to
%   https://sccn.ucsd.edu/wiki/ICLabel for a tutorial on this plug-in. Go
%   to labeling.ucsd.edu/tutorial/about for more information.
%
%   Inputs:
%       EEG: EEGLAB EEG structure. Must have an attached ICA decomposition
%       version (optional): Version of ICLabel to use. Default
%       (recommended) version is used if passed 'default', '', or left
%       empty. Pass 'lite' to use ICLabelLite or 'beta' to use the original
%       beta version of ICLabel (only recommended for replicating old
%       results).
%       model: indices of models for applying ICLabel
%
%   Results are stored in EEG.etc.ic_classifications.ICLabel. The matrix of
%   label vectors is stored under "classifications" and the cell array of
%   class names are stored under "classes". The version if ICLabel used is
%   stored under The matrix stored under "version". "classifications" is
%   organized with each column matching to the equivalent element in
%   "classes" and each row matching to the equivalent IC. For example, if
%   you want to see what percent ICLabel attributes IC 7 to the class
%   "eye", you would look at:
%       EEG.etc.ic_classifications.ICLabel.classifications(7, 3)
%   since EEG.etc.ic_classifications.ICLabel.classes{3} is "eye".


% check inputs
if ~exist('model', 'var') || isempty(model)
    model = 1:EEG.etc.amica.num_models;
end

if ~exist('version', 'var') || isempty(version)
    version = 'default';
else
    version = lower(version);
end
assert(any(strcmp(version, {'default', 'lite', 'beta'})), ...
    ['Invalid network version choice. ' ...
    'Version must be one of the following: ' ...
    '''default'', ''lite'', or ''beta''.'])
if any(strcmpi(version, {'', 'default'}))
    flag_autocorr = true;
else
    flag_autocorr = false;
end

% calc smoothed probability of AMICA models for using ICLabel
win_smooth = 1;     % sec
win_walk = 0.5;     % sec
EEG = comp_smooth_model_prob(EEG, win_smooth, win_walk);

% iterate through all specified models
classifications = cell(1,length(model));
for idx_model = 1:length(model)
    fprintf('AMICA-ICLabel: processing model %d\n',model(idx_model));
    
    % load amica model to EEG
    EEG = pop_changeweights_amica(EEG,model(idx_model));
    
    % check for ica
    assert(isfield(EEG, 'icawinv') && ~isempty(EEG.icawinv), ...
        'You must have an ICA decomposition to use ICLabel')
    
    % extract features
    disp 'ICLabel: extracting features...'
    features = ICL_feature_extractor_amica(EEG, model(idx_model), flag_autocorr);
    
    % run ICL
    disp 'ICLabel: calculating labels...'
    labels = run_ICL(version, features{:});
    
    % save labels
    disp 'ICLabel: saving results...'
    classifications{idx_model} = labels;
end

% save into EEG
EEG.etc.amica.ICLabel.classes = ...
    {'Brain', 'Muscle', 'Eye', 'Heart', ...
    'Line Noise', 'Channel Noise', 'Other'};
EEG.etc.amica.ICLabel.version = version;
EEG.etc.amica.ICLabel.classifications = classifications;
EEG.etc.amica.ICLabel.modelIdx = model;
  