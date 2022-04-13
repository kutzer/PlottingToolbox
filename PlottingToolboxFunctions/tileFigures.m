function tileFigures(figs)
% TILEFIGURES tiles figures across available screen space.
%   tileFigures
%
%   tileFigures(fig)
%
%   Input(s)
%       figs - array of figure handles
%
%   Output(s)
%
%
%   M. Kutzer, 13Apr2022, USNA

%% Check input(s)
narginchk(0,1);

if nargin < 1
    figs = findobj('Type','Figure');
end

%% Define available screen space
% TODO - add "Use All Monitors" option
%mPos = get(0,'MonitorPositions');

%% Tile figures
w0 = 0.00;  % Lower left corner (initial width)
h0 = 0.03;  % Lower left corner (initial height, accounting for taskbar) 
dw = 0.05;
dh = 0.10;

row = 1;
col = 1;
for i = 1:numel(figs)
    
end