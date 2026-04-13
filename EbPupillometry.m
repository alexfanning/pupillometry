% DLC Pupil Width Calculator
% Prompts user to select a folder, loops through all DLC CSV files,
% appends pupil_right_x - pupil_left_x as a new column in each CSV,
% then saves all results as a cell array in a .mat workspace file.

% Prompt user to select the master folder
master_folder = uigetdir('', 'Select the folder containing DLC CSV files');
if master_folder == 0
    disp('No folder selected. Exiting.');
    return;
end

% Find all CSV files in the folder
csv_files = dir(fullfile(master_folder, '*.csv'));
n_files = length(csv_files);

if n_files == 0
    error('No CSV files found in the selected folder.');
end

fprintf('Found %d CSV file(s). Processing...\n\n', n_files);

% Preallocate cell array to hold pupil width vectors (one per file)
% Rows = files, each cell holds a column vector of different length
pupil_width_all = cell(n_files, 1);
file_names      = cell(n_files, 1);

% Loop through each file
for i = 1:n_files
    filename = csv_files(i).name;
    filepath = fullfile(master_folder, filename);
    fprintf('Processing file %d/%d: %s\n', i, n_files, filename);

    try
        % Read the CSV — DLC files have 3 header rows (scorer, bodyparts, coords)
        raw = readcell(filepath);
        [n_raw_rows, n_raw_cols] = size(raw);

        % Row 2 = bodyparts, Row 3 = coords (x/y/likelihood)
        bodyparts = raw(2, 2:end);
        coords    = raw(3, 2:end);

        % Find column indices for pupil_right x and pupil_left x
        % (+1 offset because col 1 is the frame index column)
        pupil_right_x_col = find(strcmp(bodyparts, 'pupil_right') & strcmp(coords, 'x')) + 1;
        pupil_left_x_col  = find(strcmp(bodyparts, 'pupil_left')  & strcmp(coords, 'x')) + 1;

        if isempty(pupil_right_x_col) || isempty(pupil_left_x_col)
            warning('Could not find pupil_right x or pupil_left x in %s. Skipping.', filename);
            pupil_width_all{i} = [];
            file_names{i}      = filename;
            continue;
        end

        % Data rows start at row 4
        data_raw = raw(4:end, :);
        n_rows   = size(data_raw, 1);

        % Extract x values and compute difference
        pupil_right_x = cell2mat(data_raw(:, pupil_right_x_col));
        pupil_left_x  = cell2mat(data_raw(:, pupil_left_x_col));
        pupil_width   = pupil_right_x - pupil_left_x;

        % --- Append new column to the raw cell array ---
        new_col_idx = n_raw_cols + 1;

        % Header rows: label the new column clearly
        raw{1, new_col_idx} = 'DLC_processed';          % scorer row
        raw{2, new_col_idx} = 'pupil_width';             % bodyparts row
        raw{3, new_col_idx} = 'pupil_right_x-pupil_left_x'; % coords row

        % Fill data rows with computed values
        for r = 1:n_rows
            raw{r + 3, new_col_idx} = pupil_width(r);
        end

        % Write the modified cell array back to the same CSV file
        writecell(raw, filepath);

        % Store pupil width vector and filename for workspace
        pupil_width_all{i} = pupil_width;
        file_names{i}      = filename;

    catch ME
        warning('Error processing %s: %s', filename, ME.message);
        pupil_width_all{i} = [];
        file_names{i}      = filename;
    end
end

% --- Save workspace ---
% pupil_width_all : Nx1 cell array, each cell is a column vector of pupil widths
% file_names      : Nx1 cell array of corresponding filenames
workspace_path = fullfile(master_folder, 'pupil_width_workspace.mat');
save(workspace_path, 'pupil_width_all', 'file_names');

fprintf('\nDone!\n');
fprintf('Workspace saved to: %s\n', workspace_path);
fprintf('Variables saved:\n');
fprintf('  pupil_width_all  — %dx1 cell array of pupil width vectors\n', n_files);
fprintf('  file_names       — %dx1 cell array of corresponding filenames\n', n_files);