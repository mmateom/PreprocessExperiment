function [] = emgImuSync(defpath1,subjectName, loadPeaks)
%% EMG & IMU synchro

%INPUTS:
    % defpath: has the default path for all your folders realted to the experiment
    % subjecName: ejem...subjects' name
    % loadPeaks: 0-load synchro peaks manually; 1-I already have them, load them for me
    
%OUTPUTS: look in Step1_SyncedRawData

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 

%% Load EMG and IMU data (must be in same folder)

%-----COMMENT this to use as a function of 'Main_PreproIMU.m'---------
% clear;clc;close all;
% defpath = 'D:\OneDrive - Universiteit Twente\2_Internship\All data\Data (ReadyForMatlab)';
% subjectName = 'Michelangelo';
% loadPeaks = 1;%do you already have the sync points? Put 1.
% 
% disp('Select the folder with your data in the dialogue')
% disp('Must have one .txt(imu) and one .mat(emg)')
%pause(1)

%YOU'LL NEED THIS IF YOU WANT TO SELECT FOLDERS MANUALLY 
%mypath = uigetdir(defpath);%get path
% if isequal(mypath,0)%check if path is correct
%     warning('No folder selected');
%     return;
% end
%------------------------------------------------------------------

defpath = [defpath1,'DataReadyForMatlab\',subjectName];

%I forget to tap in the end in some cases so say which case needs stopPks
switch subjectName
    case 'Miguel';stopPks = 0;
    case 'Luis' ;stopPks = 0;
    case 'Constantina' ;stopPks = 0;
    otherwise, stopPks = 1;
end

%------

f = [dir(fullfile(defpath,'*mat')); dir(fullfile(defpath,'*txt'))];

mon = {'s1','s2','s3','s4','s5','s6'}; %select sensors to read MIKEL

for k = 1:length(f)
  baseFileName = f(k).name;
  fullFileName = fullfile(defpath, baseFileName);
  if ~iscell(fullFileName)
    fullFileName = {fullFileName};
  end

  [filepath,name,ext] = fileparts(fullFileName{1});
  switch ext
      case '.txt'
        disp('Reading IMU file...')
       imuData = readSatData2(fullFileName{1},mon);                   
      otherwise, emgData = load(fullFileName{1});  %Data from all subjects
          disp('Reading EMG file...')
                 
  end
end

disp('Loaded')
%% Check emg
% 
figure(100)
subplot(3,1,1);plot(emgData.D.Data(:,7))
subplot(3,1,2);plot(emgData.D.Data(:,8))
subplot(3,1,3);plot(emgData.D.Data(:,9))

%%
clearvars -except imuData emgData mon subjectName mypath defpath loadPeaks stopPks

%% Set some stuff

set(0,'defaultfigurewindowstyle','docked');
format long g %get rid of scientific notation
              
%% set fs
fs_imu = 100; %check this in SampFreqSubjects.txt
fs_emg = emgData.D.SamplingRate;%usually 2048 Hz

%%Load data matrices needed for synchro

imuRaw = imuData.(mon{1}).acc';%need only first IMU: Right-Wrist for synchro
t1  = imuData.(mon{1}).t;%need only first IMU: Right-Wrist
emg = emgData.D.Data;


%% Check if IMU has pretty constant fs

dt = diff(t1);
figure;plot(dt);%example: 10ms = 0.01s = 1/100Hz = 1/fs_imu;
ylabel('diff between samples in Miliseconds')
%ylim([-100,100])
%% Create time vectors
% 
% %Remember :P --> samples = time*fs 
% 
%IMU: We can interpolate to get a better time vector taking into account drift factor

fs_resamp = 100; %new sampling frequency
factor = 1.00058;%drift factor
%factor = 0.99977;%drift factor
t = t1*factor;
dt = 1000*(1/fs_resamp);%milisecs*(1/fs_resamp)

tideal = t(1):dt:t(end);%ideally spaced time vector
imu_1 = interp1(t,imuRaw,tideal);%output: resampled data
t_imu = tideal/1000/60;%IMU vector in minutes

%EMG
t_emg = (0:length(emg)-1) / fs_emg /60; % Minutes

%% Get synchronization spikes from EMG and IMU - VISUALLY
if ~loadPeaks %if I don't already have them, let me pick them
    figure(1);
    plot(t_imu,imu_1(:,3))
    title('IMU Sensor 1 acceleration: START1')
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartImu1,~] = ginput(1);%3 spikes for start 
    figure(2);
    plot(t_imu,imu_1(:,3))
    title('IMU Sensor 1 acceleration: START2')
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartImu2,~] = ginput(1);%3 spikes for start
    if ~strcmp(subjectName,'Valerio')
    figure(3);
    plot(t_imu,imu_1(:,3))
    title('IMU Sensor 1 acceleration: START3')
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartImu3,~] = ginput(1);%3 spikes for start
    end
    if stopPks
        figure(4);
        plot(t_imu,imu_1(:,3))
        title('IMU Sensor 1 acceleration: STOP1')
        zoom on
        waitfor(gcf,'CurrentCharacter', char(13))
        zoom reset
        zoom off
        [pksStopImu1,~] = ginput(1);%3 spikes for stop 
                figure(5);
        plot(t_imu,imu_1(:,3))
        title('IMU Sensor 1 acceleration: STOP2')
        zoom on
        waitfor(gcf,'CurrentCharacter', char(13))
        zoom reset
        zoom off
        [pksStopImu2,~] = ginput(1);%3 spikes for stop
        if ~strcmp(subjectName,'Valerio')
        figure(6);
        plot(t_imu,imu_1(:,3))
        title('IMU Sensor 1 acceleration: STOP3')
        zoom on
        waitfor(gcf,'CurrentCharacter', char(13))
        zoom reset
        zoom off
        [pksStopImu3,~] = ginput(1);%3 spikes for stop
        end
    end
    figure(7);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: START1')
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartEmg1,~] = ginput(1);
        figure(8);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: START2')
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartEmg2,~] = ginput(1);
    if ~strcmp(subjectName,'Valerio')
    figure(9);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: START3');
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStartEmg3,~] = ginput(1);
    end
    if stopPks 
    figure(10);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: STOP1')
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStopEmg1,~] = ginput(1);
        figure(11);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: STOP2')
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStopEmg2,~] = ginput(1);
    if ~strcmp(subjectName,'Valerio')
    figure(12);
    plot(t_emg,emg(:,10));%take channel 1 from EMG
    title('EMG channel 1: STOP3')
    xlim([0 t_emg(end)])
    zoom on
    waitfor(gcf,'CurrentCharacter', char(13))
    zoom reset
    zoom off
    [pksStopEmg3,~] = ginput(1);
    end
    
    end
    %save the points
    yourFolder = [defpath,'\SyncPeaks'];
    if ~exist(yourFolder, 'dir')
       mkdir(yourFolder)
    end

if ~strcmp(subjectName,'Valerio')
pksStartImu = [pksStartImu1,pksStartImu2,pksStartImu3];  
pksStartEmg = [pksStartEmg1,pksStartEmg2,pksStartEmg3];
else
pksStartImu = [pksStartImu1,pksStartImu2];  
pksStartEmg = [pksStartEmg1,pksStartEmg2];
end
if stopPks && ~strcmp(subjectName,'Valerio')%Valerio takes only 2 points
pksStopImu = [pksStopImu1,pksStopImu2,pksStopImu3];
pksStopEmg = [pksStopEmg1,pksStopEmg2,pksStopEmg3];
else
    pksStopImu = [pksStopImu1,pksStopImu2];
    pksStopEmg = [pksStopEmg1,pksStopEmg2];
end

    disp(['Saving synchro peaks in: ',yourFolder,'\'])
    filename = [subjectName,'_syncPks.mat'];
    disp(['File name: ',filename])
    if stopPks
    save([yourFolder,'\',filename],'pksStartEmg','pksStartImu','pksStopEmg','pksStopImu')
    else
       save([yourFolder,'\',filename],'pksStartEmg','pksStartImu') 
    disp(['Look in: ',yourFolder, 'folder for your synced, raw data'])
    end
end
%% Create new arrays
labelsEmg = emg(:,7)+1;%labels.  Plus one to start labels from 1 instead from 0
emg = [emg(:,1:6),labelsEmg,emg(:,8:end),t_emg'];%1st channel,labels,time vector
imu_1 = [imu_1,t_imu'];

clearvars -except loadPeaks t_imu t_emg emg imu_1 fs_imu fs_emg imuData mon subjectName...
    pksStartEmg pksStartImu pksStopEmg pksStopImu defpath yourFolder stopPks t tideal

%% Calculate mean of points

%LOADS THE PEAKS IF STATED ABOVE
if loadPeaks
    yourFolder = [defpath,'\SyncPeaks'];
    load([yourFolder,'\',subjectName,'_syncPks.mat']);
end
%calculate mean of peaks
meanStartEmg = mean(pksStartEmg);
meanStartImu = mean(pksStartImu);

if stopPks
meanStopEmg = mean(pksStopEmg);
meanStopImu = mean(pksStopImu);
end
%check if EMG and IMU match
if stopPks
mImu = meanStopImu-meanStartImu
mEmg = meanStopEmg-meanStartEmg
(mImu-mEmg)*60%difference in seconds
else
    im4 = imu_1(:,4);
    im4(end)-meanStartImu
    c1 = emg(:,end);c1(end)-meanStartEmg
end
%% Find the index of the mean values
%find nearest value of meanInd in time vector and get the index
%emg(:,end) has the time vector
%imu(:,4) has the time vector
%difemg is the lowest difference between time vector and meanInd,
%so I take that index: startIdx

[difStemg, startIdxEmg] = min(abs(emg(:,end)-meanStartEmg));
[difStimu, startIdxImu] = min(abs(imu_1(:,4)-meanStartImu));
if stopPks
[difSpemg, stopIdxEmg]  = min(abs(emg(:,end)-meanStopEmg));
[difSpimu, stopIdxImu]  = min(abs(imu_1(:,4)-meanStopImu));
end


%% Crop from the start index till stop index
if stopPks
 
    emg = emg(startIdxEmg:stopIdxEmg,:);
    imu_1 = imu_1(startIdxImu:stopIdxImu,:);

else

    emg = emg(startIdxEmg:end,:);
    imu_1 = imu_1(startIdxImu:end,:);
end

%new imu matrix with cropped signals
labelsImu = nan(length(imu_1),1);%create labels column in imus;
statusImu = nan(length(imu_1),1);
t_imu = imu_1(:,end);
t_imu = t_imu-t_imu(1);%to cero
imu_1 = [imu_1(:,1:3),labelsImu,statusImu,t_imu];%**********
t_emg = emg(:,end);
t_emg = t_emg-t_emg(1);%to cero

%%
% figure(5);suptitle('Cropped signals. Displaying imu 1 and emg channel 1') 
% subplot(2,1,1);plot(t_imu,imu_1(:,1:3))
% subplot(2,1,2);plot(t_emg,emg(:,10))%channel 1
% pause(4)
%% True synchroniced EMG and IMU
figure(6);suptitle('Cropped signals. Displaying imu 1 and emg channel 1') 
subplot(2,1,1);plot(t_imu,imu_1(:,1:3))
subplot(2,1,2);plot(t_emg,emg(:,10))%channel 1

%close all
%% IMU Labeling (I): Labels

labelsEmg = emg(:,7);%labels.
statusEmg = emg(:,9);%status

%% Check transitions 

df = (diff(labelsEmg)~=0)*100;
df2 = [df',0];
figure;
plot(t_emg,labelsEmg)
hold on
plot(t_emg,statusEmg*10)

%% Now we're gonna remove unuseful repetitions,the ones that went wrong.
%I could've done a function for this as the code is almost the same for
%each subject...But "if it ain't broken, don't fix it".
%Unwanted repetitions are give a status '0'. In the next phase of the
%program everything that is not status '2' (useful data) will be removed.
%Also, it reasigns labels in the proper way. See excel file 'Activities and Labels'
%% socks rep 1 michelangelo

if strcmp(subjectName,'Michelangelo')
idx20 = find(labelsEmg == 20);
if any(diff(idx20)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx20)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last20 = idx20(idxRep)-1;%take the value of the idx where the big gap ends. Minus one becase is where the last label ends
                        %not where the 39 begins
statusEmg(idx20(1):last20) = 0;%assign status 0 to the repetition
end
end

%% Reasign labels for activities 20 and 21 (socks and tie shoes)
reps = [20,25];
idxsocks = find(labelsEmg == reps(1));
idxsockrep = find(labelsEmg == reps(2));
labelsEmg(idxsocks(1):idxsockrep(end))=20;%true label

reps = [26,28];
idxshoes = find(labelsEmg == reps(1));
idxshoesrep = find(labelsEmg == reps(2));
labelsEmg(idxshoes(1):idxshoesrep(end))=21;%true label
%now there's a jump from 21 to label 29. 

%Reasign rest of labels from 29 to 48 as 7 labels less
%example: 29-7 = 22, so now follows 

idx29 = find(labelsEmg == 29);%true label is 22
idx48 = find(labelsEmg == 48);%true labels is 41
restLabs = (labelsEmg(idx29(1):idx48(end)))-7;
labelsEmg(idx29(1):idx48(end)) = restLabs;
%48 now is 41. So now there's a transition between 41 to 49

%% making bed
if strcmp(subjectName,'Andrea')
idx30 = find(labelsEmg == 30);
if any(diff(idx30)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx30)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last30 = idx30(idxRep)-1;%take the value of the idx where the big gap ends. Minus one becase is where the last label ends
                        %not where the 39 begins
statusEmg(idx30(1):last30) = 0;%assign status 0 to the repetition
end
end

%% scrub windows
if strcmp(subjectName,'Valerio')
idx31 = find(labelsEmg == 31);
if any(diff(idx31)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx31)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last31 = idx31(idxRep)-1;%take the value of the idx where the big gap ends. Minus one becase is where the last label ends
                        %not where the 39 begins
statusEmg(idx31(1):last31) = 0;%assign status 0 to the repetition
end
end

%% washing hands rep
if strcmp(subjectName,'Luis')
idx39 = find(labelsEmg == 39);
if any(diff(idx39)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx39)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last39 = idx39(idxRep)-1;%take the value of the idx where the big gap ends. Minus one becase is where the last label ends
                        %not where the 39 begins
statusEmg(idx39(1):last39) = 0;%assign status 0 to the repetition
end
end

%% Mark not valid repetitions in running, if any
if strcmp(subjectName,'Luigi')||strcmp(subjectName,'Michelangelo')
idx40 = find(labelsEmg == 40);
if any(diff(idx40)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx40)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last40 = idx40(idxRep)-1;%take the value of the idx where the big gap ends
statusEmg(idx40(1):last40) = 0;%assign status 0 to the repetition
end
end

%% Mark not valid repetitions in JUMPING, if any
if strcmp(subjectName,'Mikel')
idx50 = find(labelsEmg == 50);
if any(diff(idx50)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx50)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last50 = idx50(idxRep)-1;%take the value of the idx where the big gap ends
statusEmg(idx50(1):last50) = 0;%assign status 0 to the repetition
end
end

%% Reasign jumping

reps = [49,50];
idxjump = find(labelsEmg == reps(1));
idxjumprep = find(labelsEmg == reps(2));
labelsEmg(idxjump(1):idxjumprep(end))=42;%true label
%now there's a jump from 42 to 51.

%plot(labelsEmg)

%Reasign rest of labels from 51 to 58 as 8 labels less
%example: 51-8 = 43, so now follows 

idx51 = find(labelsEmg == 51);%true label is 43
idx59 = find(labelsEmg == 59);%true labels is 51
restLabs = (labelsEmg(idx51(1):idx59(end)))-8;
labelsEmg(idx51(1):idx59(end)) = restLabs;

%% Mark not valid repetitions in cycling, if any
if strcmp(subjectName,'Luigi')
idx41start = idx40(end)+1;
idx42 = find(labelsEmg == 42);
if any(diff(idx42)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx42)>1);%index in the array of diff. 
last42 = idx42(idxRep);%take the value of the idx where the big gap ends.NOT MINUS ONE.
statusEmg(idx41start:last42) = 0;%assign status 0 to the repetition
end
end

%% Mark not valid repetitions in walking, if any
if strcmp(subjectName,'Luis')||strcmp(subjectName,'Andrea')||strcmp(subjectName,'Luigi')%luigi,andrea,luis
idx43 = find(labelsEmg == 43);
if any(diff(idx43)>1) %if there's a big jump in idx, means jumping is labeled twice, which means there's a repetition
idxRep = find(diff(idx43)>1)+1;%index in the array of diff. Plus one becase the big change is the next idx
last43 = idx43(idxRep)-1;%take the value of the idx where the big gap ends
statusEmg(idx43(1):last43) = 0;%assign status 0 to the repetition
end
end

%% find the indeces where the difference between labels is not zero
transIdx = (find(diff(labelsEmg)~=0)+1)';%plus one because diff has length(labels)-1
emgTrans = t_emg(transIdx)';%relate indices with times of emg

%% Check transitions agree

df = (diff(labelsEmg)~=0)*100;
df2 = [df',0];
figure;
plot(t_emg,labelsEmg)
hold on
plot(t_emg,statusEmg*10)
%plot(t_emg,df2);
% pause(4)
% line([emgTrans.' emgTrans.'],[0 100],'Color',[0 0 0])%black
%% IMU Labeling (I): Labels

Nmat = repmat(t_imu,[1 numel(emgTrans)]);%create a matrix to compare
[minval,indices] = min(abs(Nmat-emgTrans),[],1);%indices from imu.
                                        %te dice dónde ocurren las
                                        %transiciones en la time vector de
                                        %las imu
%closestvals = t_imuPrime(indices);

labelsImu(indices) = labelsEmg(transIdx);%relate labels from emg to corresponding
                                %indices in imus   

%% assign labels to the rest of the indexes
    %for miguel: 1:63, for mikel: 1:5X, depends on if I have repeated any
    %activity
    
labelsImu(1:indices(1)-1) = 1;   
for k = 1:numel(indices)
    
    j = k+1;
    
        if k == numel(indices) %I have to assign the last one manually cause idx is out of bound for labs
        labelsImu(indices(k):length(labelsImu)) = labelsImu(indices(k));
        else, labelsImu(indices(k):indices(j)-1) = labelsImu(indices(k));
        end

end
       
%% IMU Labeling (II): Status

%statusEmg = emg(:,9);%status DEFINED ABOVE.

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

%status = 1:numel(transStatusIdx);

statusImu(1:sindices(1)-1) = 5;
for k = 1:length(sindices)
    
    j = k+1;

        if k==length(sindices) %I have to assign the last one manually cause I need that status to go till the end
               statusImu(sindices(k):length(statusImu)) = statusImu(sindices(k));
        else,statusImu(sindices(k):sindices(j)-1) = statusImu(sindices(k));
        end
        

end
  
%% Check labelled IMUs correspong to EMG labelling

figure;plot(labelsImu)
hold on
plot(statusImu*10)
title('Sudden jump to 51 means data is missing')

%% Synchronice the rest of the imus 

for s = 1:numel(mon)%number of sensors
    acc = imuData.(mon{s}).acc';
    gyr = imuData.(mon{s}).gyr';
    mag = imuData.(mon{s}).mag';
    q   = imuData.(mon{s}).q';
    
    acc = interp1(t,acc,tideal);%output: resampled data
    gyr = interp1(t,gyr,tideal);%output: resampled data
    mag = interp1(t,mag,tideal);%output: resampled data
    q   = interp1(t,q,tideal);%output: resampled data
     
    if stopPks
    %crop 
        acc2 = acc(startIdxImu:stopIdxImu,:);
        gyr2 = gyr(startIdxImu:stopIdxImu,:);
        mag2 = mag(startIdxImu:stopIdxImu,:);    
        q2   = q(startIdxImu:stopIdxImu,:); 
    else 
        acc2 = acc(startIdxImu:end,:);
        gyr2 = gyr(startIdxImu:end,:);
        mag2 = mag(startIdxImu:end,:);    
        q2   = q(startIdxImu:end,:);
    end
    %create new struct
    imuDataSync.(mon{s}).acc    = acc2;
    imuDataSync.(mon{s}).gyr    = gyr2;
    imuDataSync.(mon{s}).mag    = mag2;
    imuDataSync.(mon{s}).q      = q2;
    imuDataSync.(mon{s}).t      = t_imu;
    imuDataSync.(mon{s}).labels = labelsImu;
    imuDataSync.(mon{s}).status = statusImu;
    imuDataSync.fs = 100;
end
%%
figure(6);suptitle('Cropped signals. Displaying imu 1 and emg channel 1') 
subplot(2,1,1);plot(t_imu,mag2(:,1))
subplot(2,1,2);plot(t_emg,emg(:,10))%channel 1


%% Save
%new struct for emg data
emgData.data = [emg(:,1:6),labelsEmg,emg(:,8),statusEmg,emg(:,end-1)];
emgData.t = t_emg;
emgData.fs = fs_emg;

%clearvars -except imuData emgData subjectName defpath

disp('Magic! EMG and IMUs sychronized!')


%gonna save your data in the subjects folder
% cd (mypath)
% cd ../
yourFolder = [defpath,'Step1_SyncedRawData'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving synced, raw data in: ',yourFolder])
filename = [subjectName,'_SyncedData.mat'];
disp(['File name: ',filename])
disp('Still saving...')
save([yourFolder,'\',filename],'imuDataSync','emgData')  % function form
disp(['Saved. Look in: ',yourFolder, 'folder for your synced, raw data'])


