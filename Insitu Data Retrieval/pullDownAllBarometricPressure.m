%% ========================================================================
%  FRF THREDDS (OPeNDAP) — Derived Barometer (airPressure, mbar) RAW ONLY
%  Date range: 2023-07-01 through 2025-02-01 (UTC)
%  Fix: force UTC timezone for *all* datetime arrays
% ========================================================================

paths = setupPaths();

clear; clc;

outDir = "D:\SWOT\Data\FRF Hydro data\Barometer";
if ~isfolder(outDir), mkdir(outDir); end
outMat = fullfile(outDir, "baroFRF_airPressure_raw_20230701_20250201.mat");

base = "https://chldata.erdc.dren.mil/thredds/dodsC/frf/meteorology/barometer/derivedBarom";

t0 = datetime(2023,7,1,0,0,0,'TimeZone','UTC');
t1 = datetime(2025,2,1,23,59,59,'TimeZone','UTC');  % inclusive

mStart = dateshift(t0,'start','month');
mEnd   = dateshift(t1,'start','month');
mList  = (mStart : calmonths(1) : mEnd).';

% ---- IMPORTANT: initialize with UTC timezone ----
T_all = datetime.empty(0,1);
T_all.TimeZone = 'UTC';

P_all = [];                % raw mbar
Src   = strings(0,1);

fprintf("→ Pulling FRF derived barometer from THREDDS for %d months...\n", numel(mList));

for i = 1:numel(mList)
    yr = year(mList(i));
    mo = month(mList(i));
    yyyymm = sprintf("%04d%02d", yr, mo);

    url = base + "/" + sprintf("%04d", yr) + "/FRF-met_barometer_derivedBarom_" + yyyymm + ".nc";
    fprintf("  [%d/%d] %s\n", i, numel(mList), url);

    try
        % Make sure file exists and has expected variables
        info = ncinfo(url);
        vnames = string({info.Variables.Name});
        if ~any(strcmp(vnames,"time")) || ~any(strcmp(vnames,"airPressure"))
            warning("    Missing expected vars in %s (skipping)", yyyymm);
            continue;
        end

        % ---- Read time (POSIX seconds) ----
        tSec = double(ncread(url, "time"));
        fillT = getFill(url, "time");
        if ~isnan(fillT)
            tSec(tSec == fillT) = NaN;
        end

        % Force UTC no matter what MATLAB decides for this month
        t = datetime(tSec, 'ConvertFrom','posixtime');
        t.TimeZone = 'UTC';

        % ---- Read raw pressure (mbar) ----
        p = double(ncread(url, "airPressure"));
        fillP = getFill(url, "airPressure");
        if ~isnan(fillP)
            p(p == fillP) = NaN;
        end

        t = t(:);
        p = p(:);
        n = min(numel(t), numel(p));
        t = t(1:n);
        p = p(1:n);

        % Subset to requested range (NO QC/corrections)
        mask = (t >= t0) & (t <= t1);
        t = t(mask);
        p = p(mask);

        if isempty(t)
            continue;
        end

        % Append (now timezone-consistent)
        T_all = [T_all; t];
        P_all = [P_all; p];
        Src   = [Src; repmat(url, numel(t), 1)];

    catch ME
        warning("    Failed month %s: %s", yyyymm, ME.message);
    end
end

if isempty(T_all)
    error("No data pulled. Check connectivity and file availability.");
end

% Sort, raw only
[TT, ix] = sort(T_all);
P_all = P_all(ix);
Src   = Src(ix);

baroTT = timetable(TT, P_all, repmat("mbar", numel(TT), 1), Src, ...
    'VariableNames', {'airPressure_raw_mbar','airPressure_raw_units','source_file'});

fprintf("✓ Pulled %d samples total. Range: %s to %s (UTC)\n", ...
    height(baroTT), string(baroTT.TT(1)), string(baroTT.TT(end)));

save(outMat, "baroTT");
fprintf("✓ Saved MAT: %s\n", outMat);

% Optional CSV
outCsv = erase(outMat, ".mat") + ".csv";
writetimetable(baroTT, outCsv);
fprintf("✓ Wrote CSV: %s\n", outCsv);

%% ---------------- helper: read _FillValue if present ----------------
function fv = getFill(ncFile, varName)
    fv = NaN;
    try
        fv = double(ncreadatt(ncFile, varName, "_FillValue"));
    catch
        % leave NaN
    end
end
