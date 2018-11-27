%% EMG & IMU syncro
clear;clc;
set(0,'defaultfigurewindowstyle','docked');


path = '/Users/mikel/Desktop/Data from GOOD experiments_1/';

%%%
fs_imu = 100; %Miguel has an fs of 100 Hz
fs_emg = 2048;

%% Plot 1st channels, where the synchro has been done
%IMUs

subject = '4_LuisMiguel/';
signal = 'IMU/';
file = 'Luis_Trial1_NoWeight_0.txt';

nomefile = strcat(path,subject,signal,file);%load the IMUs

% mon = {'s1','s2','s3','s4','s5','s6'}; %s1 = sensor 1
mon = {'s1','s2','s3'}; %MIGUEL SOLO USA 3 SENSORES

disp('loading IMU 1...')
data = readSatData2(nomefile,mon,20);
imu_1 = data.(mon{1}).acc';%need only first IMU: Right-Wrist
t1 = data.(mon{1}).t';%need only first IMU: Right-Wrist
disp('loaded')

% %% resample imu to constant fs
% 
% disp('Resampling IMU...')
% [imu,t_imu] = resample(imu_1(:,1),t1',fs_imu);
% disp('Resampled IMU')
%%
%EMG
subject = '4_LuisMiguel/';
signal = 'EMG/';
file = 'Luis_NoWeight_1.mat';

disp('loading EMG 1...')
sub = load (strcat(path,subject,signal,file));
emg = sub.D.Data;% I need all data to take the labels too
disp('loaded')

%plot both: get VISUALLY the index. 
%Store index in workspace from graph with right
%click --> Export cursor data

%samples = time*fs

t_imu = (1:length(imu_1)) / fs_imu /60; % Minutes
t_emg = (1:length(emg)) / fs_emg /60; % Minutes


figure(1)
plot(t_imu,imu_1)
figure(2)
plot(t_emg,emg(:,8));%take channel 1 from EMG

%create new arrays
emg = [emg(:,8),emg(:,5),t_emg'];%1st channel,labels,time vector
imu_1 = [imu_1,t_imu'];

clc;
%% Syncro
clearvars -except imu_1 emg fs_emg fs_imu
%get VISUALLY the time for each peack of both signals, they'll be different
%these are in minutes.

%start peaks
pkStart1emg = 0.3575;pkStart1imu = 1.3810;%en realidad 1.3810,pero 1 es min y 0.3810 son los segundos
pkStart2emg = 0.3896;pkStart2imu = 1.4140;
pkStart3emg = 0.4200;pkStart3imu = 1.4460;

%end peaks
pkStop1emg = 33.26;pkStop1imu = 35.70;
pkStop2emg = 33.28;pkStop2imu = 35.73;
pkStop3emg = 33.31;pkStop3imu = 35.75;

indStart_emg = [pkStart1emg,pkStart2emg,pkStart3emg];
indStart_imu = [pkStart1imu,pkStart2imu,pkStart3imu];
indStop_emg  = [pkStop1emg,pkStop2emg,pkStop3emg];
indStop_imu  = [pkStop1imu,pkStop2imu,pkStop3imu];

%%
clearvars -except imu_1 emg fs_emg fs_imu indStart_emg indStart_imu indStop_emg indStop_imu

%calculate mean of peaks
meanStartEmg = round(mean(indStart_emg),3);
meanStartImu = round(mean(indStart_imu),3);

meanStopEmg = round(mean(indStop_emg),3);
meanStopImu = round(mean(indStop_imu),3);
%%
%t_dif = abs(meanStartEmg-meanStartImu);

%para hacerlos con todas las variables de las
%matrices de emg e imu. Por ahora solo sincroniza
%canal 1 de emg con un IMU

%find nearest value of meanInd in time vector and get the index
%emg(:,3) has the time vector
%imu(:,4) has the time vector
%difemg is the lowest different between time vector and meanInd,
%so I take that index: startIdx

[difStemg, startIdxEmg] = min(abs(emg(:,3)-meanStartEmg));
[difStimu, startIdxImu] = min(abs(imu_1(:,4)-meanStartImu));
[difSpemg, stopIdxEmg]  = min(abs(emg(:,3)-meanStopEmg));
[difSpimu, stopIdxImu]  = min(abs(imu_1(:,4)-meanStopImu));

%% crop from the start index till the end

emg_prime = emg(startIdxEmg:stopIdxEmg,:);
imu_prime = imu_1(startIdxImu:stopIdxImu,:);

t_emg_prime = (1:length(emg_prime))/ fs_emg/60;%Minutes
t_imu_prime = (1:length(imu_prime))/fs_imu/60;%Minutes

figure;
plot(t_imu_prime,imu_prime(:,1:3))
figure;
plot(t_emg_prime,emg_prime(:,1))
clearvars -except imu_1 emg fs_emg fs_imu emg_prime imu_prime t_emg_prime t_imu_prime

%% IMU Labeling

%EMG is 2048 Hz and IMU 200 Hz:
% CÓMO ASIGNAR LAS LABELS EN DOS TIME VECTORS DIFERENTES?
% 
% una vez que el vector de tiempo del emg está relacionado con las labels,
% cojo el índice en el que empieza una label, ese índice contiene el
% tiempo en el que empieza.
% 
% ------------
% index    | 6
% -------------
% timeEMG  | 4.7
% ------------
% EMGs.....|...
% ------------
% label    | 2 = drinking
% ------------
% 
% 
% Si comparo (si calculo la diferencia de) ese timestamp con el todo el vector de
% tiempo del imu y cojo el índice que más se acerque a 0, significará
% que la label corresponde a ese time stamp en la imu
% 
% diff = abs(timeEMG-timeIMU) --> min(diff) gets the index that approaches 0
% 4.7-4.5 = 0.2 at idx 6 --> min(diff) = 6






