%% === Fill AWAC-4.5m NaNs using sig940-400 from THREDDS ===
paths = setupPaths();

clear; clc;

load('timeVec.mat');
filePath = fullfile(paths.inSitu.hs, 'insituSWH_relevantInstrumentsAllProducts.mat');

S = load(filePath);

% === process HRpixc (main dataset) ===
[S.instrumentSWH_byTime_HRpixc] = fill_awac_from_thredds( ...
    S.instrumentSWH_byTime_HRpixc, ...
    timeVec);

% % OPTIONAL — apply to others
% if isfield(S,'instrumentSWH_byTime_L3_2km')
%     S.instrumentSWH_byTime_L3_2km = fill_awac_from_thredds( ...
%         S.instrumentSWH_byTime_L3_2km, ...
%         S.timeVec_L3_2km);
% end
% 
% if isfield(S,'instrumentSWH_byTime_LR2km')
%     S.instrumentSWH_byTime_LR2km = fill_awac_from_thredds( ...
%         S.instrumentSWH_byTime_LR2km, ...
%         S.timeVec_LR2km);
% end
% 
% if isfield(S,'instrumentSWH_byTime_HR100m')
%     S.instrumentSWH_byTime_HR100m = fill_awac_from_thredds( ...
%         S.instrumentSWH_byTime_HR100m, ...
%         S.timeVec_HR100m);
% end

save(filePath,'-struct','S');

fprintf('\n✓ Finished filling AWAC gaps using THREDDS sig940-400\n');


%% ================= HELPER FUNCTION =================
function T = fill_awac_from_thredds(T, timeVec)

vars = T.Properties.VariableNames;

awacCol = find(contains(lower(vars),'awac'),1);
if isempty(awacCol)
    error('AWAC column not found.');
end

awacVals = T{:,awacCol};

nanIdx = find(isnan(awacVals));

fprintf('→ Found %d AWAC NaNs to replace\n', numel(nanIdx));

% Start parallel pool if not active
if isempty(gcp('nocreate'))
    parpool;
end

replacementVals = NaN(size(nanIdx));

parfor k = 1:numel(nanIdx)
    i = nanIdx(k);
    thisTime = timeVec(i);

    try
        replacementVals(k) = getFrfWaveHeight_universal(thisTime,'sig940-400');
    catch
        replacementVals(k) = NaN;
    end
end

validFill = ~isnan(replacementVals);
awacVals(nanIdx(validFill)) = replacementVals(validFill);

T{:,awacCol} = awacVals;

fprintf('✓ Filled %d values from sig940-400\n', sum(validFill));

end