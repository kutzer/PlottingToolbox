function h_f2c = plotFiducialExtrinsics(h_c2x,cameraParams,squareColors)
% PLOTFIDUCIALEXTRINSICS plots fiducial extrinsics relative to the camera
% frame using camera parameters.
%   h_f2c = plotFiducialExtrinsics(h_c2x,cameraParams,squareColors)
%
%   Input(s)
%              h_c2x - hgTransform object defining the camera frame
%       cameraParams - camera parameters object
%       squareColors - [OPTIONAL] 1x2 cell array containing the color 
%                      of the checkerboard squares. Elements of 
%                      squareColors can be specified as a valid color
%                      character or an rgb triplet.
%
%   Output(s)
%       h_f2c - N-element hgTransform object defining each checkerboard
%               fiducial pose relative to the camera frame.
%
%   See also plotCheckerboard
%
%   M. Kutzer, 02Dec2023, USNA

%% Check input(s)
narginchk(2,3);
% TODO - check inputs

%% Parse camera parameters
cameraFields = fields(cameraParams);

fields2022b = {'RotationMatrices','TranslationVectors','NumPatterns'};
fields2023a = {'PatternExtrinsics'};

if nnz( matches(cameraFields,fields2022b) ) == numel(fields2022b)
    % MATLAB 2022b and older
    n = cameraParams.NumPatterns;
    for i = 1:n
        R_f2c = cameraParams.RotationMatrices(:,:,i).';
        d_f2c = cameraParams.TranslationVectors(i,:).';
        H_f2c{i} = [R f2c, d f2c; 0,0,0,1];
    end
end

if nnz( matches(cameraFields,fields2023a) ) == numel(fields2023a)
    % MATLAB 2022b and older
    n = numel(cameraParams.PatternExtrinsics);
    for i = 1:n
        rtform = cameraParams.PatternExtrinsics(i);
        H_f2c{i} = rtform.A;
    end
end

%% Define board & square size
worldPoints = cameraParams.WorldPoints;
[boardSize,squareSize] = checkerboardPoints2boardSize(worldPoints);

%% Plot checkerboards
% Initialize checkerboard to copy
if nargin < 3
    hg = plotCheckerboard(h_c2x,boardSize,squareSize);
else
    hg = plotCheckerboard(h_c2x,boardSize,squareSize,squareColors);
end

for i = 1:numel(H_f2c)
    h_f2c(i) = copyobj(hg,h_c2x);
    set(h_f2c(i),'Matrix',H_f2c{i});
end

delete(hg);
