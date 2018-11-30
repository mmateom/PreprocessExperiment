function [] = emgImuSync(defpath,subjectName, loadPeaks)
%% EMG & IMU synchro

%INPUTS:
    % defpath: has the default path for all your folders realted to the experiment
    % subjecName: ejem...subjects' name
    % loadPeaks: 0-load synchro peaks manually; 1-I already have them, load them for me
    
%OUTPUTS: no outputs

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 

%% Load EMG and IMU data (must be in same folder)
disp('Select the folder with your data in the dialogue')
disp('Must have one .txt(imu) and one .mat(emg)')
pause(3)


mypath = uigetdir(defpath);%get path
if isequal(mypath,0)%check if path is correct
    warning('No folder selected');
    return;
end

f = [dir(fullfile(mypath,'*mat')); dir(fullfile(mypath,'*txt'))];
mon = {'s1','s2','s3'}; %select sensors to read MIGUEL
%mon = {'s1','s2','s3','s4','s5','s6'}; %select sensors to read MIKEL

for k = 1:length(f)
  baseFileName = f(k).name;
  fullFileName = fullfile(mypath, baseFileName);
  if ~iscell(fullFileName)
    fullFileName = {fullFileName};
  end

  [filepath,name,ext] = fileparts(fullFileName{1});
  switch ext
      case '.txt'
        disp('Reading IMU file...')
       imuData = readSatData2(fullFileName{1},mon,20);                   
      otherwise, emgData = load(fullFileName{1});  %Data from all subjects
          disp('Reading EMG file...')
                 
  end
end

disp('Loaded')
clearvars -except imuData emgData mon subjectName mypath defpath loadPeaks

%% Set some stuff

set(0,'defaultfigurewindowstyle','docked');
format long g %get rid of scientific notation
              
%% set fs
fs_imu = 100; %Miguel has an fs of 100 Hz
fs_emg = emgData.D.SamplingRate;%usually 2048 Hz

%% Load data matrices needed for synchro

imu_1 = imuData.(mon{1}).acc';%need only first IMU: Right-Wrist for synchro
t1  = imuData.(mon{1}).t;%need only first IMU: Right-Wrist
emg = emgData.D.Data;


%% Check if IMU has pretty constant fs

dt = diff(t1);
%figure;plot(dt);%10ms = 0.01s = 1/100Hz = 1/fs_imu;

%% Create time vectors

%Remember :P --> samples = time*fs 

%IMU: We can interpolate to get a better time vector taking into account drift factor

factor = 1.0006;
t_imuNoRes = (0:length(imu_1)-1)/fs_imu/60; % mins

%%interpolate t_imu with t1
t_imuRes = resample(t1*factor,t_imuNoRes');%milisecs
%get it in minutes
t_imu =(t_imuRes-t_imuRes(1))/1000/60; %from milisecs to secs to minutes
%figure;plot(t_imu,imu_1);

%EMG
t_emg = (0:length(emg)-1) / fs_emg /60; % Minutes

%% Get synchronization spikes from EMG and IMU - VISUALLY
if ~loadPeaks
    figure(1);title('IMU Sensor 1 acceleration: START');
    plot(t_imu,imu_1(:,1))
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartImu,~] = ginput(3);%3 spikes for start 

    figure(2);title('IMU Sensor 1 acceleration: STOP');
    plot(t_imu,imu_1(:,1))
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStopImu,~] = ginput(3);%3 spikes for stop 

    figure(3);title('EMG channel 1: START');
    plot(t_emg,emg(:,8));%take channel 1 from EMG
    xlim([0 40])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartEmg,~] = ginput(3);

    figure(4);title('EMG channel 1: STOP');
    plot(t_emg,emg(:,8));%take channel 1 from EMG
    xlim([0 40])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStopEmg,~] = ginput(3);

    %save the points
    yourFolder = [defpath,'/SyncPeaks'];
    if ~exist(yourFolder, 'dir')
       mkdir(yourFolder)
    end

    disp(['Saving synchro peaks in: ',yourFolder,'/'])
    filename = [subjectName,'_syncPks.mat'];
    disp(['File name: ',filename])
    save([yourFolder,'/',filename],'pksStartEmg','pksStartImu','pksStopEmg','pksStopImu')
    disp(['Look in: ',yourFolder, 'folder for your synced, raw data'])

end
%% Create new arrays

emg = [emg,t_emg'];%1st channel,labels,time vector
imu_1 = [imu_1,t_imu];

clearvars -except loadPeaks t_imu t_emg emg imu_1 fs_imu fs_emg imuData mon subjectName...
    pksStartEmg pksStartImu pksStopEmg pksStopImu defpath yourFolder

%% Calculate mean of points

%LOADS THE PEAKS IF STATED ABOVE
if loadPeaks
    yourFolder = [defpath,'/SyncPeaks'];
    load([yourFolder,'/',subjectName,'_syncPks.mat']);
end
%calculate mean of peaks
meanStartEmg = mean(pksStartEmg);
meanStartImu = mean(pksStartImu);

meanStopEmg = mean(pksStopEmg);
meanStopImu = mean(pksStopImu);
%%
%t_dif = abs(meanStartEmg-meanStartImu);

%para hacerlos con todas las variables de las
%matrices de emg e imu. Por ahora solo sincroniza
%canal 1 de emg con un IMU

%find nearest value of meanInd in time vector and get the index
%emg(:,end) has the time vector
%imu(:,4) has the time vector
%difemg is the lowest difference between time vector and meanInd,
%so I take that index: startIdx

[difStemg, startIdxEmg] = min(abs(emg(:,end)-meanStartEmg));
[difStimu, startIdxImu] = min(abs(imu_1(:,4)-meanStartImu));
[difSpemg, stopIdxEmg]  = min(abs(emg(:,end)-meanStopEmg));
[difSpimu, stopIdxImu]  = min(abs(imu_1(:,4)-meanStopImu));

%% Crop from the start index till stop index

emg = emg(startIdxEmg:stopIdxEmg,:);
imu_1 = imu_1(startIdxImu:stopIdxImu,:);

%new imu matrix with cropped signals
labelsImu = zeros(length(imu_1),1);%create labels column in imus;
statusImu = nan(length(imu_1),1);
t_imu = imu_1(:,end);
imu_1 = [imu_1(:,1:3),labelsImu,t_imu];
t_emg = emg(:,end);

%%
% figure(5);suptitle('Cropped signals. Displaying imu 1 and emg channel 1') 
% subplot(2,1,1);plot(t_imu,imu_1(:,1:3))
% subplot(2,1,2);plot(t_emg,emg(:,8))%channel 1
% pause(4)
% close all
%% IMU Labeling (I): Labels

labelsEmg = emg(:,5);%labels

%find the indeces where the difference between labels is not zero
transIdx = (find(diff(labelsEmg)~=0)+1)';%plus one because diff has length(labels)-1
emgTrans = t_emg(transIdx)';%relate indices with times of emg

Nmat = repmat(t_imu,[1 numel(emgTrans)]);%create a matrix to compare
[minval,indices] = min(abs(Nmat-emgTrans),[],1);%indices from imu.
                                        %te dice dónde ocurren las
                                        %transiciones en la time vector de
                                        %las imu
%closestvals = t_imuPrime(indices);

labelsImu(indices) = labelsEmg(transIdx);%relate labels from emg to corresponding
                                %indices in imus   

%assign labels to the rest of the indexes
    %for miguel: 1:63, for mikel: 1:59
for k = 1:numel(indices)
    
    j = k+1;
    
        if k == numel(indices) %I have to assign the last one manually cause idx is out of bound for labs
        labelsImu(indices(k):length(labelsImu)) = k;
        else, labelsImu(indices(k):indices(j)) = k;
        end

end
       
%% IMU Labeling (II): Status

statusEmg = emg(:,7);%status

%%find the indeces where the difference between labels is not zero
transStatusIdx = (find(diff(statusEmg)~=0)+1)';%plus one because diff has length(labels)-1
emgTransStatus = t_emg(transStatusIdx)';%relate indices with times of emg

Nsmat = repmat(t_imu,[1 numel(emgTransStatus)]);%create a matrix to compare
[minval,sindices] = min(abs(Nsmat-emgTransStatus),[],1);%indices from imu.
                                        %te dice dónde ocurren las
                                        %transiciones en la time vector de
                                        %las imu


statusImu(sindices) = statusEmg(transStatusIdx);%relate status from emg to corresponding
                                                %indices in imus   

%%assign status to the rest of the indexes

status = 1:numel(transStatusIdx);

statusImu(1:sindices(1)-1) = 5;
for k = 1:length(sindices)
    
    j = k+1;

        if k==length(sindices) %I have to assign the last one manually cause I need that status to go till the end
               statusImu(sindices(k):length(statusImu)) = statusImu(sindices(k));
        else,statusImu(sindices(k):sindices(j)-1) = statusImu(sindices(k));
        end
        

end
     
%% Synchronice the rest of the imus 


for s = 1:numel(mon)%number of sensors
    acc = imuData.(mon{s}).acc';
    gyr = imuData.(mon{s}).gyr';
    mag = imuData.(mon{s}).mag';
    q   = imuData.(mon{s}).q';
    
    %crop 
    acc = acc(startIdxImu:stopIdxImu,:);
    gyr = gyr(startIdxImu:stopIdxImu,:);
    mag = mag(startIdxImu:stopIdxImu,:);    
    q   = q(startIdxImu:stopIdxImu,:); 
    
    %create new struct
    imuData.(mon{s}).acc    = acc;
    imuData.(mon{s}).gyr    = gyr;
    imuData.(mon{s}).mag    = mag;
    imuData.(mon{s}).q      = q;
    imuData.(mon{s}).t      = t_imu;
    imuData.(mon{s}).labels = labelsImu;
    imuData.(mon{s}).status = statusImu;
    imuData.fs = fs_imu;
end

%new struct for emg data
emgData.data = emg(:,1:end-1);
emgData.t = emg(:,end);
emgData.fs = fs_emg;

clearvars -except imuData emgData subjectName defpath

disp('Magic! EMG and IMUs sychronized!')


%gonna save your data in the subjects folder
% cd (mypath)
% cd ../
yourFolder = [defpath,'/Step1_SyncedRawData'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving synced, raw data in: ',yourFolder])
filename = [subjectName,'_SyncedData.mat'];
disp(['File name: ',filename])
save([yourFolder,'/',filename],'imuData','emgData')  % function form
disp(['Look in: ',yourFolder, 'folder for your synced, raw data'])


