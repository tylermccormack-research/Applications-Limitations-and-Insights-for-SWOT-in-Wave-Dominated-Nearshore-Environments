function L = computeWavelength(Tp, depth)
% COMPUTEWAVELENGTH  Solve linear dispersion relation for wavelength
%
%   L = computeWavelength(Tp, depth)
%
%   Inputs:
%       Tp      - wave period [s]  (vector or scalar)
%       depth   - water depth [m]  (same size as Tp)
%
%   Output:
%       L       - wavelength [m]   (same size as Tp)
%
%   Notes:
%       - Invalid Tp or depth (NaN, <=0) return NaN
%       - Uses fzero with safe guards
%       - Never crashes; always returns numeric vector

    g = 9.81;

    % Preallocate output
    L = NaN(size(Tp));

    % Loop through each element (robust, safe)
    for i = 1:numel(Tp)

        T = Tp(i);
        h = depth(i);

        % ---- Skip invalid entries ----
        if ~(isfinite(T) && T > 0 && isfinite(h) && h > 0)
            L(i) = NaN;
            continue;
        end

        % ---- Starting guess (deep-water approx) ----
        L0 = (g*T^2)/(2*pi);

        if ~isfinite(L0) || L0 <= 0
            L(i) = NaN;
            continue;
        end

        % ---- Define dispersion function ----
        fun = @(L_) (2*pi/T)^2 - g*(2*pi./L_).*tanh(2*pi*h./L_);

        % ---- Solve with fzero safely ----
        try
            L(i) = fzero(fun, L0);
        catch
            L(i) = NaN;  % fallback
        end
    end
end
