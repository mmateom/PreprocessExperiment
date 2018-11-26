%% EMG & IMU syncro
clear;clc;
set(0,'defaultfigurewindowstyle','docked');


path = '/Users/mikel/Desktop/Data from GOOD experiments_1/';

%%%THIS WILL CHANGE DEPENDING ON THE SUBJECT BECAUSE fs IS NOT PERFECT
fs_imu = 100;
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
disp('loaded. Resampling IMU...')

%resample imu to constant fs

[imu,t_imu] = resample(imu_1,t1,fs_imu);
disp('Resampled IMU')
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


t_imu = (1:length(imu_1)) / fs_imu /60; % Minutes
t_emg = (1:length(emg)) / fs_emg /60; % Minutes


figure(1)
plot(t_imu,imu_1)
figure(2)
plot(t_emg,emg(:,8));%take channel 1 from EMG

emg = [emg(:,8),t_emg'];
imu_1 = [imu_1,t_imu'];




clc;
%% Syncro

%get VISUALLY the time for each peack of both signals, they'll be different
%these are in minutes.

% t = hours(7.6)
% t = 
%   duration
%    7.6 hr
% >> t.Format = 'hh:mm:ss'
% t = 
%   duration
%    07:36:00
peak1emg = 0.3575;peak1imu = 0.3810;
peak2emg = 0.3896;peak2imu = 0.4140;
peak3emg = 0.4200;peak3imu = 0.4460;

t1emg = hours(0) + minutes(0) + seconds(peak1emg*60);
t2emg = hours(0) + minutes(0) + seconds(peak2emg*60);
t3emg = hours(0) + minutes(0) + seconds(peak3emg*60);

t1imu = hours(0) + minutes(1) + seconds(peak1imu*60);
t2imu = hours(0) + minutes(1) + seconds(peak2imu*60);
t3imu = hours(0) + minutes(1) + seconds(peak3imu*60);

ind_emg = [t1emg,t2emg,t3emg];
ind_imu = [t1imu,t2imu,t3imu];

for i = 1:numel(ind_emg)
    dummy_emg = ind_emg(i);dummy_emg.Format  = 'hh:mm:ss.SS';
    dummy_imu = ind_imu(i);dummy_imu.Format  = 'hh:mm:ss.SS';
    ind2_emg(:,i) = dummy_emg;
    ind2_imu(:,i) = dummy_imu;  
end
%%
clearvars -except imu_1 emg fs_emg fs_imu ind2_emg ind2_imu

%calculate mean of peaks
meanIndEmg = floor(mean(ind2_emg),'seconds');
meanIndImu = floor(mean(ind2_imu),'seconds');



%%
t_dif = abs(meanIndEmg-meanIndImu);

%------modificar de aquí para abajo---
%para hacerlos con todas las variables de las
%matrices de emg e imu. Por ahora solo sincroniza
%canal 1 de emg con un IMU

emg_prime = emg(:,meanIndEmg:end);
imu_prime = imu_1(:,meanIndImu:end);

% t_imu_prime = 1:length(imu2);
% t_emg_prime = 1:length(emg2);
% 
% figure;
% plot(t_imu_prime,imu_prime,'r')
% figure;
% plot(t_emg_prime,emg_prime,'b')

%----------------modificar de aquí para arriba
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
% abs(timeEMG-timeIMU) --> get the index that approaches 0
% 4.7-4.5 = 0.2




