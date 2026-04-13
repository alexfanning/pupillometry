% =========================================================================
% compute_baseline_avg.m
%
% Loads pupil_width_all from the 'All_Videos' folder workspace, determines
% the first-200-ms frame range from the 'eyeblink_summary.xlsx' Traces tab,
% subtracts 9 frames from the end of that range, then computes the mean of
% those frames for each trial and stores all results in 'baseAvg'.
% The result is saved as a new .mat workspace in the master folder.
%
% Based on the actual eyeblink_summary.xlsx:
%   - Frames sampled at ~3.33 ms intervals (row 2 = 0 ms, row 3 = 3.33 ms, ...)
%   - Frame 60 (1-based) = 199.08 ms  --> last frame <= 200 ms
%   - Frame range used: 1:60, then minus 9 --> 1:51
% =========================================================================

clear; close all

%% 1. Ask the user to select the master folder
masterFolder = uigetdir('', 'Select the Master Folder');
if isequal(masterFolder, 0)
    error('No folder selected. Script cancelled.');
end

%% Create pupilAnalyses output folder
figFolder = fullfile(masterFolder, 'pupilAnalyses');
if ~exist(figFolder, 'dir')
    mkdir(figFolder);
end

%% 2. Build paths
allVideosFolder = fullfile(masterFolder, 'All_Videos');
matFile         = fullfile(allVideosFolder, 'pupil_width_workspace.mat');
xlsxFile        = fullfile(masterFolder,   'eyeblink_summary.xlsx');
outputFile      = fullfile(masterFolder,   'baseline_averages.mat');

% Verify files exist
if ~isfile(matFile)
    error('Could not find pupil_width_workspace.mat in:\n  %s', allVideosFolder);
end
if ~isfile(xlsxFile)
    error('Could not find eyeblink_summary.xlsx in:\n  %s', masterFolder);
end

%% 3. Determine the 200-ms frame range from the Traces tab
% Read the Time_ms column from the Traces sheet (row 1 = header, skip it)
fprintf('Reading eyeblink_summary.xlsx ...\n');
timeMs = readmatrix(xlsxFile, ...
    'Sheet',     'Traces', ...
    'Range',     'A2:A10000', ...
    'OutputType','double');

% Drop any NaN rows (readmatrix pads with NaN if range exceeds data)
timeMs = timeMs(~isnan(timeMs));

% Find the last frame whose time is <= 200 ms
lastFrame200 = find(timeMs <= 200, 1, 'last');
if isempty(lastFrame200)
    error('No time values <= 200 ms found in the Traces sheet Time_ms column.');
end

% Subtract 9 frames from the end of the range
frameStart = 1;
frameEnd   = lastFrame200 - 9;

if frameEnd < frameStart
    error(['After subtracting 9 frames the end index (%d) is less than the ' ...
           'start index (%d). Check your Time_ms column.'], frameEnd, frameStart);
end

fprintf('200-ms boundary: frame %d (%.2f ms)\n', lastFrame200, timeMs(lastFrame200));
fprintf('Using frames %d to %d (%.2f ms to %.2f ms, after subtracting 9).\n', ...
    frameStart, frameEnd, timeMs(frameStart), timeMs(frameEnd));

%% 4. Load the workspace
fprintf('Loading pupil_width_workspace.mat ...\n');
ws              = load(matFile);
pupil_width_all = ws.pupil_width_all;

nTrials = numel(pupil_width_all);
fprintf('Number of trials found: %d\n', nTrials);

%% 5. Compute the baseline average for each trial
baseAvg = nan(nTrials, 1);

for i = 1:nTrials
    trialData = double(pupil_width_all{i});   % ensure numeric; column vector
    nFrames   = numel(trialData);

    if nFrames < frameEnd
        % Trial is shorter than expected -- use what's available and warn
        warning('Trial %d has only %d frames (expected >= %d). Using frames %d:%d.', ...
            i, nFrames, frameEnd, frameStart, nFrames);
        baselineFrames = trialData(frameStart : nFrames);
    else
        baselineFrames = trialData(frameStart : frameEnd);
    end

    baseAvg(i) = mean(baselineFrames, 'omitnan');
end

grandMean = mean(baseAvg, 'omitnan');

%% 7. Load CS_paired tab and identify CS_HoldOk trials

% Read TrialName and CS_HoldOk columns (skip row 1 header, skip row 2 SUMMARY)
trialNames = readcell(xlsxFile, 'Sheet', 'CS_paired', 'Range', 'A3:A1000');
holdOk     = readcell(xlsxFile, 'Sheet', 'CS_paired', 'Range', 'K3:K1000');

validRows  = cellfun(@(x) ischar(x) || isstring(x), trialNames);
trialNames = trialNames(validRows);
holdOk     = holdOk(validRows);

trialNums = cellfun(@(s) str2double(regexp(s, '\d+', 'match', 'once')) + 1, trialNames);

% Separate into TRUE and FALSE groups
isTrue  = cellfun(@(x) isequal(x, true) || isequal(x, 1), holdOk);
isFalse = ~isTrue;

trueIdx  = trialNums(isTrue);
falseIdx = trialNums(isFalse);

%% 8. Build baseCR and baseCRavgs
baseCR     = cell(1, 2);
baseCR{1}  = baseAvg(trueIdx);   % CS_HoldOk == TRUE
baseCR{2}  = baseAvg(falseIdx);  % CS_HoldOk == FALSE

baseCRavgs = [mean(baseCR{1}, 'omitnan'), mean(baseCR{2}, 'omitnan')];

fprintf('CS_HoldOk TRUE  trials: %d  --> baseCRavgs(1) = %.6f\n', numel(trueIdx),  baseCRavgs(1));
fprintf('CS_HoldOk FALSE trials: %d  --> baseCRavgs(2) = %.6f\n', numel(falseIdx), baseCRavgs(2));

%% 10. Identify 250-650 ms frame range from Time_ms
% From eyeblink_summary.xlsx Traces tab:
%   Frame 75  = 249.43 ms  --> first frame >= 250 ms is frame 76
%   Frame 193 = 648.48 ms  --> last frame  <= 650 ms is frame 193

csStart = find(timeMs >= 250, 1, 'first');
csEnd   = find(timeMs <= 650, 1, 'last') - 9;

fprintf('250-650 ms window: frames %d (%.2f ms) to %d (%.2f ms)\n', ...
    csStart, timeMs(csStart), csEnd, timeMs(csEnd));

%% 11. Compute per-trial averages over 250-650 ms
csAvg = nan(nTrials, 1);

for i = 1:nTrials
    trialData = double(pupil_width_all{i});
    nFrames   = numel(trialData);

    if nFrames < csEnd
        warning('Trial %d has only %d frames (expected >= %d). Using frames %d:%d.', ...
            i, nFrames, csEnd, csStart, nFrames);
        csFrames = trialData(csStart : nFrames);
    else
        csFrames = trialData(csStart : csEnd);
    end

    csAvg(i) = mean(csFrames, 'omitnan');
end

%% 12. Grand mean of 250-650 ms averages
csMean = mean(csAvg, 'omitnan');

%% 13. Split by CS_HoldOk
csCR      = cell(1, 2);
csCR{1}   = csAvg(trueIdx);   % CS_HoldOk == TRUE
csCR{2}   = csAvg(falseIdx);  % CS_HoldOk == FALSE

csCRavgs  = [mean(csCR{1}, 'omitnan'), mean(csCR{2}, 'omitnan')];

crAmpRaw = readmatrix(xlsxFile, 'Sheet', 'CS_paired', 'Range', 'G3:G1000');
crAmpRaw = crAmpRaw(~isnan(crAmpRaw));  % drop NaN padding

% Map to full trial index
crAmpFull = nan(nTrials, 1);
for i = 1:numel(trialNums)
    if trialNums(i) <= nTrials
        crAmpFull(trialNums(i)) = crAmpRaw(i);
    end
end

crAmpMean = mean(crAmpFull, 'omitnan');

%% Per-session scatter: baseAvg vs CR amplitude
figure;
scatter(crAmpFull(trueIdx),  baseAvg(trueIdx),  40, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(crAmpFull(trueIdx),  baseAvg(trueIdx),  [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
ylim([0 60])
title('Baseline (0-200 ms) vs CR Amplitude');
legend('Location', 'best');

saveas(gcf, fullfile(figFolder, 'CSp_baseline_vs_CRamp.fig'));

%% Per-session scatter: csAvg vs CR amplitude
figure;
scatter(crAmpFull(trueIdx),  csAvg(trueIdx),  40, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(crAmpFull(trueIdx),  csAvg(trueIdx),  [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
ylim([0 60])
title('CS + trace (250-650 ms) vs CR Amplitude');
legend('Location', 'best');

saveas(gcf, fullfile(figFolder, 'CSp_CStrace_vs_CRamp.fig'));

%% 18. Save with crAmpMean included
save(outputFile, 'baseAvg', 'grandMean', 'baseCR', 'baseCRavgs', ...
                 'csAvg',   'csMean',    'csCR',   'csCRavgs',   ...
                 'crAmpFull', 'crAmpMean', ...
                 'frameStart', 'frameEnd', 'csStart', 'csEnd');
fprintf('Done. Saved to:\n  %s\n', outputFile);

%% 14. Save everything
save(outputFile, 'baseAvg', 'grandMean', 'baseCR', 'baseCRavgs', ...
                 'csAvg',   'csMean',    'csCR',   'csCRavgs',   ...
                 'frameStart', 'frameEnd', 'csStart', 'csEnd');


%% 19. CS_only tab -- read trial names, HoldOk, and CR amplitude
fprintf('Reading CS_only sheet...\n');

trialNames_cso = readcell(xlsxFile, 'Sheet', 'CS_only', 'Range', 'A3:A1000');
holdOk_cso     = readcell(xlsxFile, 'Sheet', 'CS_only', 'Range', 'K3:K1000');
crAmpRaw_cso   = readmatrix(xlsxFile, 'Sheet', 'CS_only', 'Range', 'G3:G1000');

% Drop empty/padding rows
validRows_cso  = cellfun(@(x) ischar(x) || isstring(x), trialNames_cso);
trialNames_cso = trialNames_cso(validRows_cso);
holdOk_cso     = holdOk_cso(validRows_cso);
crAmpRaw_cso   = crAmpRaw_cso(1:sum(validRows_cso));

% Parse trial numbers (zero-indexed in name --> 1-based MATLAB index)
trialNums_cso  = cellfun(@(s) str2double(regexp(s, '\d+', 'match', 'once')) + 1, trialNames_cso);

% CR amplitude mapped to trial index
crAmpFull_cso  = nan(nTrials, 1);
for i = 1:numel(trialNums_cso)
    if trialNums_cso(i) <= nTrials
        crAmpFull_cso(trialNums_cso(i)) = crAmpRaw_cso(i);
    end
end
crAmpMean_cso = mean(crAmpFull_cso, 'omitnan');

% TRUE/FALSE indices
isTrue_cso  = cellfun(@(x) isequal(x, true) || isequal(x, 1), holdOk_cso);
isFalse_cso = ~isTrue_cso;
trueIdx_cso  = trialNums_cso(isTrue_cso);
falseIdx_cso = trialNums_cso(isFalse_cso);

%% 20. baseCR and baseCRavgs for CS_only
baseCR_cso    = cell(1, 2);
baseCR_cso{1} = baseAvg(trueIdx_cso);
baseCR_cso{2} = baseAvg(falseIdx_cso);
baseCRavgs_cso = [mean(baseCR_cso{1}, 'omitnan'), mean(baseCR_cso{2}, 'omitnan')];

fprintf('CS_only HoldOk TRUE  (baseline): %d trials --> %.6f\n', numel(trueIdx_cso),  baseCRavgs_cso(1));
fprintf('CS_only HoldOk FALSE (baseline): %d trials --> %.6f\n', numel(falseIdx_cso), baseCRavgs_cso(2));

%% 21. csCR and csCRavgs for CS_only
csCR_cso    = cell(1, 2);
csCR_cso{1} = csAvg(trueIdx_cso);
csCR_cso{2} = csAvg(falseIdx_cso);
csCRavgs_cso = [mean(csCR_cso{1}, 'omitnan'), mean(csCR_cso{2}, 'omitnan')];

fprintf('CS_only HoldOk TRUE  (CS+trace): %d trials --> %.6f\n', numel(trueIdx_cso),  csCRavgs_cso(1));
fprintf('CS_only HoldOk FALSE (CS+trace): %d trials --> %.6f\n', numel(falseIdx_cso), csCRavgs_cso(2));

%% 22. Per-session scatter: baseAvg vs CR amplitude (CS_only)
figure;
scatter(crAmpFull_cso(trueIdx_cso),  baseAvg(trueIdx_cso),  40, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(crAmpFull_cso(trueIdx_cso), baseAvg(trueIdx_cso), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('CS only -- Baseline (0-200 ms) vs CR Amplitude');
legend('Location', 'best');

saveas(gcf, fullfile(figFolder, 'CSo_baseline_vs_CRamp.fig'));

%% 23. Per-session scatter: csAvg vs CR amplitude (CS_only)
figure;
scatter(crAmpFull_cso(trueIdx_cso),  csAvg(trueIdx_cso),  40, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(crAmpFull_cso(trueIdx_cso), csAvg(trueIdx_cso), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('CS only -- CS + trace (250-650 ms) vs CR Amplitude');
legend('Location', 'best');

saveas(gcf, fullfile(figFolder, 'CSo_CStrace_vs_CRamp.fig'));

%% 25. CR on next trial predicted by current trial pupil width (CS_paired)

% Build predictor (trial i) and outcome (trial i+1) vectors
% Using trialNums_paired (already 1-based) sorted in trial order
[sortedTrials_cp, sortIdx_cp] = sort(trialNums);
holdOkFull_cp = false(nTrials, 1);
holdOkFull_cp(trialNums(isTrue)) = true;

% Shift: predictor = trial i, outcome = trial i+1
predBase_cp = baseAvg(sortedTrials_cp(1:end-1));
predCs_cp   = csAvg(sortedTrials_cp(1:end-1));
nextCR_cp   = holdOkFull_cp(sortedTrials_cp(2:end));

% Remove NaNs
validBase_cp = ~isnan(predBase_cp) & ~isnan(nextCR_cp);
validCs_cp   = ~isnan(predCs_cp)   & ~isnan(nextCR_cp);

% --- Logistic regression + binned plot: baseline vs next CR (CS_paired) ---
figure;
plotLogisticWithBins(predBase_cp(validBase_cp), nextCR_cp(validBase_cp), 5, [0.2 0.2 0.8]);
xlabel('Baseline Pupil Width (0-200 ms)');
ylabel('P(CR on next trial)');
title('CS paired -- Baseline pupil predicting next trial CR');

saveas(gcf, fullfile(figFolder, 'CSp_baseline_nextCR.fig'));

% --- Logistic regression + binned plot: CS+trace vs next CR (CS_paired) ---
figure;
plotLogisticWithBins(predCs_cp(validCs_cp), nextCR_cp(validCs_cp), 5, [0.2 0.2 0.8]);
xlabel('CS+trace Pupil Width (250-650 ms)');
ylabel('P(CR on next trial)');
title('CS paired -- CS+trace pupil predicting next trial CR');

saveas(gcf, fullfile(figFolder, 'CSp_CStrace_nextCR.fig'));

%% 26. CR on next trial predicted by current trial pupil width (CS_only)
[sortedTrials_cso, ~] = sort(trialNums_cso);
holdOkFull_cso = false(nTrials, 1);
holdOkFull_cso(trialNums_cso(isTrue_cso)) = true;

predBase_cso = baseAvg(sortedTrials_cso(1:end-1));
predCs_cso   = csAvg(sortedTrials_cso(1:end-1));
nextCR_cso   = holdOkFull_cso(sortedTrials_cso(2:end));

validBase_cso = ~isnan(predBase_cso) & ~isnan(nextCR_cso);
validCs_cso   = ~isnan(predCs_cso)   & ~isnan(nextCR_cso);

% --- Logistic regression + binned plot: baseline vs next CR (CS_only) ---
figure;
plotLogisticWithBins(predBase_cso(validBase_cso), nextCR_cso(validBase_cso), 5, [0.8 0.2 0.2]);
xlabel('Baseline Pupil Width (0-200 ms)');
ylabel('P(CR on next trial)');
title('CS only -- Baseline pupil predicting next trial CR');

saveas(gcf, fullfile(figFolder, 'CSo_baseline_nextCR.fig'));

% --- Logistic regression + binned plot: CS+trace vs next CR (CS_only) ---
figure;
plotLogisticWithBins(predCs_cso(validCs_cso), nextCR_cso(validCs_cso), 5, [0.8 0.2 0.2]);
xlabel('CS+trace Pupil Width (250-650 ms)');
ylabel('P(CR on next trial)');
title('CS only -- CS+trace pupil predicting next trial CR');

saveas(gcf, fullfile(figFolder, 'CSo_CStrace_nextCR.fig'));

%% 25. Prior trial pupil width split by whether current trial is CR or not

% CS_paired
[sortedTrials_cp, ~] = sort(trialNums);
holdOkFull_cp = false(nTrials, 1);
holdOkFull_cp(trialNums(isTrue)) = true;

% For each trial i+1, grab pupil from trial i
priorBase_cp = baseAvg(sortedTrials_cp(1:end-1));
priorCs_cp   = csAvg(sortedTrials_cp(1:end-1));
currentCR_cp = holdOkFull_cp(sortedTrials_cp(2:end));

% Split by CR outcome
priorBase_CR_cp    = priorBase_cp(currentCR_cp  & ~isnan(priorBase_cp));
priorBase_noCR_cp  = priorBase_cp(~currentCR_cp & ~isnan(priorBase_cp));
priorCs_CR_cp      = priorCs_cp(currentCR_cp    & ~isnan(priorCs_cp));
priorCs_noCR_cp    = priorCs_cp(~currentCR_cp   & ~isnan(priorCs_cp));

fprintf('CS_paired -- Prior baseline:  CR trials = %.4f, No CR trials = %.4f\n', ...
    mean(priorBase_CR_cp), mean(priorBase_noCR_cp));
fprintf('CS_paired -- Prior CS+trace:  CR trials = %.4f, No CR trials = %.4f\n', ...
    mean(priorCs_CR_cp), mean(priorCs_noCR_cp));

% CS_only
[sortedTrials_cso, ~] = sort(trialNums_cso);
holdOkFull_cso = false(nTrials, 1);
holdOkFull_cso(trialNums_cso(isTrue_cso)) = true;

priorBase_cso = baseAvg(sortedTrials_cso(1:end-1));
priorCs_cso   = csAvg(sortedTrials_cso(1:end-1));
currentCR_cso = holdOkFull_cso(sortedTrials_cso(2:end));

priorBase_CR_cso   = priorBase_cso(currentCR_cso  & ~isnan(priorBase_cso));
priorBase_noCR_cso = priorBase_cso(~currentCR_cso & ~isnan(priorBase_cso));
priorCs_CR_cso     = priorCs_cso(currentCR_cso    & ~isnan(priorCs_cso));
priorCs_noCR_cso   = priorCs_cso(~currentCR_cso   & ~isnan(priorCs_cso));

fprintf('CS_only -- Prior baseline:  CR trials = %.4f, No CR trials = %.4f\n', ...
    mean(priorBase_CR_cso), mean(priorBase_noCR_cso));
fprintf('CS_only -- Prior CS+trace:  CR trials = %.4f, No CR trials = %.4f\n', ...
    mean(priorCs_CR_cso), mean(priorCs_noCR_cso));

%% 26. Save
save(outputFile, 'baseAvg', 'grandMean', 'baseCR', 'baseCRavgs', ...
                 'csAvg',   'csMean',    'csCR',   'csCRavgs',   ...
                 'crAmpFull',     'crAmpMean', ...
                 'baseCR_cso',    'baseCRavgs_cso', ...
                 'csCR_cso',      'csCRavgs_cso', ...
                 'crAmpFull_cso', 'crAmpMean_cso', ...
                 'priorBase_CR_cp',  'priorBase_noCR_cp', ...
                 'priorCs_CR_cp',    'priorCs_noCR_cp', ...
                 'priorBase_CR_cso', 'priorBase_noCR_cso', ...
                 'priorCs_CR_cso',   'priorCs_noCR_cso', ...
                 'frameStart', 'frameEnd', 'csStart', 'csEnd');
fprintf('Done. Saved to:\n  %s\n', outputFile);