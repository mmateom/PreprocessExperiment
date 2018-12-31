%% IMU prepro
%function [] = preproIMU(defpath,subjectName)
clearvars -except defpath subjectName
clc;

%preproIMU: 
%   -low pass filters all acc, gyr and mag at 20 Hz. NOTE: if you want to 
%   see the result of the filtering to change the cutting freq to your preference,
%   you should anable the variable 'analysis' to '1'. If not, just set '0'.
%   -eliminates unusefull data and gets only the instances where the
%   activity was being performed.
%   -calculates smv of all acc, gyr and mag

% by Mikel Mateo - University of Twente - November 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 

%set(0,'defaultfigurewindowstyle','docked');
%see: 60_PreproAllIMUDATA.pdf

%% Load files

%--------------COMMENT THIS SECTION WHEN USING WITH Main_PreproIMU.m-------
% subjectName = 'Michelangelo';
% defpath = 'D:\OneDrive - Universiteit Twente\2_Internship\Everything\All data\';

% [FileName,PathName,~] = uigetfile(fullfile(defpath,'Step1_SyncedRawData\','*.mat'),'select file');
% if isequal(FileName,0)
%     warning('No file selected');
%     return;
% end
%--------------------------------------------------------------------------

PathName = [defpath,'Step1_SyncedRawData\'];
FileName = [subjectName,'_SyncedData'];
data = load(strcat(PathName,FileName));  %Data from all subjects

fs = data.imuDataSync.fs;
Ts = 1/fs;%length of a sample

%% Load all sensors' imu data in a table

s1 = struct2table(data.imuDataSync.s1);
s2 = struct2table(data.imuDataSync.s2);
s3 = struct2table(data.imuDataSync.s3);
s4 = struct2table(data.imuDataSync.s4);
s5 = struct2table(data.imuDataSync.s5);
s6 = struct2table(data.imuDataSync.s6);

analysis = 0;

if analysis
%% FFT analysis
% x = s.s1(:,1);
x = s1.acc(:,1);

samples = length(x);  % samples in a window
NFFT=2^(2+nextpow2(samples));%padding+computation speed

c_f = fft(x,NFFT)/fs;%get fft
c_f=abs(c_f(1+(0:NFFT/2))); %only the first half 
f = (0:NFFT/2)/NFFT*fs;


%periodogram, just in case
%[p,fm] = periodogram(x,[],[],fs);
figure(99);plot(f,c_f);title('before filter freq')

%% High pass at 20 Hz

lfc = 20;
nlfc = 2*Ts*lfc; %normalized cutoff freq.: nfc = fc/fnyq; fnyq = 1/2*fs=2*Ts

[b,a]=butter(2,nlfc,'low'); 
y=filtfilt(b,a,x);


%%
samples = length(y);  % samples in a window
NFFT=2^(2+nextpow2(samples));%padding+computation speed

c_f2 = fft(y,NFFT)/fs;%get fft
c_f2=abs(c_f2(1+(0:NFFT/2))); %only the first half 
f2 = (0:NFFT/2)/NFFT*fs;


figure(1);plot(x);title('before filter time')
figure(2);plot(f,c_f);title('before filter freq')
figure(3);plot(y);title('after filter time')
figure(4);plot(f2,c_f2);title('after filter freq')
end
%% Filter data

sRaw = {s1,s2,s3,s4,s5,s6};
sFilt = sRaw;%initialize sFilt

lfc = 20;%Hz
nlfc = 2*Ts*lfc; %normalized cutoff freq.: nfc = fc/fnyq; fnyq = 1/2*fs=2*Ts
[b,a]=butter(2,nlfc,'low'); 

vars = {'acc','gyr','mag'};
for k = 1:numel(sRaw)%for each sensors    
    for v = 1:numel(vars)%for each variable
       sFilt{k}{:,vars} = filtfilt(b,a,sRaw{k}{:,vars});
    end   
end

%% Get activity windows

% STATUS LABELS:
%     0: null--> between activities OR NOT VALID ACTIVITIES
%     1: grey
%     2: GREEN (useful data)
%     3: end of text --> after finishing an activity
%     4 & 5: before experiment starting
%     6: acknowledge
%so the only useful data is with status '2'

%Labels are the same in all sensors.
%Find the indices in s1 and and I can use them with the rest

s = sFilt;%initialize with same structure as sFilt

idx = sFilt{:,1}.status ==2;%get indices where status is 2. sFilt{:,1} = sensor1
labels = sFilt{:,1}(idx,end-1);%get labels from status idx in last row (where the labels are)

for sf = 1:numel(sFilt)%for all sensors
    s{:,sf} = sFilt{:,sf}(idx,:);%take samples where status is 2, so discard the rest, also invalid reps
    s{:,sf}(:,{'t','q','status','labels'})=[];%these variables are not usefull anymore
end

%s will be a cell with: 1 x number of sensors

clearvars -except s subjectName defpath labels

%% Calculate SMV of acc, gyr and mag (sqrt(ax^2+ay^2+az^2))

vars = {'acc','gyr','mag'};
func = @(x) sqrt(x(:,1).^2 + x(:,2).^2 + x(:,3).^2);
for i = 1:numel(s)
    smv = varfun(func,s{i}(:,vars));%returns table
    s{i}.smvAcc = smv{:,1};
    s{i}.smvGyr = smv{:,2};
    s{i}.smvMag = smv{:,3};
    
    %reorder table
    s{i}= [s{i}(:,2),s{i}(:,1),s{i}(:,3), s{i}(:,4:6)];
    s{i}.Properties.VariableNames = ...
            {['acc',num2str(i)],['gyr',num2str(i)],['mag',num2str(i)],...
             ['smvAcc',num2str(i)],['smvGyr',num2str(i)],['smvMag',num2str(i)]};
end

%create final table
dataIMULabeled = [s{:,1},s{:,2},s{:,3},labels];

clearvars -except dataIMULabeled subjectName defpath

%% Save data

%dataImu = [acc,gyr,mag,smvAcc,smvGyr,smvMag,labels];
name = [subjectName,'DataIMUPrepro'];

yourFolder = [defpath,'Step2_Preprocessed_Data'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving preprocessed data in: ',yourFolder])
filename = [name,'.mat'];
disp(['File name: ',filename])
save([yourFolder,'\',filename],'dataIMULabeled')  % function form
disp(['Look in: ',yourFolder, 'folder for your preprocessed data'])