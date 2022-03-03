function appendLine(obj,v)
% APPENDLINE appends a set of data to a line object (or other object
% containing the properties xdata, ydata and [optional] zdata)
%   appendLine(obj,v)
%
%   Input(s)
%       obj - MATLAB object (e.g. line object) with properties xdata, ydata
%             and [OPTIONAL] z-data
%       v   - MxN array array (1 <= M <= 3) to be appended to the object
%
%   M. Kutzer, 28Feb2022, USNA

%% Check input(s)
narginchk(2,2);

% TODO - check input object

M = size(v,1);
N = size(v,2);
if M < 1 || M > 3
    error('Appended vector must be MxN where 1 <= M <= 3.');
end

%% Get current x/y/z data
x = get(obj,'XData');
y = get(obj,'YData');
z = get(obj,'ZData');

if M < 3 && ~isempty(z)
    error('The specified object appears to have z-data, but no z-data was provided in the data to be appended.');
end

switch M
    case 1
        % Assume x is an indexing value
        x = [x,(1:N)+x(end)];
        y = [y,v];
    case 2
        % Append x/y data
        x = [x,v(1,:)];
        y = [y,v(2,:)];
    case 3
        % Append x/y/z data
        x = [x,v(1,:)];
        y = [y,v(2,:)];
        z = [z,v(3,:)];
end

%% Update the object
set(obj,'XData',x,'YData',y,'ZData',z);

