%% Reads mat files and stores them in a struct

myFolder = uigetdir('/Users/mikel/Desktop/');

filePattern = fullfile(myFolder, '*.mat');
matFiles = dir(filePattern);
for k = 1:length(matFiles)
  baseFileName = matFiles(k).name;
  fullFileName = fullfile(myFolder, baseFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
  AllData(k) = load(fullFileName);  %Data from all subjects
end