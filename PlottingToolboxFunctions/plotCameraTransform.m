function camVis = plotCameraTransform(h_c2x,varargin)
% PLOTCAMERATRANSFORM creates a MATLAB camera object (see plotCamera.m) and
% re-assigns the parent from a default axes to an existing hgtransform
% object.
%   camVis = plotCameraTransform(h_c2x)
%   camVis = plotCameraTransform(h_c2x,[ INPUTS to plotCamera.m ])
%
%   Input(s)
%       h_c2x - hgtransform object (e.g. created from triad.m)
%       INPUTS to plotCamera.m
%             - Name/Value pair inputs for plotCamera.m
%             - Do not use cameraTable input
%             - Do not use 'AbsolutePose' Name/Value pair
%
%   Output(s)
%       camVis - camera object handle returned by plotCamera.m
%
%   NOTES:
%       (1) Returned camera object "parent" property will be a deleted axes
%           handle.
%       (2) Not all camera object properties and/or functions may work as
%           expected when using this function. This function is intended 
%           as a camera visualization tool.
%
%   Example:
%       % Initialize figure & axes
%       fig = figure('Name','plotCameraTransform.m Example');
%       axs = axes('Parent',fig,'dataAspectRatio',[1,1,1],...
%           'NextPlot','add');
%       view(axs,3);
%
%       % Define camera pose relative to axes frame
%       H_c2axs = randSE; 
%
%       % Visulize camera frame & define hgtransform
%       camScale = 10;
%       h_c2axs = triad('Parent',axs,'Matrix',H_c2axs,'Scale',camScale,...
%           'LineWidth',1.2,'AxisLabels',{'x_c','y_c','z_c'});
%
%       % Visulize camera
%       c_Vis = plotCameraTransform(h_c2axs,'Size',camScale/2,...
%           'Color',[0,0,1]);
%
%   M. Kutzer, 02Dec2023, USNA

%% Check input(s)
throwError = false;
if nargin < 1
    error('A single hgtransform object must be specified as the first input.');
end
if numel(h_c2x) ~= 1
    error('A single hgtransform object must be specified as the first input.');
end
if ~ishghandle(h_c2x)
    error('A single hgtransform object must be specified as the first input.');
end
switch lower( get(h_c2x,'Type') )
    case 'hgtransform'
        % Transform is good
    otherwise
        error('A single hgtransform object must be specified as the first input.');
end

%% Create temporary figure & axs
figTMP = figure('Name','plotCameraTransform.m Temporary Figure',...
    'Visible','off');
axsTMP = axes('Parent',figTMP);

%% Create camera visualization
camVis = plotCamera('Parent',axsTMP,varargin{:});

%% Get camVis hgtransform
mom = camVis.Parent;
h_c2c = findobj('Parent',mom,'Type','hgtransform');

if isempty(h_c2c)
    delete(figTMP);
    error('Unable to create camera object.');
end
if numel(h_c2c) > 1
    delete(figTMP);
    error('Unnexpected number of hgtransform objects created with camera object.');
end

%% Update camVis hgtransform properties
set(h_c2c,'Parent',h_c2x,...
    'Tag','Camera Object hgTransform, plotCameraTransform.m');

%% Delete temporary figure/axes
delete(figTMP);