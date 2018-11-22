%% EMG & IMU syncro
clear;clc;
set(0,'defaultfigurewindowstyle','docked');


path = '/Users/mikel/Desktop/Data from GOOD experiments_1/';

%%%THIS WILL CHANGE DEPENDING ON THE SUBJECT BECAUSE fs IS NOT PERFECT
fs_imu = 200;
fs_emg = 2048;

%% Plot 1st channels, where the synchro has been done
%IMUs

subject = '1_Miguel/';
signal = 'IMU/';
file = 'Miguel.txt';

nomefile = strcat(path,subject,signal,file);%load the IMUs

mon = {'s1','s2','s3','s4','s5','s6'}; %s1 = sensor 1

disp('loading IMU 1...')
data = readSatData2(nomefile,mon,20);
imu_1 = data.(mon{1}).acc';%need only first IMU: Right-Wrist
disp('loaded')


%EMG
subject = '1_Miguel/';
signal = 'EMG/';
file = 'trial3.mat';

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

%clearvars -except imu_1 emg
clc;
%% Syncro

%get VISUALLY the index of both signals, they'll be different
%ind_emg = [peak1emg,peak2emg,peak3emg];
%ind_imu = [peak1imu,peak2imu,peak3imu];

%calculate mean of peaks
meanIndEmg = mean(ind_emg);
meanIndImu = mean(ind_imu);


t_dif = abs(meanIndEmg-meanIndImu);

%------modificar de aquí para abajo---
%para hacerlos con todas las variables de las
%matrices de emg e imu

emg_prime = emg(:,meanIndEmg:end);
imu_prime = imu(:,meanIndImu:end);

t_imu_prime = 1:length(imu2);
t_emg_prime = 1:length(emg2);

figure;
plot(t_imu_prime,imu_prime,'r')
figure;
plot(t_emg_prime,emg_prime,'b')

%----------------modificar de aquí para arriba
%% IMU Labeling

%EMG is 2048 Hz and IMU 200 Hz:
CÓMO ASIGNAR LAS LABELS EN DOS TIME VECTORS DIFERENTES?

una vez que el vector de tiempo del emg está relacionado con las labels,
cojo el índice en el que empieza una label, ese índice contiene el
tiempo en el que empieza.

------------
index    | 6
-------------
timeEMG  | 4.7
------------
EMGs.....|...
------------
label    | 2 = drinking
------------


Si comparo (si calculo la diferencia de) ese timestamp con el todo el vector de
tiempo del imu y cojo el índice que más se acerque a 0, significará
que la label corresponde a ese time stamp en la imu

abs(timeEMG-timeIMU) --> get the index that approaches 0
4.7-4.5 = 0.2




