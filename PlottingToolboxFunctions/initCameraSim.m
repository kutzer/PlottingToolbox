function sim = initCameraSim(varargin)
% INITCAMERASIM initializes a figure and axes matching the approximate
% field of view of a pinhole camera given the camera intrinsics and
% resolution.
%   sim = INITCAMERASIM(A_c2m) initializes a figure and axes matching the 
%   approximate field of view of a pinhole camera given the camera 
%   intrinsics A_c2m.  This function assumes the image resolution  is 
%   defined by the principal point contained in A_c2m. 
%
%   sim = INITCAMERASIM(A_c2m,res) specifies the camera resolution (res). 
%   Note that resolution is defined as [column resolution, row resolution]. 
%
%   sim = INITCAMERASIM(A_c2m,res,s) the depth of the simulated camera. 
%
%   Note that this function assumes the camera remains at the origin and
%   all objects are moved relative to the camera frame.
%
%   This function returns a structured array sim:
%       sim.Figure - figure handle for simulated FOV
%       sim.Axes   - axes handle for simulated FOV
%       sim.hRes   - horizontal resolution of the camera
%       sim.vRes   - vertical resolution of the camera
%       sim.hAOV   - approximate horizontal angle of view for the camera
%       sim.vAOV   - approximate vertical angle of view for the camera
%   
%   To capture simulated image from sim, use the following:
%       frm = getframe(sim.Figure);
%       im = frm.cdata;
%
%   M. Kutzer, USNA, 17Mar2020

% TODO - accept cameraParams as an input instead of intrinsic matrix A_c2m

%% Parse inputs
narginchk(1,3);

A_c2m = varargin{1};

if nargin > 1
    res = varargin{2};
else
    % Set default resolution
    res = 2*transpose(A_c2m(1:2,3));
end

if nargin > 2
    s = varargin{3};
else
    s = 24*12*25.4; % 24' converted to millimeters
end

% Seperate horizontal and vertical resolution
hpix = res(1);
vpix = res(2);

% Calculate horizontal and vertical angle of view
[hAOV,vAOV] = intrinsics2AOV(A_c2m);

%% Attempt to *easily* replicate camera FOV
fig = figure('Name','Simulated Camera FOV (Approximate)',...
    'Tag','Simulated Camera FOV, Figure');
axs = axes('Parent',fig,'Tag','Simulated Camera FOV, Axes');
daspect(axs,[1 1 1]);
hold(axs,'on');
% Set axes limits
xlim([-hpix,hpix]); % In theory these should be [0,hpix]
ylim([-vpix,vpix]); % In theory these should be [0,vpix]
zlim([0,s]);

% Set parameters
set(fig,'Renderer','OpenGL','Color',[1 1 1]);
set(axs,'ZDir','Reverse','XDir','Reverse','Visible','off');

% Setup for saving correct image dimensions
set(axs,'Units','Normalized','Position',[0,0,1,1]);
set(fig,'Units','Pixels');
pos = get(fig,'Position');
set(fig,'Position',[pos(1:2),hpix,vpix]);
centerFigure(fig);

% Set up camera parameters
camproj(axs,'Perspective'); % projection
camva(axs,hAOV);            % view angle 
campos(axs,zeros(1,3));     % camera position
camtarget(axs,[0,0,s]);     % target position
camup(axs,[0,-1,0]);        % camera "up" direction

% frm = getframe(fig);
% im = frm.cdata;

%% Package output
sim.Figure = fig;
sim.Axes   = axs;
sim.hRes   = hpix;
sim.vRes   = vpix;
sim.hAOV   = hAOV;
sim.vAOV   = vAOV;