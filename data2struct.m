%% Reads mat files and stores them in a struct
function [] = data2struct(defpath) 

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 


clearvars -except defpath
clc;

%defpath = '/Users/mikel/Desktop/Data from GOOD experiments_1/';
%myFolder = uigetdir(defpath);

myFolder = [defpath,'/Step2_Preprocessed_Data/'];

filePattern = fullfile(myFolder, '*.mat');
matFiles = dir(filePattern);

for k = 1:length(matFiles)
  seFileName = matFiles(k).name;
  fullFileName = fullfile(myFolder, seFileName);
  fprintf(1, 'Now reading %s\n', fullFileName);
  allData(k) = load(fullFileName);  %Data from all subjects in a struct 
end

%% From table to matrix

allSubjects = [];

for k = 1:numel(allData)
    
    eachSubject = allData(k).dataIMULabeled;%can do it with table2array but I wanna see if table is OK.
    allSubjects = [allSubjects;eachSubject{:,:}];
    
end

%% Create struct

varNames = {
            'acc1x','acc1y','acc1z',...
            'gyr1x','gyr1y','gyr1z',...
            'mag1x','mag1y','mag1z',...            
            'smvAcc1','smvGyr1','smvMag1',...
            'acc2x','acc2y','acc2z',...
            'gyr2x','gyr2y','gyr2z',...
            'mag2x','mag2y','mag2z',...
            'smvAcc2','smvGyr2','smvMag2'...
            'acc3x','acc3y','acc3z',...          
            'gyr3x','gyr3y','gyr3z',...
            'mag3x','mag3y','mag3z',...
            'smvAcc3','smvGyr3','smvMag3',...
            'labels'};

dataIMUS.sensorData = allSubjects;
dataIMUS.varNames = varNames;

%% Save data

name = 'dataIMUS';

yourFolder = [defpath,'/Step3_ReadyToProcess'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving data in: ',yourFolder,'/'])
filename = [name,'.mat'];
disp(['File name: ',filename])
save([yourFolder,'/',filename],'dataIMUS')  % function form
disp(['Look in: ',yourFolder, 'folder for your data ready to classify'])
