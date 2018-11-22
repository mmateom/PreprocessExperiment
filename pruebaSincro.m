
%% Prueba de sincronización imu + emg

imu = zeros(1,100);
imu(20) = 1;
imu(25) = 1;
imu(33) = 1;

twos = [40,41,42,43,44,45,46];
imu(twos) = 2;

g = [20,25,33];

m = mean(g);

emg = zeros(1,150);
emg(50) = 1;
emg(55) = 1;
emg(63) = 1;
twose = [40+30,42+30,44+30,46+30];
emg(twose) = 2;

h = [50,55,63];

m2 = mean(h);

imu2 = imu(:,m:end);
emg2 = emg(:,m2:end);
%%
% time_imu = 1:100;
% time_emg = 1:150;
% figure;
% plot(time_imu,imu,'r')
% figure;
% plot(time_emg,emg,'b')

%%

t_imu2 = 1:length(imu2);
t_emg2 = 1:length(emg2);

figure;
plot(t_imu2,imu2,'r')
figure;
plot(t_emg2,emg2,'b')