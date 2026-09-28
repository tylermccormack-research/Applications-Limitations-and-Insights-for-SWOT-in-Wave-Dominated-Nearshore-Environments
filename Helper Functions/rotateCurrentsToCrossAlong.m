function Currents_CSAS = rotateCurrentsToCrossAlong( ...
    instrumentCurrentEastProfile_byTime_L3_unsmoothed, ...
    instrumentCurrentNorthProfile_byTime_L3_unsmoothed, ...
    thetaCS_deg)

%ROTATECURRENTSTOCROSSALONG Rotate EN current profile vectors to cross/along (bin-by-bin),
%robust to blank cells ([]), missing, and tables storing vectors as cells.
%
% Inputs: 49x5 tables. Each entry is either:
%   - numeric vector (Nx1 or 1xN), OR
%   - cell containing numeric vector, OR
%   - [] / empty / missing
%
% Output struct Currents_CSAS:
%   .thetaCS_deg
%   .cross   (table, same size)
%   .along   (table, same size)
%   .nRotated (count of rotated entries)
%   .nEmpty   (count of empty/missing entries)
%   .nSkipped (count of non-numeric weird entries)

if nargin < 3 || isempty(thetaCS_deg)
    thetaCS_deg = 71.8;
end
theta = deg2rad(thetaCS_deg);

uEtab = instrumentCurrentEastProfile_byTime_L3_unsmoothed;
uNtab = instrumentCurrentNorthProfile_byTime_L3_unsmoothed;

assert(istable(uEtab) && istable(uNtab), "Inputs must be tables.");
assert(isequal(size(uEtab), size(uNtab)), "East/North tables must be the same size.");
assert(isequal(uEtab.Properties.VariableNames, uNtab.Properties.VariableNames), ...
    "East/North tables must have the same VariableNames.");

% Preallocate outputs as tables-of-cells holding vectors (most robust)
crossTab = uEtab;
alongTab = uEtab;

nR = size(uEtab,1);
nC = size(uEtab,2);

nRotated = 0; nEmpty = 0; nSkipped = 0;

for r = 1:nR
    for c = 1:nC

        e = uEtab{r,c};
        n = uNtab{r,c};

        % Unwrap if table stores a cell containing the vector
        if iscell(e); e = e{1}; end
        if iscell(n); n = n{1}; end

        % Treat missing/empty as empty output
        if isempty(e) || isempty(n) || (isnumeric(e) && all(isnan(e))) || (isnumeric(n) && all(isnan(n)))
            crossTab{r,c} = {[]};
            alongTab{r,c} = {[]};
            nEmpty = nEmpty + 1;
            continue
        end

        % Must be numeric to rotate
        if ~isnumeric(e) || ~isnumeric(n)
            crossTab{r,c} = {[]};
            alongTab{r,c} = {[]};
            nSkipped = nSkipped + 1;
            continue
        end

        if numel(e) ~= numel(n)
            error("Length mismatch at row %d, col %d: numel(E)=%d, numel(N)=%d", ...
                r, c, numel(e), numel(n));
        end

        % Preserve original shape (row vs col)
        sz0 = size(e);
        e = e(:);
        n = n(:);

        % Rotation (bin-by-bin)
        uCross = e .* sin(theta) + n .* cos(theta);
        uAlong = e .* cos(theta) - n .* sin(theta);

        crossTab{r,c} = {reshape(uCross, sz0)};
        alongTab{r,c} = {reshape(uAlong, sz0)};
        nRotated = nRotated + 1;

    end
end

Currents_CSAS = struct();
Currents_CSAS.thetaCS_deg = thetaCS_deg;
Currents_CSAS.cross = crossTab;
Currents_CSAS.along = alongTab;
Currents_CSAS.nRotated = nRotated;
Currents_CSAS.nEmpty   = nEmpty;
Currents_CSAS.nSkipped = nSkipped;

end
