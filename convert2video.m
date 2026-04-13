% 1. Select the Master Folder (the one containing all trial_* folders)
masterPath = uigetdir();
if isequal(masterPath, 0), error('No folder selected.'); end

% --- NEW: Create a central output folder in the Master Directory ---
outputFolder = fullfile(masterPath, 'All_Videos');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
% -------------------------------------------------------------------

% 2. Get list of all 'trial_*' folders directly inside the Master Folder
trialFolders = dir(fullfile(masterPath, 'trial_*'));
trialFolders = trialFolders([trialFolders.isdir]);

if isempty(trialFolders)
    error('No folders starting with "trial_" were found in the selected directory.');
end

for k = 1:length(trialFolders)
    % Define the path to the current trial folder
    trialPath = fullfile(masterPath, trialFolders(k).name);
    
    % Look for JSON and BMP Images inside this specific trial folder
    jsonFiles = dir(fullfile(trialPath, '*.json'));
    imgFiles = dir(fullfile(trialPath, '*.bmp'));
    
    if isempty(jsonFiles) || isempty(imgFiles)
        fprintf('Skipping %s: Missing JSON or BMP files.\n', trialFolders(k).name);
        continue; 
    end
    
    % 3. Read the JSON to get Measured FPS
    jsonData = jsondecode(fileread(fullfile(trialPath, jsonFiles(1).name)));
    
    if isfield(jsonData, 'measured_fps')
        fps = jsonData.measured_fps;
    else
        % Fallback if measured is missing
        fps = jsonData.camera_reported_fps; 
        warning('measured_fps not found in %s, using reported.', trialFolders(k).name);
    end
    
    % 4. Define output path (SAVED INSIDE THE CENTRAL OUTPUT FOLDER)
    videoName = [trialFolders(k).name, '.avi'];
    videoPath = fullfile(outputFolder, videoName); % Changed from trialPath to outputFolder
    
    % Create Video Writer
    v = VideoWriter(videoPath, 'Motion JPEG AVI');
    v.FrameRate = fps;
    v.Quality = 95; 
    open(v);
    
    % Sort images numerically (Note: simple sort may fail if names are frame_1.bmp, frame_10.bmp)
    % For robust numeric sorting, consider using natsortfiles if you have it.
    [~, idx] = sort({imgFiles.name});
    imgFiles = imgFiles(idx);
    
    fprintf('Processing %s -> Saving to %s at %.4f FPS...\n', trialFolders(k).name, videoName, fps);
    
    for f = 1:length(imgFiles)
        img = imread(fullfile(trialPath, imgFiles(f).name));
        
        % Ensure 3-channel RGB (required for many video encoders)
        if size(img, 3) == 1
            img = cat(3, img, img, img);
        end
        
        writeVideo(v, img);
    end
    close(v);
end