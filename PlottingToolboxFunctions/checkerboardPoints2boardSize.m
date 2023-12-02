function [boardSize,squareSize] = checkerboardPoints2boardSize(worldPoints)
% CHECKERBOARDPOINTS2BOARDSIZE determines the board size and square size
% given a set of body-fixed checkerboard points.
%   [boardSize,squareSize] = checkerboardPoints2boardSize(worldPoints)
%
%   Input(s)
%       worldPoints - Nx2 array of body-fixed checkerboard points
%
%   Output(s)
%        boardSize - 1x2 array defining checkerboard size
%       squareSize - scalar defining square size
%
%   M. Kutzer, 02Dec2023, USNA

%% Check input(s)
narginchk(1,1);
if ~ismatrix(worldPoints)
    error('Input must be an Nx2 array.');
end
if size(worldPoints,2) ~= 2
    error('Input must be an Nx2 array.');
end

%% Define board size
boardSize(1,2) = numel( unique(worldPoints(:,1)) ) + 1;
boardSize(1,1) = numel( unique(worldPoints(:,2)) ) + 1;

%% Confirm proper number of world points
n1 = size(worldPoints,1);
m1 = (boardSize(1)-1)*(boardSize(2)-1);
if n1 ~= m1
    str = sprintf([...
        'World points do not appear to be valid.\n',...
        '\t- For boardSize = [%d,%d], worldPoints should be a %dx2 array.\n' ...
        '\t- The worldPoints provided is a %dx2 array.'],...
        boardSize(1),boardSize(2),m1,n1);
    warning(str);
end

%% Define squareSize
squareSize = worldPoints(2,2) - worldPoints(1,2);