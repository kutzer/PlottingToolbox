function [hg,ptc,cInfo] = plotCheckerboard(varargin)
% PLOTCHECKERBOARD plots a visual representation of a checkerboard given a
% 1x2 board size representing the number of squares in body-fixed the 
% x-direction and y-direction, and the square size.
%   [hg, ptcs, cInfo] = plotCheckerboard(boardSize,squareSize) returns an
%   hgtransform (hg) object that is the parent of the checkerboard
%   visualization, and the patch objects of each square (ptcs).
%
%   [___] = plotCheckerboard(boardSize,squareSize,squareColors) allows the
%   user to specify the colors of the squares on the checkerboard as a
%   2-element cell array. The default value is {'k','w'} (black and white)
%   matching the convention used by MATLAB's "detectCheckerboardPoints."
%
%   [___] = plotCheckerboard(axs,___) allows the user to 
%   specify the axes or parent of the checkerboard representation.
%
%   Input(s)
%                axs - parent object for the checkerboard, default value is
%                      axs = gca
%          boardSize - 1x2 array of positive integer values defining 
%                      checkerboard size (see detectCheckerboardPoints)
%         squareSize - positive scalar value defining the size of a single 
%                      checkerboard squares, e.g. 10mm 
%                      (see generateCheckerboardPoints)
%       squareColors - 1x2 cell array containing the color of checkerboard 
%                      squares. Elements of squareColors can be specified 
%                      as a valid color character or an rgb triplet.
%
%   Output(s)
%        hg - hgtransform object parent of the checkerboard patch objects
%       ptc - patch objects visualizing the checkerboard
%     cInfo - structured array containing checkerboard information
%       cInfo.BoardSize  - 1x2 array defining board size
%       cInfo.SquareSize - scalar value defining square size
%       cInfo.Boundary   - 4x2 array containing the x/y bounding box 
%                          corners of the checkerboard
%
%   See also detectCheckerboardPoints generateCheckerboardPoints
%
%   M. Kutzer, USNA, 04Sep2019

% Updates
%   14Apr2022 - Updated documentation
%   14Apr2022 - Updated input parsing and added input checking
%   14Apr2022 - Deleted copyobj patch after use
%   15Sep2022 - Added cInfo output
%% Parse inputs and set defaults 
% TODO - check inputs and better check number of inputs
narginchk(2,4);

idx0 = 1;
% Check if parent was provided
if numel(varargin{1}) == 1 && ishandle(varargin{1}(1))
    mom = varargin{1};
    idx0 = idx0 + 1;
else
    mom = gca;
end

boardSize  = varargin{idx0};
squareSize = varargin{idx0 + 1};

% Define square colors
if nargin > (idx0+1)
    squareColors = varargin{idx0 + 2};
else
    squareColors = {'k','w'};
end

%% Check inputs
switch lower( get(mom,'Type') )
    case 'axes'
        % Acceptable parent
    case 'hgtransform'
        % Acceptable parent
    otherwise
        error('Specified parent must be a valid axes or hgtransform object.');
end

if numel(boardSize) ~= 2 || nnz(boardSize == round(abs(boardSize))) ~= numel(boardSize)
    error('Board size must be specified as a two element array containing positive integers.');
end

if numel(squareSize) ~= 1 || squareSize ~= abs(squareSize)
    error('Square size must be defined as a positive scalar.');
end

if ~iscell(squareColors) || numel(squareColors) ~= 2
    error('Square colors must be defined as a 2-element cell array.');
end

%% Create base frame
hg = triad('Scale',2*squareSize,'Linewidth',1.5,'Parent',mom);

%% Create patch object
p0.Faces = [1,2,3,4];
p0.Vertices = squareSize * [...
    0, 1, 1, 0; ... % x
    0, 0, 1, 1; ... % y
    0, 0, 0, 0].';  % z

p0 = patch(p0,'Parent',hg,'EdgeColor','k','FaceColor','w');

%% Create boxes
xColor = false;
x0 = -squareSize;
y0 = -squareSize;
xy = [];
for i = 1:boardSize(2)      % boxes in x-direction
    % Define x-position of box
    x = x0 + (i-1)*squareSize;
    % Define base color for y-index of 1
    xColor = ~xColor;
    % Define xy-color
    xyColor = ~xColor;
    for j = 1:boardSize(1)  % boxes in y-direction
        % Define y-position
        y = y0 + (j-1)*squareSize;
        % Update xy-color
        xyColor = ~xyColor;
        
        % Clone patch
        ptc(i,j) = copyobj(p0,hg);
        
        % Update position
        v = ptc(i,j).Vertices.';
        v(4,:) = 1;
        v = Tx(x)*Ty(y)*v;
        v(4,:) = [];
        ptc(i,j).Vertices = v.';
        
        % Append new vertices
        xy = [xy; v(:,1:2)];

        % Update face color
        if xyColor
            % "Black"
            set(ptc(i,j),'FaceColor',squareColors{1});
        else
            % "White"
            set(ptc(i,j),'FaceColor',squareColors{2});
        end
    end
end
delete(p0);

%% Define cInfo
if nargout > 2
    xx = [min(xy(:,1)), max(xy(:,1))];
    yy = [min(xy(:,2)), max(xy(:,2))];

    cInfo.BoardSize  = boardSize;
    cInfo.SquareSize = squareSize;
    cInfo.Boundary   = [...
        xx(1), yy(1);...
        xx(2), yy(1);...
        xx(2), yy(2);...
        xx(1), yy(2)];
end