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



% s1 = [data.imuData.s1.acc,data.imuData.s1.gyr,data.imuData.s1.mag,...
%         data.imuData.s1.labels,data.imuData.s1.status];
% s2 = [data.imuData.s2.acc,data.imuData.s2.gyr,data.imuData.s2.mag,...
%         data.imuData.s2.labels,data.imuData.s2.status];
% s3 = [data.imuData.s3.acc,data.imuData.s3.gyr,data.imuData.s3.mag,...
%         data.imuData.s3.labels,data.imuData.s3.status];
    
s = {s1,s2,s3};
% s.s4 = [data.imuData.s4.acc,data.imuData.s4.gyr,data.imuData.s1.mag,...
%         data.imuData.s4.labels,data.imuData.s4.status];
% s.s5 = [data.imuData.s5.acc,data.imuData.s5.gyr,data.imuData.s2.mag,...
%         data.imuData.s5.labels,data.imuData.s5.status];
% s.s6 = [data.imuData.s6.acc,data.imuData.s6.gyr,data.imuData.s3.mag,...
%         data.imuData.s6.labels,data.imuData.s6.status];
%figure(1);plot(acc)

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

sensor1 = s{1,1};
idxStatus = find(sensor1.status==2);%find the indexes where status = 2

preWindowed = cell(1,3);

for tab = 1:numel(s)
      labels = s{tab}.labels(idxStatus,:);
      acc = s{tab}.acc(idxStatus,:);
      gyr = s{tab}.gyr(idxStatus,:);
      mag = s{tab}.mag(idxStatus,:);
      
      preWindowed{tab}=table(acc,gyr,mag,labels);
             
end

%% do I need to get each window?

idxLabels = find(diff(preWindowed{1}.labels)~=0)+1;%find when labels change

% numTabs = numel(preWindowed);%number of tables
% windowed = cell(length(idxLabels),numTabs);%number of windows 
%                                            %(should be number of labels)
% 
% for tab = 1:numTabs %for each table
%     windowed{1,tab} = preWindowed{tab}(1:idxLabels(1)-1,:);%table_n, from a to b give label y
%     for k = 1:length(idxLabels)%number of label changes
% 
%         w = k+1;
% 
%             if k == length(idxLabels) %I have to assign the last one manually cause idx is out of bound for labs
%             windowed{w,tab} =  preWindowed{tab}(idxLabels(k):height(preWindowed{tab}),:);
%             else, windowed{w,tab} = preWindowed{tab}(idxLabels(k):idxLabels(w)-1,:);
%             end
% 
%     end
% end

%% Detrend each window AND calculate SMV = sqrt(ax^2,ay^2,az^2)

numTabs = numel(preWindowed);%number of tables
detr = cell(1,numTabs);

acc = [];gyr = [];mag = [];
smvAcc = [];smvGyr = [];smvMag =[];

for tab = 1:numTabs
    accD = detrend(preWindowed{tab}.acc,'linear',idxLabels);   
    gyrD = detrend(preWindowed{tab}.gyr,'linear',idxLabels);
    magD = detrend(preWindowed{tab}.mag,'linear',idxLabels);
    smvAccD = sqrt(accD(:,1).^2 +accD(:,2).^2 +accD(:,3).^2);
    smvGyrD = sqrt(gyrD(:,1).^2 +gyrD(:,2).^2 +gyrD(:,3).^2);
    smvMagD = sqrt(magD(:,1).^2 +magD(:,2).^2 +magD(:,3).^2); 
    
    acc = [acc,accD];gyr = [gyr,gyrD];mag = [mag,magD];
    smvAcc = [smvAcc,smvAccD];smvGyr = [smvGyr,smvGyrD];smvMagD = [smvMag,smvMagD];

    

end


labels = preWindowed{1}.labels;

dataImu = [acc,gyr,mag,smvAcc,smvGyr,smvMag,labels];
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


%% if I wanna normalize here instead of in Main_IMU
% for tab = 1:numTabs
%     acc = normalize(detrend(preWindowed{tab}.acc,'linear',idxLabels),1);
%     gyr = normalize(detrend(preWindowed{tab}.gyr,'linear',idxLabels),1);
%     mag = normalize(detrend(preWindowed{tab}.mag,'linear',idxLabels),1);
%     
%     cleanImu{:,tab} = table(acc,gyr,mag,preWindowed{tab}.labels);
% end






