function [Xd,axs] = distortImagePoints(Xu,params)
% DISTORTIMAGEPOINTS calculate distorted image points using the
% classical lens distortion model.
%   Xd = distortImagePoints(Xu,params)
%
%   Input(s)
%           Xu - undistorted image points
%               Xu = [xu_1,xu_2,...;
%                     yu_1,yu_2,...];
%       params - MATLAB camera parameters structured array
%
%   Output(s)
%       Xd - distorted image points
%           Xd = [xd_1,xd_2,...;
%                 yd_1,yd_2,...];
%
%   NOTE: This function is not a 1:1 match for undistortImagePoints. There
%         is still an issue with implementation.
%
% References
%   [1] https://www.mathworks.com/help/vision/ug/camera-calibration.html
%
%   [2] https://www.tangramvision.com/blog/camera-modeling-exploring-distortion-and-distortion-models-part-ii
%
%   [3] https://en.wikipedia.org/wiki/Distortion_(optics)
%
%   [4] J.P. de Villiers, F.W. Leuschner, R. Geldenhuys, "Centi-pixel
%   accurate real-time inverse distortion correction," SPIE Vol 7266, 2008.
%
%   *NOTE: [4] contains a typo in Eq. 1, (xu,yu) appears to be switched
%   with (xd,yd)
%
%   M. Kutzer, 21July2015, USNA

% Updates
%   18Feb2016 - Updated to accept and parse MATLAB camera parameters
%   21Nov2023 - Updated to follow MATLAB documentation

%% EMBEDDED MATLAB FUNCTION
%{
function distortedPoints = distortPoints(points, K, radialDistortion, tangentialDistortion)
%

%   Copyright 2014-2022 The MathWorks, Inc.

%#codegen

% unpack the pre-multiply intrinisc matrix
cx = K(1, 3);
cy = K(2, 3);
fx = K(1, 1);
fy = K(2, 2);
skew = K(1, 2);

% center the points
center = [cx, cy];
centeredPoints = bsxfun(@minus, points, center);

% normalize the points
yNorm = centeredPoints(:, 2, :) ./ fy;
xNorm = (centeredPoints(:, 1, :) - skew * yNorm) ./ fx; % Distortion must be computed without skew

% compute radial distortion
r2 = xNorm .^ 2 + yNorm .^ 2;
r4 = r2 .* r2;
r6 = r2 .* r4;

k = zeros(1, 3, 'like', radialDistortion);
k(1:2) = radialDistortion(1:2);
if numel(radialDistortion) < 3
    k(3) = 0;
else
    k(3) = radialDistortion(3);
end

alpha = k(1) * r2 + k(2) * r4 + k(3) * r6;

% compute tangential distortion
p = tangentialDistortion;
xyProduct = xNorm .* yNorm;
dxTangential = 2 * p(1) * xyProduct + p(2) * (r2 + 2 * xNorm .^ 2);
dyTangential = p(1) * (r2 + 2 * yNorm .^ 2) + 2 * p(2) * xyProduct;

% apply the distortion to the points
normalizedPoints = [xNorm, yNorm];
distortedNormalizedPoints = normalizedPoints + normalizedPoints .* [alpha, alpha] + ...
    [dxTangential, dyTangential];

% convert back to pixels
distortedPointsX = distortedNormalizedPoints(:, 1, :) * fx + cx + ...
    skew * distortedNormalizedPoints(:, 2, :); % Add skew effect back
distortedPointsY = distortedNormalizedPoints(:, 2, :) * fy + cy;


distortedPoints = [distortedPointsX, distortedPointsY];
%}

debugOn = true;

%% Check input(s)
% TODO - check input(s)

%% Create debug plots
if debugOn
    fig = figure('Name','distortImagePoints.m, debugOn = true');
    axs(1) = subplot(1,2,1,'Parent',fig);
    axs(2) = subplot(1,2,2,'Parent',fig);
    set(axs,'NextPlot','add','DataAspectRatio',[1 1 1],'YDir','Reverse');

    xlabel(axs(1),'x (pixels)');
    ylabel(axs(1),'y (pixels)');

    xlabel(axs(2),'x (normalized image coordinates)');
    ylabel(axs(2),'y (normalized image coordinates)');
else
    axs = [];
end

%% Parse camera parameters
A_c2m = ( params.IntrinsicMatrix ).';
A_m2c = ( A_c2m )^(-1);
Xo = params.PrincipalPoint;
%F  = params.FocalLength;
K  = params.RadialDistortion;
P  = params.TangentialDistortion;

%% Plot original points and principal point
if debugOn
    plt_Xu = plot(axs(1),Xu(1,:),Xu(2,:),'xr','Tag','Undistorted Points');
    for i = 1:size(Xu,2)
        txt_Xu(i) = text(Xu(1,i),Xu(2,i),sprintf('$x_{%d}$',i),...
            'Parent',axs(1),'Interpreter','latex','VerticalAlignment','top',...
            'HorizontalAlignment','left','FontSize',12,'Tag','Undistorted Point Labels');
    end

    plt_Xo = plot(axs(1),Xo(:,1),Xo(:,2),'+g','Tag','Principal Point');
end

%% Define normalized image coordinates
Xu(3,:) = 1;
Xn = A_m2c*Xu;
Xu(3,:) = [];
Xn(3,:) = [];
%Xn = (Xu - Xo.')./F.';
Rn = sqrt(sum(Xn.^2,1));

if debugOn
    plt_bXn = plot(axs(2),Xn(1,:),Xn(2,:),'xr','Tag','Normalized Points');
    for i = 1:size(Xn,2)
        txt_bXn(i) = text(Xn(1,i),Xn(2,i),sprintf('$\\bar{x}_{%d}$',i),...
            'Parent',axs(2),'Interpreter','latex','VerticalAlignment','top',...
            'HorizontalAlignment','left','FontSize',12,'Tag','Normalized Point Labels');

        %r_bXn(i) = plot(axs(2),[0,Xn(1,i)],[0,Xn(2,i)],':k','Tag','Normalized Radius');
        if ~isZero( Rn(i) - norm(Xn(:,i)) )
            fprintf('%f ~= %f for i = %d\n',Rn(i),norm(Xn(:,i)),i);
        end
    end

    plt_bXo = plot(axs(2),0,0,'+g','Tag','Principal Point');
end

%% Calculate radial distortion
if numel(K) < 3
    K(3) = 0;
end
%Xr(1,:) = Xn(1,:).*(1 + K(1)*Rn.^2 + K(2)*Rn.^4 + K(3)*Rn.^6);
%Xr(2,:) = Xn(2,:).*(1 + K(1)*Rn.^2 + K(2)*Rn.^4 + K(3)*Rn.^6);
delta_r(1,:) = (1 + K(1)*Rn.^2 + K(2)*Rn.^4 + K(3)*Rn.^6);
delta_r(2,:) = (1 + K(1)*Rn.^2 + K(2)*Rn.^4 + K(3)*Rn.^6);
%% Calculate tangential distortion
if numel(P) < 2
    P(2) = 0;
end
%Xt(1,:) = Xn(1,:) + (2*P(1)*Xn(1,:).*Xn(2,:) + P(2)*(Rn.^2 + 2*Xn(1,:).^2));
%Xt(2,:) = Xn(2,:) + (P(1)*(Rn.^2 + 2*Xn(2,:).^2) + 2*P(2)*Xn(1,:).*Xn(2,:));
delta_t(1,:) = (2*P(1)*Xn(1,:).*Xn(2,:) + P(2)*(Rn.^2 + 2*Xn(1,:).^2));
delta_t(2,:) = (P(1)*(Rn.^2 + 2*Xn(2,:).^2) + 2*P(2)*Xn(1,:).*Xn(2,:));

%% Package output
% Calculate normalized distortion
Xd = (Xn + delta_t).*delta_r;

if debugOn
    plt_bXd = plot(axs(2),Xd(1,:),Xd(2,:),'+b',...
        'Tag','Distorted Normalized Points');
    for i = 1:size(Xd,2)
        txt_bXd(i) = text(Xd(1,i),Xd(2,i),sprintf('$\\tilde{x}_{%d}$',i),...
            'Parent',axs(2),'Interpreter','latex','VerticalAlignment','bottom',...
            'HorizontalAlignment','right','FontSize',12,...
            'Tag','Distorted Normalized Point Labels');
    end
end

% Re-scale
Xd(3,:) = 1;
Xd = A_c2m*Xd;
Xd(3,:) = [];
%Xd = Xd.*F.' + Xo.';

if debugOn
    plt_Xd = plot(axs(1),Xd(1,:),Xd(2,:),'+b',...
        'Tag','Distorted Normalized Points');
    for i = 1:size(Xd,2)
        txt_Xd(i) = text(Xd(1,i),Xd(2,i),sprintf('$\\tilde{x}_{%d}$',i),...
            'Parent',axs(1),'Interpreter','latex','VerticalAlignment','bottom',...
            'HorizontalAlignment','right','FontSize',12,...
            'Tag','Distorted Normalized Point Labels');
    end
end

return
%% --- Old method ---

%% Convert points to camera frame
% TODO - validate this method
Xo(3,:) = 1;
Xo = (A_c2m)^(-1)*Xo;
Xu(3,:) = 1;
Xu = (A_c2m)^(-1)*Xu;

%% Distort points
%TODO - check dimensions of inputs
N = numel(K);
K = reshape(K,1,[]);
M = numel(P);
P = reshape(P,1,[]);

xu = Xu(1,:);
yu = Xu(2,:);
xc = Xo(1);
yc = Xo(2);

xuc = bsxfun(@minus,xu,xc);
yuc = bsxfun(@minus,yu,yc);
r = sqrt( xuc.^2 + yuc.^2 );

rN = zeros(N,numel(r));
for i = 1:N
    rN(i,:) = r.^(2*i);
end

%TODO - account for M = 1 and M = 2 in a cleaner/faster way
if M < 3
    P(1,3) = 0;
end
rM = zeros(M-2,numel(r));
for i = 3:M
    rM(i-2,:) = r.^(2*(i-2));
end

%Villiers
xd = xu + xuc.*(K*rN) + ...
    ( P(1)*(r.^2 + 2*xuc.^2) + 2*P(2)*xuc.*yuc ).*bsxfun(@plus,1,P(3:M)*rM);

yd = yu + yuc.*(K*rN) + ...
    ( 2*P(1)*xuc.*yuc + P(2)*(r.^2 + 2*yuc.^2) ).*bsxfun(@plus,1,P(3:M)*rM);

%Wiki
% xd = xu.*(K*rN) + ...
%     ( P(2)*(r.^2 + 2*xu.^2) + 2*P(1)*xu.*yu ).*bsxfun(@plus,1,P(3:M)*rM);
%
% yd = yu.*(K*rN) + ...
%     ( P(1)*(r.^2 + 2*yu.^2) + 2*P(2)*xu.*yu ).*bsxfun(@plus,1,P(3:M)*rM);

Xd = [xd; yd];

%% Project distorted points back to matrix frame
Xd(3,:) = 1;
Xd = A_c2m*Xd;
Xd(3,:) = [];
