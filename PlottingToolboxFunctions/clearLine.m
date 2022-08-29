function clearLine(obj)
% CLEARLINE clears data contained in a line object (or object containing
% the properties xdata, ydata, and zdata)
%   clearLine(obj)
%
%   Input(s)
%       obj - MATLAB object (e.g. line object) with properties xdata, ydata
%             and [OPTIONAL] z-data
%
%   See also plot appendLine
%
%   M. Kutzer, 29Aug2022, USNA

%% Check input(s)
narginchk(1,1);

% TODO - check input object

%% Get current x/y/z data

% Get data and check input object
try
    x = get(obj,'XData');
    y = get(obj,'YData');
    z = get(obj,'ZData');
catch ME
    error('APPENDLINE:badObject','The object provided is invalid.\n\n%s',...
        ME.message);
end

%% Update the object
set(obj,'XData',[],'YData',[],'ZData',[]);