function [ string ] = readDotNetString( fID )
nChars = fread(fID, 1, 'uint8');
format = sprintf('%%%dc',nChars);
string = fscanf(fID, format, 1);
end

