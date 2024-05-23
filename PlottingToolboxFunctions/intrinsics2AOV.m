function varargout = intrinsics2AOV(varargin)
% INTRINSICS2AOV calculates the angle of view (AOV or view angle)
% in degrees associated with the intrinsic matrix of a camera.
%   hAOV = INTRINSICS2AOV(A_c2m) returns the horizontal angle of view 
%   in degrees (hAOV) using the intrinsic matrix A_c2m. This function 
%   assumes the image resolution is defined by the principal point 
%   contained in A_c2m.
%
%   hAOV = INTRINSICS2AOV(A_c2m,res) returns the horizontal angle of view 
%   in degrees (hAOV) using the intrinsic matrix A_c2m and the camera 
%   resolution. Note that resolution is defined as [column resolution, row 
%   resolution].
%
%   [hAOV,vAOV,dAOV] = INTRINSICS2AOV(___) returns the horizontal angle of
%   view (hAOV), vertical angle of view (vAOV), and diagonal angle of view
%   (dAOV) in degrees.
%
%   See also AOV2Intrinsics plotCameraFOV
%
%   M. Kutzer, USNA, 17Mar2020

% Updates
%   16Jun2020 - corrected horizontal & vertical AOV estimates.

% TODO - accept cameraParams as an input instead of intrinsic matrix A_c2m

%% Parse inputs
narginchk(1,2);

A_c2m = varargin{1};

if nargin > 1
    res = varargin{2};
else
    % Set default resolution
    res = 2*transpose(A_c2m(1:2,3));
end

%% Check inputs
if ~isequal(size(A_c2m),[3,3])
    error('Intrinsic matrix must be 3x3.');
end

if numel(res) ~= 2
    error('Image resolution must be a 2-element array.');
end

%% Calculate field of view
s = 100; % assume scaling value
A_m2c = A_c2m^(-1);

% Define bounding points
X_m = [0,      0, res(1), res(1);...
       0, res(2), res(2),      0;...
       1,      1,      1,      1];
   
% Calculate points relative to camera frame
X_c = s*A_m2c*X_m;

%% Center points 
X_c0 = X_c - repmat( mean(X_c,2), 1, size(X_c,2) );

%% Estimate angle of view
if nargout > 0
    %hAOV = atan2d(max(X_c0(1,:)),s) - atan2d(min(X_c0(1,:)),s);
    hAOV = atan2d(max(X_c0(2,:)),s) - atan2d(min(X_c0(2,:)),s); % Corrected
    varargout{1} = hAOV;
end

if nargout > 1
    %vAOV = atan2d(max(X_c0(2,:)),s) - atan2d(min(X_c0(2,:)),s);
    vAOV = atan2d(max(X_c0(1,:)),s) - atan2d(min(X_c0(1,:)),s); % Corrected
    varargout{2} = vAOV;
end

if nargout > 2
    dAOV = ...
        atan2d( sqrt( max(X_c0(1,:))^2 + max(X_c0(2,:))^2 ),s) - ...
        atan2d(-sqrt( min(X_c0(1,:))^2 + min(X_c0(2,:))^2 ),s);
    varargout{3} = dAOV;
end