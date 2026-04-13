%% compile_pupil_data.m

clear; close all
%% 1. Select master folder
masterFolder = uigetdir('', 'Select the Master Folder');
if isequal(masterFolder, 0)
    error('No folder selected. Script cancelled.');
end

%% 2. Get all subfolders in master folder (e.g. Ad1, Bd2, Cd3...)
contents   = dir(masterFolder);
subFolders = contents([contents.isdir] & ~strncmp({contents.name}, '.', 1));

%% 3. Loop through each subfolder
all_csCRavgs   = [];
all_baseCRavgs = [];
sessionLabels  = {};
all_crAmpMean = [];
all_baseCRavgs_cso = [];
all_csCRavgs_cso   = [];
all_crAmpMean_cso  = [];

all_priorBase_CR_cp  = [];
all_priorBase_noCR_cp = [];
all_priorCs_CR_cp    = [];
all_priorCs_noCR_cp  = [];
all_priorBase_CR_cso  = [];
all_priorBase_noCR_cso = [];
all_priorCs_CR_cso    = [];
all_priorCs_noCR_cso  = [];

all_baseSE_CR    = [];
all_baseSE_noCR  = [];
all_csSE_CR      = [];
all_csSE_noCR    = [];
all_baseSE_CR_cso   = [];
all_baseSE_noCR_cso = [];
all_csSE_CR_cso     = [];
all_csSE_noCR_cso   = [];

for i = 1:numel(subFolders)
    subPath = fullfile(masterFolder, subFolders(i).name);

    % Search recursively for baseline_averages.mat anywhere inside this subfolder
    matSearch = dir(fullfile(subPath, '**', 'baseline_averages.mat'));

    if isempty(matSearch)
        warning('No baseline_averages.mat found under: %s -- skipping.', subPath);
        continue;
    end
    if numel(matSearch) > 1
        warning('Multiple baseline_averages.mat found under: %s -- using first.', subPath);
    end

    matFile = fullfile(matSearch(1).folder, matSearch(1).name);
    ws      = load(matFile);

    if ~isfield(ws, 'csCRavgs') || ~isfield(ws, 'baseCRavgs')
        warning('Missing csCRavgs or baseCRavgs in: %s -- skipping.', matFile);
        continue;
    end

    all_crAmpMean = [all_crAmpMean; ws.crAmpMean];
    all_csCRavgs   = [all_csCRavgs;   ws.csCRavgs];
    all_baseCRavgs = [all_baseCRavgs; ws.baseCRavgs];
    all_baseCRavgs_cso = [all_baseCRavgs_cso; ws.baseCRavgs_cso];
    all_csCRavgs_cso   = [all_csCRavgs_cso;   ws.csCRavgs_cso];
    all_crAmpMean_cso  = [all_crAmpMean_cso;  ws.crAmpMean_cso];

    all_priorBase_CR_cp   = [all_priorBase_CR_cp;   mean(ws.priorBase_CR_cp,  'omitnan')];
    all_priorBase_noCR_cp = [all_priorBase_noCR_cp; mean(ws.priorBase_noCR_cp,'omitnan')];
    all_priorCs_CR_cp     = [all_priorCs_CR_cp;     mean(ws.priorCs_CR_cp,    'omitnan')];
    all_priorCs_noCR_cp   = [all_priorCs_noCR_cp;   mean(ws.priorCs_noCR_cp,  'omitnan')];
    all_priorBase_CR_cso   = [all_priorBase_CR_cso;   mean(ws.priorBase_CR_cso,  'omitnan')];
    all_priorBase_noCR_cso = [all_priorBase_noCR_cso; mean(ws.priorBase_noCR_cso,'omitnan')];
    all_priorCs_CR_cso     = [all_priorCs_CR_cso;     mean(ws.priorCs_CR_cso,    'omitnan')];
    all_priorCs_noCR_cso   = [all_priorCs_noCR_cso;   mean(ws.priorCs_noCR_cso,  'omitnan')];

    all_baseSE_CR      = [all_baseSE_CR;      std(ws.baseCR{1},    'omitnan') / sqrt(numel(ws.baseCR{1}))];
    all_baseSE_noCR    = [all_baseSE_noCR;    std(ws.baseCR{2},    'omitnan') / sqrt(numel(ws.baseCR{2}))];
    all_csSE_CR        = [all_csSE_CR;        std(ws.csCR{1},      'omitnan') / sqrt(numel(ws.csCR{1}))];
    all_csSE_noCR      = [all_csSE_noCR;      std(ws.csCR{2},      'omitnan') / sqrt(numel(ws.csCR{2}))];
    all_baseSE_CR_cso  = [all_baseSE_CR_cso;  std(ws.baseCR_cso{1},'omitnan') / sqrt(numel(ws.baseCR_cso{1}))];
    all_baseSE_noCR_cso= [all_baseSE_noCR_cso;std(ws.baseCR_cso{2},'omitnan') / sqrt(numel(ws.baseCR_cso{2}))];
    all_csSE_CR_cso    = [all_csSE_CR_cso;    std(ws.csCR_cso{1},  'omitnan') / sqrt(numel(ws.csCR_cso{1}))];
    all_csSE_noCR_cso  = [all_csSE_noCR_cso;  std(ws.csCR_cso{2},  'omitnan') / sqrt(numel(ws.csCR_cso{2}))];
    sessionLabels{end+1} = subFolders(i).name;

    fprintf('Loaded: %s\n', matFile);
end

sessNums = cellfun(@(s) str2double(regexp(s, '\d+', 'match', 'once')), sessionLabels);
fprintf('\nCompiled data from %d sessions.\n', numel(sessionLabels));

%% 4. Save to master folder
outputFile = fullfile(masterFolder, 'pupilCompiled.mat');
save(outputFile, 'all_csCRavgs', 'all_baseCRavgs', 'sessionLabels');
fprintf('Saved to:\n  %s\n', outputFile);

%% 5. Plot all_baseCRavgs
figure;
errorbar(sessNums, all_baseCRavgs(:,1), all_baseSE_CR, '-o', 'LineWidth', 1.5, ...
    'Color', [1 0 0], 'MarkerFaceColor', [1 0 0], 'CapSize', 5, 'DisplayName', 'CR');
hold on;
errorbar(sessNums, all_baseCRavgs(:,2), all_baseSE_noCR, '-o', 'LineWidth', 1.5, ...
    'Color', [0 0 0], 'MarkerFaceColor', [0 0 0], 'CapSize', 5, 'DisplayName', 'No CR');
hold off;
xlabel('Conditioning day');
ylabel('Average Pupil Width');
title('Baseline (0-200 ms)');
legend('Location', 'best');
xlim([min(sessNums)-1, max(sessNums)+1]);
xticks(sessNums);
xticklabels(arrayfun(@num2str, sessNums, 'UniformOutput', false));

%% 6. Plot all_csCRavgs
figure;
errorbar(sessNums, all_csCRavgs(:,1), all_csSE_CR, '-o', 'LineWidth', 1.5, ...
    'Color', [1 0 0], 'MarkerFaceColor', [1 0 0], 'CapSize', 5, 'DisplayName', 'CR');
hold on;
errorbar(sessNums, all_csCRavgs(:,2), all_csSE_noCR, '-o', 'LineWidth', 1.5, ...
    'Color', [0 0 0], 'MarkerFaceColor', [0 0 0], 'CapSize', 5, 'DisplayName', 'No CR');
hold off;
xlabel('Conditioning day');
ylabel('Average Pupil Width');
title('CS + trace (250-650 ms)');
legend('Location', 'best');
xlim([min(sessNums)-1, max(sessNums)+1]);
xticks(sessNums);
xticklabels(arrayfun(@num2str, sessNums, 'UniformOutput', false));


%% Compiled scatter: baseCRavgs vs CR amplitude
figure;
scatter(all_crAmpMean, all_baseCRavgs(:,1), 60, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(all_crAmpMean, all_baseCRavgs(:,1), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('Baseline (0-200 ms) vs CR Amplitude Paired Trials');
legend('Location', 'best');

%% Compiled scatter: csCRavgs vs CR amplitude
figure;
scatter(all_crAmpMean, all_csCRavgs(:,1), 60, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(all_crAmpMean, all_csCRavgs(:,1), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('CS + trace (250-650 ms) vs CR Amplitude Paired Trials');
legend('Location', 'best');

%% Compiled scatter: baseCRavgs_cso vs CR amplitude
figure;
scatter(all_crAmpMean_cso, all_baseCRavgs_cso(:,1), 60, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(all_crAmpMean_cso, all_baseCRavgs_cso(:,1), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('CS only -- Baseline (0-200 ms) vs CR Amplitude');
legend('Location', 'best');

%% Compiled scatter: csCRavgs_cso vs CR amplitude
figure;
scatter(all_crAmpMean_cso, all_csCRavgs_cso(:,1), 60, [1 0 0], 'filled', 'DisplayName', 'CR');
hold on;
plotFitLine(all_crAmpMean_cso, all_csCRavgs_cso(:,1), [1 0 0]);
hold off;
xlabel('CR Amplitude (CS\_PeakRel\_200\_630)');
ylabel('Average Pupil Width');
title('CS only -- CS + trace (250-650 ms) vs CR Amplitude');
legend('Location', 'best');

%% Prior pupil compiled plots

% CS only trial plots
figure; hold on;
validIdx = ~isnan(all_priorBase_CR_cso) & ~isnan(all_priorBase_noCR_cso);
for s = 1:numel(sessionLabels)
    if validIdx(s)
        plot([1 2], [all_priorBase_CR_cso(s), all_priorBase_noCR_cso(s)], '-o', ...
            'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.6 0.6 0.6]);
    end
end
mCR  = mean(all_priorBase_CR_cso(validIdx));
mNoCR = mean(all_priorBase_noCR_cso(validIdx));
seCR  = std(all_priorBase_CR_cso(validIdx))  / sqrt(sum(validIdx));
seNoCR = std(all_priorBase_noCR_cso(validIdx)) / sqrt(sum(validIdx));
errorbar([1 2], [mCR mNoCR], [seCR seNoCR], '-o', ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'MarkerFaceColor', [0 0 0], 'CapSize', 8);
xlim([0.5 2.5]); xticks([1 2]); xticklabels({'CR', 'No CR'});
ylabel('Average Pupil Width'); title('CS only -- Prior baseline (0-200 ms)');
hold off;

figure; hold on;
validIdx = ~isnan(all_priorCs_CR_cso) & ~isnan(all_priorCs_noCR_cso);
for s = 1:numel(sessionLabels)
    if validIdx(s)
        plot([1 2], [all_priorCs_CR_cso(s), all_priorCs_noCR_cso(s)], '-o', ...
            'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.6 0.6 0.6]);
    end
end
mCR   = mean(all_priorCs_CR_cso(validIdx));
mNoCR = mean(all_priorCs_noCR_cso(validIdx));
seCR  = std(all_priorCs_CR_cso(validIdx))  / sqrt(sum(validIdx));
seNoCR = std(all_priorCs_noCR_cso(validIdx)) / sqrt(sum(validIdx));
errorbar([1 2], [mCR mNoCR], [seCR seNoCR], '-o', ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'MarkerFaceColor', [0 0 0], 'CapSize', 8);
xlim([0.5 2.5]); xticks([1 2]); xticklabels({'CR', 'No CR'});
ylabel('Average Pupil Width'); title('CS only -- Prior CS+trace (250-650 ms)');
hold off;

%% CS paired trial plots
figure; hold on;
validIdx = ~isnan(all_priorBase_CR_cp) & ~isnan(all_priorBase_noCR_cp);
for s = 1:numel(sessionLabels)
    if validIdx(s)
        plot([1 2], [all_priorBase_CR_cp(s), all_priorBase_noCR_cp(s)], '-o', ...
            'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.6 0.6 0.6]);
    end
end
mCR    = mean(all_priorBase_CR_cp(validIdx));
mNoCR  = mean(all_priorBase_noCR_cp(validIdx));
seCR   = std(all_priorBase_CR_cp(validIdx))   / sqrt(sum(validIdx));
seNoCR = std(all_priorBase_noCR_cp(validIdx)) / sqrt(sum(validIdx));
errorbar([1 2], [mCR mNoCR], [seCR seNoCR], '-o', ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'MarkerFaceColor', [0 0 0], 'CapSize', 8);
xlim([0.5 2.5]); xticks([1 2]); xticklabels({'CR', 'No CR'});
ylabel('Average Pupil Width'); title('CS paired -- Prior baseline (0-200 ms)');
hold off;

figure; hold on;
validIdx = ~isnan(all_priorCs_CR_cp) & ~isnan(all_priorCs_noCR_cp);
for s = 1:numel(sessionLabels)
    if validIdx(s)
        plot([1 2], [all_priorCs_CR_cp(s), all_priorCs_noCR_cp(s)], '-o', ...
            'Color', [0.6 0.6 0.6], 'MarkerFaceColor', [0.6 0.6 0.6]);
    end
end
mCR    = mean(all_priorCs_CR_cp(validIdx));
mNoCR  = mean(all_priorCs_noCR_cp(validIdx));
seCR   = std(all_priorCs_CR_cp(validIdx))   / sqrt(sum(validIdx));
seNoCR = std(all_priorCs_noCR_cp(validIdx)) / sqrt(sum(validIdx));
errorbar([1 2], [mCR mNoCR], [seCR seNoCR], '-o', ...
    'Color', [0 0 0], 'LineWidth', 2.5, 'MarkerFaceColor', [0 0 0], 'CapSize', 8);
xlim([0.5 2.5]); xticks([1 2]); xticklabels({'CR', 'No CR'});
ylabel('Average Pupil Width'); title('CS paired -- Prior CS+trace (250-650 ms)');
hold off;
%%
save(outputFile, 'all_csCRavgs',     'all_baseCRavgs',     'all_crAmpMean', ...
                 'all_csCRavgs_cso', 'all_baseCRavgs_cso', 'all_crAmpMean_cso', ...
                 'all_priorBase_CR_cp',   'all_priorBase_noCR_cp', ...
                 'all_priorCs_CR_cp',     'all_priorCs_noCR_cp', ...
                 'all_priorBase_CR_cso',  'all_priorBase_noCR_cso', ...
                 'all_priorCs_CR_cso',    'all_priorCs_noCR_cso', ...
                 'sessionLabels');