function p = plotCameraFOV(varargin)
% PLOTCAMERAFOV plots the field of view of a camera given intrinsics,
% scaling, and image resolution.
%   p = PLOTCAMERAFOV(cameraParams,s) creates a patch object (p) to 
%   visualize the field of view of a camera given the camera parameters
%   returned by the MATLAB camera calibrator.
%
%   p = PLOTCAMERAFOV(fisheyeParams,s) creates a patch object (p) to 
%   visualize the field of view of a camera given the fisheye parameters
%   returned by the MATLAB camera calibrator.
%
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

% Updates
%   15Mar2022 - Added cameraParams input support

% TODO - accept cameraParams as an input instead of intrinsic matrix A_c2m

%% Parse inputs
narginchk(2,4);

% Define axs (parent object)
vIDX = 1;
if ishandle(varargin{vIDX})
    vIDX = vIDX + 1;
    axs = varargin{vIDX};
else
    axs = gca;
    hold(axs,'on');
end

% Define camera parameters and/or intrinsic matrix
switch lower( class(varargin{vIDX}) )
    case 'cameraparameters'
        cameraParams = varargin{vIDX};
        A_c2m = [];
    case 'fisheyeparameters'
        cameraParams = varargin{vIDX};
        A_c2m = [];
    otherwise
        cameraParams = [];
        A_c2m = varargin{vIDX};
end
vIDX = vIDX+1;

% Check intrinsic matrix
if ~isempty(A_c2m)
    if size(A_c2m,1) ~= 3 || size(A_c2m,2) ~= 3
        error('Intrinsic matrix must be specified as a 3x3 array.')
    end
    % TODO - check zero and one values of A_c2m for appropriate placement
end

% Parse remaining inputs
nInput = 1;
for i = vIDX:nargin
    switch nInput
        case 1
            s = varargin{i};
        case 2
            res = varargin{i};
        otherwise
            error('Too many inputs specified.');
    end
    nInput = nInput + 1;
end

%% Check inputs
% Check intrinsic matrix
if ~isempty(A_c2m)
    if ~isequal(size(A_c2m),[3,3])
        error('Intrinsic matrix must be 3x3.');
    end
end

% Check scaling/distance
if numel(s) ~= 1 || s < 0
    error('Scaling term must be a positive scaler.');
end

% Set default resolution
if ~isempty(A_c2m)
    if nInput < 3
        res = 2*transpose(A_c2m(1:2,3));
    end

    if numel(res) ~= 2
        error('Image resolution must be a 2-element array.');
    end
end

%% Display FOV using cameraParams
if isempty(A_c2m)
    % Define scale/distance sampling
    n_dist = 50;
    s_all = linspace(0,s,n_dist+1);
    s_all(1) = [];

    % Get resolution & "intrinsics" for pointsToWorld.m
    switch lower( class(cameraParams) )
        case 'cameraparameters'
            res = cameraParams.ImageSize;
            intrinsics = cameraParams;
        case 'fisheyeparameters'
            res = cameraParams.Intrinsics.ImageSize;
            intrinsics = cameraParams.Intrinsics;
    end

    % Define image edge sampling
    n_edge = 50;
    m = res(1);
    n = res(2);
    x_pix = linspace(0,n,n_edge);
    y_pix = linspace(0,m,n_edge);
    
    % Pixels, Side 1 - upper left to upper right
    X_pix1(:,1) = x_pix.';
    X_pix1(:,2) = y_pix(1);
    % Pixels, Side 2 - upper right to lower right
    X_pix2(:,2) = y_pix.';
    X_pix2(:,1) = x_pix(end);
    % Pixels, Side 3 - lower right to lower left
    X_pix3(:,1) = flipud(x_pix.');
    X_pix3(:,2) = y_pix(end);
    % Pixels, Side 4 - lower left to upper left
    X_pix4(:,2) = flipud(y_pix.');
    X_pix4(:,1) = x_pix(1);
    
    % Package pixel bounds
    X_pix = [X_pix1; X_pix2; X_pix3; X_pix4];

    % Define "world points" for designated ranges
    verts = [];
    idx = [];
    for i = 1:numel(s_all)
        z_c = s_all(i);

        % Define points x/y coordinates relative to camera frame
        X_c = pointsToWorld(...
            intrinsics,...                  % "Intrinsics" parameter
            rigid3d(eye(3),[0,0,z_c]),...   % Tranlate along camera z
            X_pix);                         % Pixel coordinates
        % Append z-coordinate
        X_c(:,3) = z_c; % 

        % Append vertices
        verts = [verts; X_c];
        % Append index values
        idx_i(:,2) = 1:size(X_c,1);
        idx_i(:,1) = i;
        idx = [idx; idx_i];
    end

    % Define faces for FOV
    faces = [];
    for i = 2:numel(s_all)
        for j = 2:size(X_pix,1)
            % Define i/j index values for face 
            idx_ij(1,:) = [i-1,j-1];
            idx_ij(2,:) = [i  ,j-1];
            idx_ij(3,:) = [i  ,j  ];
            idx_ij(4,:) = [i-1,j  ];
            % Find face indices
            for k = 1:size(idx_ij,1)
                face(k) = find( ...
                    idx(:,1) == idx_ij(k,1) &...
                    idx(:,2) == idx_ij(k,2) );
            end
            faces(end+1,:) = face;
        end
    end

    % Create patch
    p = patch('Parent',axs,'FaceColor','b','EdgeColor','k',...
        'FaceAlpha',0.3,'EdgeAlpha',0.4,'Vertices',verts,'Faces',faces);
    % Hide edges
    set(p,'EdgeColor','none');
    
    return
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

    
    