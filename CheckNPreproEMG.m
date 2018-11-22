
%% EMG processing

%close all
clearvars

subject1 = '2_Luigi/EMG/';
file1 = 'LUIGI_TRIAL1.mat';

subject2 = '1_Miguel/EMG/';
file2 = 'trial3.mat';

luigi = load (strcat('/Users/mikel/Desktop/Data from GOOD experiments_1/',subject1,file1));
l = luigi.D.Data;
miguel = load (strcat('/Users/mikel/Desktop/Data from GOOD experiments_1/',subject2,file2));
m = miguel.D.Data;
disp('loaded');
set(0,'defaultfigurewindowstyle','docked');

clearvars -except l m
%%
%plot my signals 
for k = 8:23
    figure(k)
    %plot(D.Data(563956:662560,k))% pronation from Miguel
%   plot(D.Data(1500160:1602895,k));% pronation from Luigi
    if k<=15
        plot(l(1991030:2316705,k));% drink from Luigi
    else
        plot(m(1019390:1348900,k-8));% drink Miguel

    end
end


%% Frequency analysis by eye

fs = 2048;
Ts = 1/fs;

start = 1991030;
stop = 2316705;

z = 10;%emg number
x = l(start:stop,z);

samples = length(x);  % samples in a window

NFFT=2^(2+nextpow2(samples));%padding+computation speed

x_fl = fft(x,NFFT)/fs;%get fft
x_fl=abs(x_fl(1+(0:NFFT/2))); %only the first half 
fl = (0:NFFT/2)/NFFT*fs;

%--miguel
start = 1019390;
stop = 1348900;

z = 15;%emg number
x = m(start:stop,z);

samples = length(x);  % samples in a window

NFFT=2^(2+nextpow2(samples));%padding+computation speed

x_fm = fft(x,NFFT)/fs;%get fft
x_fm=abs(x_fm(1+(0:NFFT/2))); %only the first half 
fm = (0:NFFT/2)/NFFT*fs;

figure(80);plot(fm,x_fm)
figure(81);plot(fl,x_fl)%luigi

%periodogram, just in case
% [s,fm] = periodogram(x,[],[],fs);
% figure;plot(fm,s);

%% Notch filter for power line artifact removal (50 Hz)

d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',49,'HalfPowerFrequency2',51, ...
               'DesignMethod','butter','SampleRate',fs);
           
%fvtool(d,'Fs',fs)
y = filtfilt(d,x);
figure(100);plot(y)

%% Low pass at 500 Hz

lfc = 500;
nhfc = 2*Ts*lfc; %normalized cutoff freq.: nfc = fc/fnyq; fnyq = 1/2*fs=2*Ts

[b,a]=butter(2,nhfc,'low'); 
y1=filtfilt(b,a,y);

figure(101);plot(y1)