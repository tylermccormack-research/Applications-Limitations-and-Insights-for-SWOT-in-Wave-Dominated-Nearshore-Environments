function [Hs, Tp] = spectralStats(signal, fs)
    signal = detrend(signal);
    nfft = length(signal);
    [Pxx, f] = pwelch(signal, [], [], nfft, fs);
    df = mean(diff(f));
    m0 = trapz(f, Pxx);
    m1 = trapz(f, f .* Pxx);
    Hs = 4 * sqrt(m0);
    Tp = 1 / f(Pxx == max(Pxx));  % peak period
    if length(Tp) > 1
        Tp = Tp(1);
    end
end