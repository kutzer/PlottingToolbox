% SCRIPT_SimulateImage
% This script demonstrates the use of simulateImage.m using a saved figure
% and camera parameters.
%
%   M. Kutzer, 05Jan2020, USNA

%% Load camera parameters & figure
load('cameraParams.mat');
fig = open('Wall-E.fig');

%% Get axes object
axs = get(fig,'Children');
triad('Parent',axs,'Scale',100,'LineWidth',2);

%% Define image dimensions & dpi
vpix = 480;
hpix = 640;

%% Define extrinsic matrix
H_p2m = Tx(50)*Ty(15)*Tz(800)*Rx(pi/3)*Rz(pi/6);

%% Simulate image
im = simulateImage(axs,cameraParams,H_p2m,vpix,hpix);

%% Show image
figure;
img = imshow(im);

%% Move the robot around it's body-fixed z
thetas = linspace(0,2*pi,100);
for theta = thetas
    H_p2m_now = H_p2m*Rz(theta);
    im = simulateImage(axs,cameraParams,H_p2m_now,vpix,hpix);
    set(img,'CData',im);
    drawnow;
end