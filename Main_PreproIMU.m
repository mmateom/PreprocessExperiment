%% Get data ready for Processing
%This is the main program to get subjects data ready to plug
%into classification program. 

%%%%%%%%%%%ONLY IMU FOR NOW

%IMPORTANT:
%1.Put subjects' names in subjectName cell.
%2.Define the path where  you have your subjects,
%each subject has a folder containing .mat (emg) and .txt (imu)
%3.You'll have to select manually each subjects' folder when the dialogue
%box pops up
%4.If you have doubts, read each functions' definition
%5.Enjoy!

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 
%% 
clear;clc;

subjectName = {'JohnDoe',...
    };
           
numSubs = numel(subjectName);           
defpath = '/Users/mikel/Desktop/Data from GOOD experiments_1/';
loadPeaks = 1;%set to 1 to automatically load peak locations already obtained
              %if not, you'll have to get them manually
%

for subs = 1:numSubs            
 %% Sync EMG with IMU 
emgImuSync(defpath,subjectName{subs},loadPeaks);

%% Preprocess IMU 

preproIMU(defpath,subjectName{subs});
end

%% Put all data from all subjects in a struct

data2struct(defpath);
