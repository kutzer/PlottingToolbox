function [h_t2p,handles] = plotAprilTag(varargin)
% PLOTAPRILTAG plots a simulated AprilTag
%   [h_t2p,handles] = plotAprilTag(tagInfo)
%
%   [h_t2p,handles] = plotAprilTag(tagFamily,tagID,tagSize)
%
%   [h_t2p,handles] = plotAprilTag(axs,___)
%
%   Inputs [OPTION 1]
%       axs       - [OPTIONAL] axes or parent handle for rendered AprilTag. 
%                   If none are specified, axs = gca.
%       tagInfo   - structured array containing AprilTag information (see 
%                   simulateAprilTag.m)
%
%   Inputs [OPTION 2]
%       axs       - [OPTIONAL] axes or parent handle for rendered AprilTag. 
%                   If none are specified, axs = gca.
%       tagFamily - character array specifying the AprilTag family (must
%                   exist apriltag-imgs)
%       tagID     - scalar integer specifying AprilTag ID (must exist
%                   apriltag-imgs)
%       tagSize   - positive scalar value specifying the AprilTag size
%                   (e.g. in millimeters)
%
%   Outputs
%       h_t2p   - hgtransform object parent of the rendered AprilTag. This 
%                 includes axis visualization (see triad.m) set to 
%                 'visible' 'off' (see hideTriad/showTriad).
%       handles - handles associated with the rendered AprilTag
%           *.Parent     - object handle of parent to h_t2p
%           *.h_t2p      - hgtransform object parent of AprilTag
%           *.BlackPatch - patch object rendering white AprilTag pixels
%           *.WhitePatch - patch object rendering white AprilTag pixels
%           *.Location   - patch object rendering AprilTag "location" box
%                          (default set to 'visible','off')
%           *.Boundary   - patch object rendering AprilTag "boundary" box
%                          (default set to 'visible','off')
%           *.Background - patch object rendering of AprilTag background to
%                          occlude back of AprilTag
%
%   See also simulateAprilTag simulateImage
%
%   M. Kutzer, 14Mar2022, USNA

% Updates
%   15Mar2022 - Adjusted background/backing patch to exist in the
%               +z-direction matching the actual AprilTag direction.

%% Check input(s)
narginchk(1,4);

switch nargin
    case 1
        axs = gca;
        tagInfo = varargin{1};
    case 2
        axs = varargin{1};
        tagInfo = varargin{2};
    case 3
        axs = gca;
        tagFamily = varargin{1};
        tagID = varargin{2};
        tagSize = varargin{3};
        tagInfo = simulateAprilTag(tagFamily,tagID,tagSize);
    case 4
        axs = varargin{1};
        tagFamily = varargin{2};
        tagID = varargin{3};
        tagSize = varargin{4};
        tagInfo = simulateAprilTag(tagFamily,tagID,tagSize);
    otherwise
        error('Unexpected inputs, see "help plotAprilTag" for correct syntax.');
end

% Check parent
if ~ishandle(axs)
    error('Parent must be specified as a valid graphics handle.');
end

switch lower( get(axs,'Type') )
    case 'axes'
        % Acceptable type
        hold(axs,'on');
        daspect(axs,[1 1 1]);
    case 'hgtransform'
        % Acceptable type
    otherwise
        error('Parent handle must be an axes or hgtransform.');
end

% Check tagInfo
usedFields = {'Family','ID','Size','Location','Boundary','Vertices',...
    'BlackFaces','WhiteFaces'};
bin = isfield(tagInfo,usedFields);
if nnz(bin) ~= numel(usedFields)
    msg = sprintf('tagInfo is missing the following required fields:');
    missingFields = usedFields(~bin);
    for i = 1:numel(missingFields)
        msg = sprintf('%s\n\ttagInfo.%s',msg,missingFields{i});
    end
    error('%s',msg);
end

%% Render AprilTag
% Define parent
handles.Parent = axs;

% Define handle tag base name
tagBase = sprintf('plotAprilTag %s %d',tagInfo.Family,tagInfo.ID);

% Define body-fixed frame
h_t2p = triad('Parent',handles.Parent,'Scale',(2/3)*tagInfo.Size,...
    'LineWidth',1);
set(h_t2p,'Tag',sprintf('%s, Body-Fixed Frame',tagBase));
hideTriad(h_t2p);
handles.h_t2p = h_t2p;

% Patch black pixels
v = tagInfo.Vertices;
v(:,3) = 0;
f = tagInfo.BlackFaces;
handles.BlackPatch = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',f,'FaceColor','k','EdgeColor','none',...
    'FaceAlpha',1,'FaceLighting','None',...
    'Tag',sprintf('%s, Black Pixels',tagBase));

% Patch white pixels
v = tagInfo.Vertices;
v(:,3) = 0;
f = tagInfo.WhiteFaces;
handles.WhitePatch = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',f,'FaceColor','w','EdgeColor','none',...
    'FaceAlpha',1,'FaceLighting','None',...
    'Tag',sprintf('%s, White Pixels',tagBase));

% Patch location
v = tagInfo.Location;
v(:,3) = 0;
f = 1:4;
handles.Location = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',f,'FaceColor','none','EdgeColor','c','LineWidth',1,...
    'Visible','off','Tag',sprintf('%s, Location',tagBase));

% Patch boundary
v = tagInfo.Boundary;
v(:,3) = 0;
f = 1:4;
handles.Boundary = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',f,'FaceColor','none','EdgeColor','m','LineWidth',1,...
    'Visible','off','Tag',sprintf('%s, Boundary',tagBase));

% Patch background
% -> Define offset between front of tag and background
backgroundOffset = tagInfo.Size/500; 
% -> Define vertices
v_f = tagInfo.Boundary;
v_f(:,3) = 0;                   % Append z-coordinate
v_b = tagInfo.Boundary;
v_b(:,3) = backgroundOffset;   % Append z-coordinate w/ ASSUMED OFFSET!
v = [v_f; v_b];     % Combine vertices
% -> Define faces
f(1,:) = [5,6,7,8]; % Back face
f(2,:) = [5,6,2,1]; % Side
f(3,:) = [6,7,3,2]; % Side
f(4,:) = [7,8,4,3]; % Side
f(5,:) = [8,5,1,4]; % Side
% -> Create patch
handles.Background = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',f,'FaceColor','w','EdgeColor','none','FaceAlpha',1,...
    'FaceLighting','None','Tag',sprintf('%s, Background',tagBase));