function EEG = comp_smooth_model_prob(EEG, win_smooth, win_walk)
% Inputs:
%   - win_smooth:   length of sliding/smoothing window in sec
%   - win_walk:     walk length of the sliding window in sec

% Outputs:
%   - EEG.etc.amica.smModProb:  smoothed model probability time courses
%   - EEG.etc.amica.tModProb:   corresponding time (in samples)

% message
disp 'AMICA: computing smoothed model probability...';

% size of model probability
[nMod,nPts] = size(EEG.etc.amica.v);
cutoff = floor(nPts / win_walk / EEG.srate) * win_walk * EEG.srate;
% blockSize  = floor( (cutoff - win_smooth*EEG.srate) / win_walk / EEG.srate);
blockSize  = floor( (nPts - (win_smooth-win_walk)*EEG.srate) / win_walk / EEG.srate); % accurate implementation
smModProb = zeros(nMod,blockSize);
timeModProb = zeros(1,blockSize);   % in samples

% compute smoothed model probability
% [TODO] implement matrix operation to speed up
for block = 1:blockSize
    data_range = floor((block-1)*win_walk*EEG.srate+1) : floor((block-1)*win_walk*EEG.srate+win_smooth*EEG.srate);
    
    % exclude data points that were rejected by AMICA (with LL = 0)
    keep_range = sum(EEG.etc.amica.v(:,data_range)) ~= 0;
    
    % compute average model probability in the sliding window
    smModProb(:,block) = mean(10.^EEG.etc.amica.v(:,data_range(keep_range)),2);
    timeModProb(block) = floor((block-1)*win_walk*EEG.srate+1);
end

% check if NaN (all samples in the window were rejected)
idx_nan = find(isnan(smModProb));
if ~isempty(idx_nan)
    smModProb(idx_nan) = 0;
end

% output
EEG.etc.amica.smModProb = smModProb; 
EEG.etc.amica.tModProb = timeModProb; 

end