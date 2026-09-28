function [zeroCrossings, meanPeriod, Hs, meanWavePeriod] = zeroCrossingStats(signal, fs)
    signal = detrend(signal);
    crossings = find(diff(sign(signal)) ~= 0);
    zeroCrossings = crossings;
    periods = diff(crossings) / fs;
    meanPeriod = mean(periods);
    % Estimate Hs from crest-trough method (approximate)
    waveHeights = abs(signal(crossings(2:end)) - signal(crossings(1:end-1)));
    Hs = 4 * std(waveHeights);
    meanWavePeriod = meanPeriod;
end