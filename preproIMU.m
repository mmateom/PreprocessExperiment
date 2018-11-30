%% IMU prepro

clear;clc;
set(0,'defaultfigurewindowstyle','docked');
%see: 60_PreproAllIMUDATA.pdf

%% SUBJECT NAME

subjectName = 'Luis';

%% Load files

defpath = '/Users/mikel/Desktop/Data from GOOD experiments_1/';
[FileName,PathName,~] = uigetfile(fullfile(defpath,'Step1_SyncedRawData/','*.mat'),'select file');
if isequal(FileName,0)
    warning('No file selected');
    return;
end
data = load(strcat(PathName,FileName));  %Data from all subjects

fs = data.imuData.fs;
Ts = 1/fs;%length of a sample

%% Load all sensors' imu data

s1 = struct2table(data.imuData.s1);
s2 = struct2table(data.imuData.s2);
s3 = struct2table(data.imuData.s3);

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
%figure(99);plot(fm,p);title('before filter freq')

%% High pass at 10 Hz

lfc = 10;
nhfc = 2*Ts*lfc; %normalized cutoff freq.: nfc = fc/fnyq; fnyq = 1/2*fs=2*Ts

[b,a]=butter(2,nhfc,'low'); 
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
%% Get activity windows

% LABELS:
%     0: null--> between activities
%     1: grey
%     2: GREEN
%     3: end of text --> after finishing an activity
%     4 & 5: before experiment starting
%     6: acknowledge

%Labels are the same in all sensors.
%Find the indices in s1 and and I can use them with the rest

idx = s1.status ==2;
s1 = s1(idx,:);s1.t = [];s1.q = [];s1.status = [];%get rid of time, quaternions and status
s2 = s2(idx,:);s2.t = [];s2.q = [];s2.status = [];%get rid of time, quaternions and status
s3 = s3(idx,:);s3.t = [];s3.q = [];s3.status = [];%get rid of time, quaternions and status

s = {s1,s2,s3};

clearvars -except s subjectName defpath

%% Calculate SMV of acc, gyr and mag (sqrt(ax^2+ay^2+az^2))

vars = {'acc','gyr','mag'};
func = @(x) sqrt(x(:,1).^2 + x(:,2).^2 + x(:,3).^2);
for i = 1:numel(s)
    smv = varfun(func,s{i}(:,vars));%returns table
    s{i}.smvAcc = smv{:,1};
    s{i}.smvGyr = smv{:,2};
    s{i}.smvMag = smv{:,3};
    
    %reorder table
    s{i}= [s{i}(:,2),s{i}(:,1),s{i}(:,3), s{i}(:,5:7), s{i}(:,4)];
    s{i}.Properties.VariableNames = ...
            {['acc',num2str(i)],['gyr',num2str(i)],['mag',num2str(i)],...
             ['smvAcc',num2str(i)],['smvGyr',num2str(i)],['smvMag',num2str(i)],...
             'labels'};
end

sf = innerjoin(s{1},s{2});

%s = [s{:,1},s{:,2},s{:,3}];

%Does the same as:
% C = s1.acc;
% D = sqrt(C(:,1).^2 + C(:,2).^2 + C(:,3).^2);
clearvars -except s subjectName defpath

%% Save data

%dataImu = [acc,gyr,mag,smvAcc,smvGyr,smvMag,labels];
name = [subjectName,'DataIMUPrepro'];

yourFolder = [defpath,'/Step2_Preprocessed_Data'];
if ~exist(yourFolder, 'dir')
   mkdir(yourFolder)
end

disp(['Saving preprocessed data in: ',yourFolder,'/'])
filename = [name,'.mat'];
disp(['File name: ',filename])
save([yourFolder,'/',filename],'dataImu')  % function form
disp(['Look in: ',yourFolder, '/ folder for your preprocessed data'])