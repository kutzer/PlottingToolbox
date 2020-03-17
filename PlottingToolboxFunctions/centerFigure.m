function varargout = centerFigure(varargin)
% CENTERFIGRE centers a specified figure in the current monitor.
%   CENTERFIGURE centers the current figure.
%
%   CENTERFIGURE(fig) centers a specified figure handle.
%
%   fig = CENTERFIGURE(___) returns the figure that was centered.
%
%   M. Kutzer, USNA, 17Mar2020

%% Parse inputs
narginchk(0,1);

if nargin < 1
    fig = gcf;
else
    fig = varargin{1};
end

%% Get current properties
unt = get(fig,'Units');
set(fig,'Units','Normalized');

pos = get(fig,'Position');
pos0 = floor( pos(1:2) );

pos(1:2) = (ones(1,2) - pos(3:4))./2;
pos(1:2) = pos(1:2) + pos0;
if pos(1) < 0
    pos(1) = 0;
end

if pos(2) < 0
    pos(2) = 0;
end

set(fig,'Position',pos);
set(fig,'Units',unt);

%% Set outputs
varargout = {};
if nargout > 0
    varargout{1} = fig;
end