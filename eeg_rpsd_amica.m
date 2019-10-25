function psdmed = eeg_rpsd_amica(EEG, model, nfreqs, pct_data)

% check if smoothed model probability exists
assert(isfield(EEG.etc.amica,'smModProb'), 'Smoothed probabilities of AMICA models are missing')

% clean input cutoff freq
nyquist = floor(EEG.srate / 2);
if ~exist('nfreqs', 'var') || isempty(nfreqs)
    nfreqs = nyquist;
elseif nfreqs > nyquist
    nfreqs = nyquist;
end
if ~exist('pct_data', 'var') || isempty(pct_data)
    pct_data = 100;
end

% setup constants
ncomp = size(EEG.icaweights, 1);
n_points = min(EEG.pnts, EEG.srate);
window = windows('hamming', n_points, 0.54)';
cutoff = floor(EEG.pnts / n_points) * n_points;
index = bsxfun(@plus, ceil(0:n_points / 2:cutoff - n_points), (1:n_points)');
if ~exist('OCTAVE_VERSION', 'builtin')
    rng('default')
else
    rand('state', 0);
end
n_seg = size(index, 2) * EEG.trials;
subset = randperm(n_seg, ceil(n_seg * pct_data / 100)); % need to improve this
if exist('OCTAVE_VERSION', 'builtin') == 0
    rng('shuffle')
end

try
    %% slightly faster but high memory use
    % calculate windowed spectrums
    temp = reshape(EEG.icaact(:, index, :), [ncomp size(index) .* [1 EEG.trials]]);
    temp = bsxfun(@times, temp(:, :, subset), window);
    temp = fft(temp, n_points, 2);
    temp = abs(temp).^2;
    temp = temp(:, 2:nfreqs + 1, :) * 2 / (EEG.srate*sum(window.^2));
    if nfreqs == nyquist
        temp(:, end, :) = temp(:, end, :) / 2; end

    % calculate average PSD weighted by windowed model probability
    end_idx = min(size(temp,3),size(EEG.etc.amica.smModProb,2));
    temp = bsxfun(@times, temp(:,:,1:end_idx), reshape(EEG.etc.amica.smModProb(model,1:end_idx),1,1,[]));
    temp = sum(temp, 3)/sum(EEG.etc.amica.smModProb(model,:));
    psdmed = 20 * log10(temp);
    
%     % calculate outputs
%     psdmed = 20 * log10(median(temp, 3));

catch
    %% lower memory but slightly slower
    psdmed = zeros(ncomp, nfreqs);
    for it = 1:ncomp
        % calculate windowed spectrums
        temp = reshape(EEG.icaact(it, index, :), [1 size(index) .* [1 EEG.trials]]);
        temp = bsxfun(@times, temp(:, :, subset), window);
        temp = fft(temp, n_points, 2);
        temp = temp .* conj(temp);
        temp = temp(:, 2:nfreqs + 1, :) * 2 / (EEG.srate*sum(window.^2));
        if nfreqs == nyquist
            temp(:, end, :) = temp(:, end, :) / 2; end

        % calculate average PSD weighted by windowed model probability
        end_idx = min(size(temp,3),size(EEG.etc.amica.smModProb,2));
        temp = bsxfun(@times, temp(:,:,1:end_idx), reshape(EEG.etc.amica.smModProb(model,1:end_idx),1,1,[]));
        temp = sum(temp, 3)/sum(EEG.etc.amica.smModProb(model,:));
        psdmed(it, :) = 20 * log10(temp);
        
    end
end
end
