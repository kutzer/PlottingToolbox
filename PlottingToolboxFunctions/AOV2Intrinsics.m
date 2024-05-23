function A_c2m = AOV2Intrinsics(varargin)
% AOV2INTRINSICS estimates the intrinsic matrix of a camera given the angle
% of view and resolution for the camera and lens assembly.
%   A_c2m = AOV2Intrinsics(hAOV,vAOV,res,sInfo)
%   A_c2m = AOV2Intrinsics(dAOV,res,sInfo)
%
%   Input(s)
%       hAOV - scalar value defining the horizontal angle of view in
%              degrees. This must be paired with a vertical angle of view.
%       vAOV - scalar value defining the vertical angle of view in degrees.
%       dAOV - scalar value defining the diagonal angle of view in degrees.
%              This can be specified without the horizontal and vertical
%              angle of view values, and assumes uniform scaling in the
%              intrinsic matrix.
%        res - 1x2 array specifying [column resolution, row resolution] of
%              the imaging sensor in pixels.
%      sInfo - sensor info can be specified as:
%           (1) a scalar value defining pixel size in micrometers
%           (2) a character array defining optical format (e.g. '1/2"')
%
%   Output(s)
%      A_m2c - 3x3 array defining the camera intrinsic matrix. The
%              principal point is assumed to lie at the center of the
%              image.
%      H_c2s - 4x4 array defining the pose of the camera frame relative to
%              to the "sensor frame" (located at the principal point of the
%              imaging sensor).
%
%   See also intrinsics2AOV plotCameraFOV
%
%   M. Kutzer, 23May2024, USNA

debug = true;

%% Check parse & input(s)
narginchk(3,4)

% Parse inputs
switch nargin
    case 3
        camInfo.dAOV  = varargin{1};
        camInfo.res   = varargin{2};
        camInfo.sInfo = varargin{3};
    case 4
        camInfo.hAOV  = varargin{1};
        camInfo.vAOV  = varargin{2};
        camInfo.res   = varargin{3};
        camInfo.sInfo = varargin{4};
    otherwise
        % This should be addressed by narginchk
end

% Check input(s)
flds = {'hAOV','vAOV','dAOV','res'};
info = [1,1,1,2];
for i = 1:numel(flds)
    if isfield(camInfo,flds{i})
        if ~isnumeric(camInfo.(flds{i})) || numel(camInfo.(flds{i})) ~= info(i)
            str = sprintf('"%s" must be defined as a 1x%d array.',flds{i},info(i));
            error(str);
        end
    end
end

% Parse sensor info
if isfield(camInfo,'sInfo')
    if ~isnumeric(camInfo.sInfo)
        camInfo.sInfo = opticalFormat2pixelSize(camInfo.sInfo,camInfo.res);
    end
end

%% Define image sensor dimensions
uv0_m = reshape(camInfo.res,2,1)./2;

x_pix = camInfo.res(1);
y_pix = camInfo.res(2);
d_pix = sqrt(x_pix^2 + y_pix^2);

x_mm = x_pix*camInfo.sInfo/1000;
y_mm = y_pix*camInfo.sInfo/1000;
d_mm = d_pix*camInfo.sInfo/1000;

%% Estimate focal point
if isfield(camInfo,'dAOV')
    z_mm = (d_mm/2)/tand( (camInfo.dAOV)/2 );
end

if isfield(camInfo,'hAOV') && isfield(camInfo,'vAOV')
    z_mm(1) = (x_mm/2)/tand( (camInfo.hAOV)/2 );
    z_mm(2) = (y_mm/2)/tand( (camInfo.vAOV)/2 );
    
    % Keep smallest focal length
    z_mm = min(z_mm);
end

%% Define pixel coordinates
% Define bounding points
X_m = [0,     0, x_pix, x_pix;...
       0, y_pix, y_pix,     0];

%% Define mm coordinates
% Define bounding points
X_c = [-x_mm/2,-x_mm/2, x_mm/2, x_mm/2;...
       -y_mm/2, y_mm/2, y_mm/2,-y_mm/2;...
        z_mm  , z_mm  , z_mm  , z_mm  ];

%% Define A_c2m
A_c2m = z_mm*X_m*pinv(X_c);
A_c2m(3,:) = [0,0,1];