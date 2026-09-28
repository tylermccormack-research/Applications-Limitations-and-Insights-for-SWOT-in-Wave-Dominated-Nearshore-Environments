function [uPick, vPick, zPick] = pickKthBinFromSurface(u, v, z, kFromSurface)
% pickKthBinFromSurface
% Picks the kth valid bin closest to the surface, where surface is z=0.
% "Closest to surface" means: largest z that is still <= 0 (smallest negative magnitude).
%
% Inputs:
%   u, v : [Nbins x 1] currents (can contain NaN)
%   z    : [Nbins x 1] NAVD88 elevations of bin centers (0=surface, negative underwater)
%   kFromSurface : 1 = closest-to-surface valid bin, 2 = second closest, etc.
%
% Outputs:
%   uPick, vPick : selected currents (NaN if none)
%   zPick        : selected depth (NaN if none)

    if nargin < 4 || isempty(kFromSurface)
        kFromSurface = 1;
    end

    uPick = NaN; vPick = NaN; zPick = NaN;

    % Valid: underwater/at-surface bin + finite currents + finite depth
    valid = isfinite(z) & (z <= 0) & isfinite(u) & isfinite(v);

    if ~any(valid)
        return;
    end

    % Sort valid bins by z descending: closest to 0 first (e.g., -0.2, -0.5, -1.0, ...)
    idxValid = find(valid);
    [~, order] = sort(z(idxValid), 'descend');
    idxSorted = idxValid(order);

    % kth-from-surface
    if kFromSurface > numel(idxSorted)
        return;
    end

    idx = idxSorted(kFromSurface);

    uPick = u(idx);
    vPick = v(idx);
    zPick = z(idx);
end
