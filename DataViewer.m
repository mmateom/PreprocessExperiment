

%%
clear;clc;
mon = {'s1','s2','s3','s4','s5','s6'}; %s1 = sensor 1
%mon = {'s1','s2','s3'}; %MIGUEL USA SOLO 3 SENSORES
% nomefile = 'AG_Trial_0_0.txt';
nomefile = 'Martina_Trial1.txt';

%data = readSatData2(nomefile,mon,1);
data = readSatData2(nomefile,mon);
%%
nS = length(mon);

figure(2);
for s = 1:nS

    subplot(2,3,s); plot(data.(mon{s}).acc');
    
end
