%%%
%%% Programs needed: ReadSig,clearRepTrials2
%%% Needs: Raw data
%%% Creates: Separate file sX_sessionY_liftZ
%%% Does: Reads from the raw data and separates the trials, EMG filtered at
%%% [10 500], GF without filter
%%% Data downsampled to 2kHz
%%%
%%%

clc
clear
close all
%%
inicio = char(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'));
%%
format long g
[FileName,PathName,~] = uigetfile('*.dat','MultiSelect','on');

if isequal(FileName,0)
    warning('No file selected');
    return;
end

if ~iscell(FileName)
    FileName = {FileName};
end
%%
SampRate = 2048;
try
    for fileIdx = 1:numel(FileName)
        clearvars -except inicio fileIdx FileName PathName SampRate     
        
        fprintf([erase(FileName{fileIdx},'.dat') '...\n']);        
        %%
        fprintf('Detecting the header...\n')
        
        fID = fopen([PathName FileName{fileIdx}]);
        HEADSTART = readDotNetString(fID);
        if strcmp(HEADSTART,'HEADER_START')
            while 1
                HEADEND = readDotNetString(fID);
                if strcmp(HEADEND,'HEADER_END')
                    break;
                end
            end
        end
        
        % Reading the file from visual studio
        fprintf('Reading the Visual Studio file...\n');
        p = ftell(fID);
        L =   3 + 1 + 3 + 3 + (2 * 8) + 1;
        
        fseek(fID,p + 1,'bof');
        auxData(:,1:3) = fread(fID,[3,Inf],'3*char*1', L - 3)'; % Wrist
        fseek(fID,p + 1 + 3 + 1,'bof');
        q = fread(fID,[3,Inf],'3*char*1', L - 3)'; % Grasp
        auxData(1:size(q,1),4:6) = q;
        fseek(fID,p + 1 + 3 + 1 + 3,'bof');
        q = fread(fID,[3,size(auxData,1)],'3*uint8', L - 3)';  % Round, Rep and status
        auxData(1:size(q,1),7:9) = q;
        fseek(fID,p + 1 + 3 + 1 + 3 + 3,'bof');
        q = fread(fID,[8,size(auxData,1)],'8*int16', L - 8 * 2)'; % EMG7
        auxData(1:size(q,1),10:(10+8-1)) = q;
        
        %%
        x = (1:size(auxData,1)) / SampRate /60; % Minutes
        a = 4;
        b = 1;
        h(1) = subplot(a,b,1);
        plot(x,auxData(:,7))
        ylabel('Series')
        h(2) = subplot(a,b,2);
        plot(x,auxData(:,8))
        ylabel('Repetition')
        h(3) = subplot(a,b,3);
        plot(x,auxData(:,9))
        ylabel('Status')
        h(4) = subplot(a,b,4);
        for i = 1 : 8
            y = auxData(:,9+1);
            y = y - min(y); %normalizing
            y = y / max(y);
            y = y + (i-1) * 1.5;
            plot(x,y)
            hold on
        end
        ylabel('EMG')
        xlabel('Time [min]')
        linkaxes(h,'x');

        %
        fID = fclose(fID);
        
        %% Adjusting the data from the EMG Machine (bits to Volt)
        fprintf('Scaling the data...\n');        
        auxData(:,10:end) = auxData(:,10:end) * 5 /(2^12 * 500);
        
        %% Creating the main file
        D.Data = auxData;
        D.SamplingRate = SampRate;
        D.Channels = {'Wrist1','Wrist2','Hand1','Hand2','Series','Repetition','Status','EMG1','EMG2','EMG3','EMG4','EMG5','EMG6','EMG7','EMG8'};
        
        %% Synchronize EMG and IMU
        %% Clear useless data
        %% Filtering
        %% Splitting into trials
        %% Saving the file
        fprintf('Saving the files    %s...\n',[erase(FileName{fileIdx},'.dat')]);
        save([PathName erase(FileName{fileIdx},'_VS.dat')], 'D','-v7');
    end
    %%
    fprintf('FINITO :D\n');
    
catch errorInfo
    msg = ['Identifier: '  char(errorInfo.cause) 10 'Message: '  char(errorInfo.message) 10 ...
        'Cause: ' char(errorInfo.cause) 10 'Line: '  num2str(errorInfo.stack.line) 10 10 ...
        'Start: ' inicio 10 'End: ' char(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'))];
    error('Crashed, email sent %s',msg);
end
