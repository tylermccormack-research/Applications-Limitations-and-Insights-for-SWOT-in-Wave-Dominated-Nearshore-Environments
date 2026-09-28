function m = fancyMean(time, signal)
% fancyMean - Computes the mean of a signal, trimmed to start and end at a wave crest or trough
%
% Syntax:
%   m = fancyMean(time, signal)
%
% Inputs:
%   time   - Time vector (must be same length as signal)
%   signal - Signal vector (e.g., water surface elevation)
%
% Output:
%   m      - Mean of trimmed signal starting and ending at a crest or trough

% Ensure input is a column vector
time = time(:);
signal = signal(:);

if length(time) ~= length(signal)
    error('Time and signal vectors must be the same length.');
end

% Find local maxima and minima (crests and troughs)
[crests, locsMax] = findpeaks(signal);
[troughs, locsMin] = findpeaks(-signal);
troughs = -troughs;

% Combine crest and trough indices
extremaIdx = sort([locsMax; locsMin]);

% Sanity check
if length(extremaIdx) < 2
    warning('Not enough extrema found. Returning mean of full signal.');
    m = mean(signal);
    return;
end

% Choose the extrema pair that maximizes the length of the signal subset
maxLen = 0;
startIdx = 1;
endIdx = length(signal);
for i = 1:length(extremaIdx)-1
    idx1 = extremaIdx(i);
    for j = i+1:length(extremaIdx)
        idx2 = extremaIdx(j);
        len = idx2 - idx1 + 1;
        if len > maxLen
            maxLen = len;
            startIdx = idx1;
            endIdx = idx2;
        end
    end
end

% Trim signal to start and end at extrema
trimmedSignal = signal(startIdx:endIdx);

% Compute the mean
m = mean(trimmedSignal);

end
