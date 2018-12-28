%% Get data ready for Processing
%This is the main program to get subjects data ready to plug
%into classification program. 

%%%%%%%%%%%ONLY IMU FOR NOW

%IMPORTANT:
%1.Put subjects' names in subjectName cell.
%2.Define the path where you have your subjects,
%each subject has a folder containing .mat (emg) and .txt (imu)
%3.Everything is done automatically from now on: emg and imu synchro and
%imu preprocessing and saving of data. Data obtained on each phase is stored in its
%corresponding file:
    %-After synchro on file: Step1_SyncedRawData
    %-After imu prepro on file: Step2_Preprocessed_Data
    %-After putting everything on a struct: Step3_ReadyToProcess

%4.If you have doubts, read each functions' definition
%5.Enjoy!

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 
%% 
clear;clc;

subjectName = {'Miguel'
'Mikel'
'Luis'
'Constantina'
'Leo'
'Luigi'
'Andrea'
'Michelangelo'
'Valerio'
% 'Marta'
% 'Martina'
'Debora'
};
           
numSubs = numel(subjectName);           
defpath = 'D:\OneDrive - Universiteit Twente\2_Internship\All data\';
loadPeaks = 1;%set to 1 to automatically load peak locations already obtained
              %if not, you'll have to get them manually
%%

for subs = 1:numSubs            
 %%Sync EMG with IMU 
%emgImuSync(defpath,subjectName{subs},loadPeaks);

%%Preprocess IMU 

preproIMU(defpath,subjectName{subs});
end

%% Put all data from all subjects in a struct

data2struct(defpath);
