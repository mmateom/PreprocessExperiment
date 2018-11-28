%% EMG & IMU syncro

clear;clc;
set(0,'defaultfigurewindowstyle','docked');
mypath = '/Users/mikel/Desktop/Data from GOOD experiments_1/';

%%%set freq
fs_imu = 100; %Miguel has an fs of 100 Hz
fs_emg = 2048;

loadPeaks = 1;%set to 1 to automatically load peak locations already obtained
              %if not, you'll have to get them manually

format long g %get rid of scientific notation

%% Load IMU data

subject_name = 'Luis';
subject = '4_LuisMiguel/';
signal = 'IMU/';
file = 'Luis_Trial1_NoWeight_0.txt';

nomefile = strcat(mypath,subject,signal,file);%load the IMUs

% mon = {'s1','s2','s3','s4','s5','s6'}; %s1 = sensor 1
mon = {'s1','s2','s3'}; %MIGUEL SOLO USA 3 SENSORES

disp('Loading IMU 1...')
imus = readSatData2(nomefile,mon,20);

imu_1 = imus.(mon{1}).acc';%need only first IMU: Right-Wrist for synchro
disp('Loaded')

%% Check if it has pretty constant fs

t1  = imus.(mon{1}).t;%need only first IMU: Right-Wrist
dt = diff(t1);
%figure;plot(dt);%10ms = 0.01s = 1/100Hz = 1/fs_imu;

%% We can interpolate to get a better time vector taking into account drift factor

factor = 1.0006;
t_imuNoRes = (1:length(imu_1))/fs_imu/60; % mins

%%interpolate t_imu with t1
t_imuRes = resample(t1*factor,t_imuNoRes');%milisecs
%get it in minutes
t_imu =(t_imuRes-t_imuRes(1))/1000/60; %from milisecs to secs to minutes
%figure;plot(t_imu,imu_1);
%% Load EMG data

subject = '4_LuisMiguel/';
signal = 'EMG/';
file = 'Luis_NoWeight_1.mat';

disp('Loading EMG 1...')
sub = load (strcat(mypath,subject,signal,file));
emg = sub.D.Data;% I need all data to take the labels too
disp('Loaded EMG')

%Remember :P --> samples = time*fs 

%create time vector for emg
t_emg = (1:length(emg)) / fs_emg /60; % Minutes

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

    save(strcat(subject_name,'_syncPks.mat'),'pksStartEmg','pksStartImu','pksStopEmg','pksStopImu')
end
%% Create new arrays
emg = [emg,t_emg'];%1st channel,labels,time vector
imu_1 = [imu_1,t_imu];

clearvars -except loadPeaks t_imu t_emg emg imu_1 fs_imu fs_emg imus mon subject_name...
    pksStartEmg pksStartImu pksStopEmg pksStopImu mypath


%% Calculate mean of points
%clearvars -except imu_1 emg fs_emg fs_imu indStart_emg indStart_imu indStop_emg indStop_imu subject_name

%LOADS THE PEAKS IF STATED ABOVE
if loadPeaks,load(strcat(subject_name,'_syncPks.mat'));end
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

%% crop from the start index till stop index

emgCrop = emg(startIdxEmg:stopIdxEmg,:);
imuCrop = imu_1(startIdxImu:stopIdxImu,:);

t_emgPrime = (1:length(emgCrop))/ fs_emg/60;%Minutes
t_imuPrime = (1:length(imuCrop))/fs_imu/60;%Minutes

%new matrix with cropped signals

labelsImu = zeros(length(imuCrop),1);%create labels column in imus;

emgPrime = [emgCrop(:,1:end-1),t_emgPrime'];
imuPrime = [imuCrop(:,1:3),labelsImu,t_imuPrime'];
%%
figure(5);suptitle('Cropped signals. Displaying imu 1 and emg channel 1') 
subplot(2,1,1);plot(t_imuPrime,imuCrop(:,1:3))
subplot(2,1,2);plot(t_emgPrime,emgCrop(:,8))%channel 1
pause(2)
close all
%% IMU Labeling
%clearvars -except imu_1 emg fs_emg fs_imu emgPrime imuPrime t_emgPrime t_imuPrime

labelsEmg = emgPrime(:,5);%labels

%find the indeces where the difference between labels is not zero
transIdx = find(diff(labelsEmg)~=0)+1;%plus one because diff has length(labels)-1
emgTrans = t_emgPrime(transIdx);%relate indices with times of emg

Nmat = repmat(t_imuPrime',[1 numel(emgTrans)]);%create a matrix to compare
[minval,indices] = min(abs(Nmat-emgTrans),[],1);%indices from imu.
                                        %te dice dónde ocurren las
                                        %transiciones en la time vector de
                                        %las imu
%closestvals = t_imuPrime(indices);

labelsImu(indices) = labelsEmg(transIdx);%relate labels from emg to corresponding
                                %indices in imus   

%assign labels to the rest of the indexes
labs = 1:63;%for miguel
%labs = 1:59;%for mikel
for k = 1:length(indices)-1
    
    j = k+1;
    
        if j==63 %I have to assign the last one manually cause idx is out of bound for labs
        labelsImu(indices(k):length(labelsImu)) = labs(63);
        else, labelsImu(indices(k):indices(j)) = labs(k);
        end

end
        

%% Synchronice the rest of the imus


for s = 1:numel(mon)%number of sensors
    acc = imus.(mon{s}).acc';
    gyr = imus.(mon{s}).gyr';
    mag = imus.(mon{s}).mag';
    q   = imus.(mon{s}).q';
    
    %crop 
    acc = acc(startIdxImu:stopIdxImu,:);
    gyr = gyr(startIdxImu:stopIdxImu,:);
    mag = mag(startIdxImu:stopIdxImu,:);    
    q   = q(startIdxImu:stopIdxImu,:); 
    
    imus.(mon{s}).acc    = acc;
    imus.(mon{s}).gyr    = gyr;
    imus.(mon{s}).mag    = mag;
    imus.(mon{s}).t      = t_imuPrime;
    imus.(mon{s}).labels = labelsImu;
end

emg = emgPrime;%assing proper name

clearvars -except imus emg subject_name mypath

disp('Magic! EMG and IMUs sychronized!')

%gonna save your data in the same folder
yourFolder = [mypath,'SyncData'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving data in: ',yourFolder,'/'])
filename = [subject_name,'_data.mat'];
disp(['File name: ',filename])
save([yourFolder,'/',filename],'imus','emg')  % function form
disp(['Look in: ',yourFolder, '/ folder for your synced data'])


