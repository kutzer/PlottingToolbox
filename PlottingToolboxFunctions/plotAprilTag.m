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

% Define body-fixed frame
tagBase = sprintf('plotAprilTag %s %d',tagInfo.Family,tagInfo.ID);
h_t2p = triad('Parent',handles.Parent,'Scale',(2/3)*tagInfo.Size,...
    'LineWidth',1);
set(h_t2p,'Tag',sprintf('%s, Body-Fixed Frame',tagBase));
hideTriad(h_t2p);
handles.h_t2p = h_t2p;

% Patch black pixels
handles.BlackPatch = patch('Parent',h_t2p,'Vertices',tagInfo.Vertices,...
    'Faces',tagInfo.BlackFaces,'FaceColor','k','EdgeColor','none',...
    'FaceAlpha',1,'FaceLighting','None',...
    'Tag',sprintf('%s, Black Pixels',tagBase));

% Patch white pixels
handles.WhitePatch = patch('Parent',h_t2p,'Vertices',tagInfo.Vertices,...
    'Faces',tagInfo.WhiteFaces,'FaceColor','w','EdgeColor','none',...
    'FaceAlpha',1,'FaceLighting','None',...
    'Tag',sprintf('%s, White Pixels',tagBase));

% Patch location
handles.Location = patch('Parent',h_t2p,'Vertices',tagInfo.Location,...
    'Faces',1:4,'FaceColor','none','EdgeColor','c','LineWidth',1,...
    'Visible','off','Tag',sprintf('%s, Location',tagBase));

% Patch boundary
handles.Boundary = patch('Parent',h_t2p,'Vertices',tagInfo.Boundary,...
    'Faces',1:4,'FaceColor','none','EdgeColor','m','LineWidth',1,...
    'Visible','off','Tag',sprintf('%s, Boundary',tagBase));

% Patch background
% TODO - close sides! 
v = tagInfo.Boundary;
v(:,3) = -0.5; % ASSUMED OFFSET!
handles.Background = patch('Parent',h_t2p,'Vertices',v,...
    'Faces',1:4,'FaceColor','w','EdgeColor','none',...
    'Tag',sprintf('%s, Background',tagBase));