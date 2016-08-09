function X=getValue(data,id,columnNum,isstring,alsocontains)
%% Retreive data from an ascii vector where each line starts with a '$<id>'
% 
%  Input:
%   data: 1xM: vector of characters read with fileread(filename) command
%   id: 1xN: vector of characters that identify the id
%   columnNum: 1 {int}: index of the column number of data to retreive
%   isstring: boolean: return value as a string or double?
%   alsocontains: 1xP : vector of characters that also must be in each line
%
%  Output:
%   X: 1xQ : vector of all output data found, eith as string or double
%
%  Example:
%   data = fileread('test.txt');
%   X = getValue(data,'$MSG',5,1,'$GPGGA');

%% Handle Inputs
columnNum=columnNum+1;
numchars=length(id);
if nargin==3
    isstring=0;
    alsocontains=0;
end
if nargin==4
    alsocontains=0;
end
%% Find End of lines, and determine if that line met the search criteria
ind=[0 strfind(data,char(10))];
NumX=0; %count number of X values found
for i=1:length(ind)-1
    linestring=data(ind(i)+1:ind(i+1)-2);
    if strcmp(linestring(1:numchars),id) && ...
            (~isempty(strfind(linestring,alsocontains)) || ...
            sum(alsocontains)==0)
        NumX=NumX+1; 
    end
end
%% Preallocate
if isstring
    X=cell(1,NumX);
else
    X=nan(1,NumX);
end
count=0;
%% Search through each line and populate data if it matches the id 
for i=1:length(ind)-1
    linestring=data(ind(i)+1:ind(i+1)-2);
    if strcmp(linestring(1:numchars),id) && (~isempty(strfind(linestring,alsocontains)) || sum(alsocontains)==0)
        count=count+1;
        AllValues=textscan(linestring,'%s','delimiter',' ,');
        if length(AllValues{1})<columnNum
            error(['ID: ' id ' doesnt have a column ' num2str(columnNum)]);
        end
        if isstring
            X{count}=(AllValues{1}(columnNum));
        else
            X(count)=str2double(AllValues{1}(columnNum));
        end
    end
end

end