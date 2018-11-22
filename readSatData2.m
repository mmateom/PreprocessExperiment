function mot = readSatData(filename, mon,limit,id)
% currently reading data from a specific imu log file


Nsat = length(mon);
 
indata = importdata(filename);
%indata = indata(1:3:end,:);
if nargin > 2
    if length(limit) == 1;
        indata = indata(limit(1):end,:);
    else
        indata = indata(limit(1):limit(2),:);
    end
end


for i = 1:Nsat %create struct: mot.(sensor number).(variable)

    mot.(mon{i}).t = indata(:,3);
    mot.(mon{i}).gyr = indata(:,9+(i-1)*14:11+(i-1)*14)'/16.4;
    mot.(mon{i}).acc = indata(:,6+(i-1)*14:8+(i-1)*14)'/2048;
    mot.(mon{i}).mag= indata(:,12+(i-1)*14:14+(i-1)*14)'/6.6667;
    
    mot.(mon{i}).q = indata(:,15+(i-1)*14:18+(i-1)*14)';
    if (nargin > 3)&&(id)
        tmp = indata(:,5+(i-1)*14);
        tmp = tmp(tmp ~= 0);
        mot.(mon{i}).ID = tmp(1);
    end

end


