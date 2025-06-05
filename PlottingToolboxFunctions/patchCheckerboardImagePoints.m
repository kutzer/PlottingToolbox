function ptc = patchCheckerboardImagePoints(imagePoints,boardSize)
% PATCHCHECKERBOARDIMAGEPOINTS creates patch structure representing an
% approximate (xxx interpolated) representation of a checkerboard
% fiducial.
%
%   ptc = patchCheckerboardImagePoints(imagePoints,boardSize)
%
%   Input(s)
%       imagePoints - Nx2 array defining image points associated with a
%                     checkerboard fiducial
%         boardSize - 1x2 array defining checkerboard size
%
%   Output(s)
%       ptc - 2-element structured array containing fields for a patch
%             object
%           ptc(1) - Black square patch object
%           ptc(2) - White square patch object
%               *.Vertices - Mx2 array defining patch vertices
%               *.Faces - Kx4 array defining face indices
%
%   M. Kutzer, 04Jun2025, USNA

%% Check input(s)
narginchk(2,2);

N = size(imagePoints,1);
if numel(boardSize) ~= 2
    error('The board size must be defined as a 1x2 array.');
end

m = boardSize(1);
n = boardSize(2);

if N ~= (m-1)*(n-1)
    error('Image points do not match specified board size');
end

%% Define fit
%fcnFit = @spline;
%fcnEval = @ppval;
fcnFit = @(in1,in2)polyfit(in1,in2,1);
fcnEval = @polyval;

%% Reshape image points
for i = 1:size(imagePoints,2)
    X(:,:,i) = reshape(imagePoints(:,i),m-1,n-1);
end

%% Initialize interpolated corners
XX = nan(m+1,n+1,2);
ii = reshape(1:numel(XX(:,:,1)),m+1,n+1);

%% Interpolate columns
k = n-1;
for i = 1:k
    s = (1:(m-1))+1;
    ss = 1:(m+1);
    for j = 1:size(X,3)
        % Identify finite points
        tfIsFinite = isfinite(X(:,i,j));
        % Fit function for interpolation
        fX = fcnFit(s(tfIsFinite),X(tfIsFinite,i,j));
        % Interpolate
        XX(:,i+1,j) = fcnEval(fX,ss);
    end
end

%% Interpolate rows
k = m-1;
for i = 1:k
    s = (1:(n-1))+1;
    ss = 1:(n+1);
    for j = 1:size(XX,3)
        % Identify finite points
        tfIsFinite = isfinite(X(i,:,j));
        % Fit function for interpolation
        fX = fcnFit(s(tfIsFinite),X(i,tfIsFinite,j));
        % Interpolate
        XX(i+1,:,j) = fcnEval(fX,ss);
    end
end

%% Interpolate corners
% Column
XXc = XX;
k = n+1;
for i = [1,k]
    s = (1:(m-1))+1;
    ss = 1:(m+1);
    for j = 1:size(XXc,3)
        % Identify finite points
        tfIsFinite = isfinite(XXc(s,i,j));
        % Fit function for interpolation
        fX = fcnFit(s(tfIsFinite),XXc(s(tfIsFinite),i,j));
        % Interpolate
        XXc(:,i,j) = fcnEval(fX,ss);
    end
end

% Row
XXr = XX;
k = m+1;
for i = [1,k]
    s = (1:(n-1))+1;
    ss = 1:(n+1);
    for j = 1:size(XXr,3)
        % Identify finite points
        tfIsFinite = isfinite(XXr(i,s,j));
        % Fit function for interpolation
        fX = fcnFit(s(tfIsFinite),XXr(i,s(tfIsFinite),j));
        % Interpolate
        XXr(i,:,j) = fcnEval(fX,ss);
    end
end

% Average results
XX = (XXc + XXr)./2;

%% Define faces
faces = [];
isBlack = logical([]);
tf = false;
for i = 1:m
    for j = 1:n
        faces(end+1,:) = [ii(i,j),ii(i,j+1),ii(i+1,j+1),ii(i+1,j)];

        tf = ~tf;
        isBlack(end+1,:) = tf;
    end
end

%% Package output
ptc(1).Vertices = [reshape(XX(:,:,1),[],1),reshape(XX(:,:,2),[],1)];
ptc(2).Vertices = [reshape(XX(:,:,1),[],1),reshape(XX(:,:,2),[],1)];
ptc(1).Faces = faces( isBlack,:);
ptc(2).Faces = faces(~isBlack,:);