paths = setupPaths();

function depthVec = getCurrentDepthProfile_universal(inst)
% getCurrentDepthProfile_universal
% Pulls the STATIC cell depth vector (NAVD88 elevation of bin centers) for an FRF current profiler
% directly from the THREDDS NCML aggregation for that instrument.
%
% INPUT
%   inst (char/string): e.g., 'sig940-300', 'awac-4.5m', 'awac-11m'
%
% OUTPUT
%   depthVec (double column vector): depth/bin elevations (m, NAVD88), FillValue -> NaN
%
% Notes:
% - Uses the NCML aggregation at:
%   https://chldata.erdc.dren.mil/thredds/dodsC/frf/oceanography/currents/<inst>/<inst>.ncml
% - Tries hard to locate the correct variable:
%   1) exact name 'depth' (case-insensitive)
%   2) otherwise searches attributes for "Cell Depth" in long_name/description/short_name
% - Replaces _FillValue (commonly -999) with NaN

    inst = char(inst);

    base = 'https://chldata.erdc.dren.mil/thredds/dodsC/frf/oceanography/currents';
    ncmlUrl = sprintf('%s/%s/%s.ncml', base, inst, inst);

    % Pull metadata
    info = ncinfo(ncmlUrl);

    vnames = string({info.Variables.Name});
    depthVar = "";

    % (1) Prefer exact variable name "depth"
    idx = find(strcmpi(vnames, "depth"), 1);
    if ~isempty(idx)
        depthVar = vnames(idx);
    else
        % (2) Search attributes for "Cell Depth"
        for k = 1:numel(info.Variables)
            v = info.Variables(k);
            attNames = string({v.Attributes.Name});
            for a = 1:numel(attNames)
                nm = lower(attNames(a));
                if nm=="long_name" || nm=="description" || nm=="short_name"
                    val = v.Attributes(a).Value;
                    if ischar(val) || isstring(val)
                        if contains(string(val), "cell depth", "IgnoreCase", true)
                            depthVar = string(v.Name);
                            break;
                        end
                    end
                end
            end
            if strlength(depthVar) > 0
                break;
            end
        end
    end

    if strlength(depthVar) == 0
        error('Could not find a depth variable in: %s', ncmlUrl);
    end

    % Read full vector
    depthVec = ncread(ncmlUrl, char(depthVar));
    depthVec = depthVec(:);

    % Apply _FillValue if present
    fillValue = [];
    try
        vinfo = ncinfo(ncmlUrl, char(depthVar));
        attNames = string({vinfo.Attributes.Name});
        iFV = find(strcmpi(attNames, "_FillValue"), 1);
        if ~isempty(iFV)
            fillValue = vinfo.Attributes(iFV).Value;
        end
    catch
        % ignore
    end

    if ~isempty(fillValue) && isnumeric(depthVec)
        depthVec(depthVec == fillValue) = NaN;
    end
end
