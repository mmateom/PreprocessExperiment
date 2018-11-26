

%%
%mon = {'s1','s2','s3','s4','s5','s6'}; %s1 = sensor 1
mon = {'s1','s2','s3'}; %MIGUEL USA SOLO 3 SENSORES
% nomefile = 'AG_Trial_0_0.txt';
nomefile = 'Luis_Trial1_NoWeight_0.txt';

data = readSatData2(nomefile,mon,20);

nS = length(mon);
figure;

figure;
for s = 1:nS

    subplot(2,3,s); plot(data.(mon{s}).acc');
    
end
