function Xd = distortImagePoints(Xu,params)
% DISTORTIMAGEPOINTS calculate distorted image points using the
% classical lens distortion model.
%
%   Xu - undistorted image points
%       Xu = [xu_1,xu_2,...;
%             yu_1,yu_2,...];
%   Xd - distorted image points
%       Xd = [xd_1,xd_2,...;
%             yd_1,yd_2,...]; 
%   Xc - center of distortion
%   K - 1xN array containing radial distortion coefficients
%   P - 1xM array containing tangential distortion coefficients
%
% References
%   [1] https://en.wikipedia.org/wiki/Distortion_(optics)
%   [2] J.P. de Villiers, F.W. Leuschner, R. Geldenhuys, "Centi-pixel
%   accurate real-time inverse distortion correction," SPIE Vol 7266, 2008.
%   *NOTE: [2] contains a typo in Eq. 1, (xu,yu) appears to be switched
%   with (xd,yd)
%
%   (c) M. Kutzer 21July2015, USNA

% Updates
%   18Feb2016 - Updated to accept and parse MATLAB camera parameters

%% Parse camera parameters
A_C2M = transpose( params.IntrinsicMatrix );
Xc = params.PrincipalPoint;
K  = params.RadialDistortion;
P  = params.TangentialDistortion;

%% Convert points to camera frame
% TODO - validate this method
Xc(3,:) = 1;
Xc = (A_C2M)^(-1)*Xc;
Xu(3,:) = 1;
Xu = (A_C2M)^(-1)*Xu;

%% Distort points
%TODO - check dimensions of inputs
N = numel(K);
K = reshape(K,1,[]);
M = numel(P);
P = reshape(P,1,[]);

xu = Xu(1,:);
yu = Xu(2,:);
xc = Xc(1);
yc = Xc(2);

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
Xd = A_C2M*Xd;
Xd(3,:) = [];
