function p = plotCameraFOV(varargin)
% PLOTCAMERAFOV plots the field of view of a camera given intrinsics,
% scaling, and image resolution.
%   p = PLOTCAMERAFOV(A_c2m,s) creates a patch object (p) to visualize the
%   field of view of a camera given the intrinsic matrix A_c2m and the
%   scaling (distance) term s. This function assumes the image resolution
%   is defined by the principal point contained in A_c2m.
%
%   p = PLOTCAMERAFOV(A_c2m,s,res) creates a patch object (p) to visualize
%   the field of view of a camera given the intrinsic matrix A_c2m, the
%   scaling (distance) term s, and the camera resolution. Note that
%   resolution is defined as [column resolution, row resolution].
%
%   p = PLOTCAMERAFOV(axs,___) specified the parent of the patch object as
%   axs. Note that axs can be defined as an axes, hgtransform, etc.
%
%   M. Kutzer, USNA, 09Nov2018

% TODO - accept cameraParams as an input instead of intrinsic matrix A_c2m

%% Parse inputs
narginchk(2,4);

vIDX = 1;
if ishandle(varargin{1})
    vIDX = vIDX + 1;
    axs = varargin{1};
else
    axs = gca;
end

nInput = 1;
for i = vIDX:nargin
    switch nInput
        case 1
            A_c2m = varargin{i};
        case 2
            s = varargin{i};
        case 3
            res = varargin{i};
        otherwise
            error('Too many inputs specified.');
    end
    nInput = nInput + 1;
end

%% Check inputs
if ~isequal(size(A_c2m),[3,3])
    error('Intrinsic matrix must be 3x3.');
end

if numel(s) ~= 1
    error('Scaling term must be a scaler.');
end

% Set default resolution
if nInput < 3
    res = 2*transpose(A_c2m(1:2,3));
end

if numel(res) ~= 2
    error('Image resolution must be a 2-element array.');
end

%% Calculate field of view
A_m2c = A_c2m^(-1);

% Define bounding points
X_m = [0,      0, res(1), res(1);...
       0, res(2), res(2),      0;...
       1,      1,      1,      1];
   
% Calculate points relative to camera frame
X_c = s*A_m2c*X_m;

%% Define patch object
p = patch('Parent',axs,'FaceColor','b','EdgeColor','k','FaceAlpha',0.3);
X = zeros(1,3);
X = [X; transpose(X_c)];

p.Vertices = X;
p.Faces = [1,2,3;...
           1,3,4;...
           1,4,5;...
           1,5,2];

    
    