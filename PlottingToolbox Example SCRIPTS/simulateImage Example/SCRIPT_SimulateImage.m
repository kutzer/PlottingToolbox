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

%% Define image dimensions & dpi
vpix = 480;
hpix = 640;

%% Define extrinsic matrix
H_p2m = Tx(120)*Ty(15)*Tz(1000)*Rx(pi/3)*Rz(pi/6);

%% Simulate image
im = simulateImage(axs,cameraParams,H_p2m,vpix,hpix);

%% Show image
figure;
imshow(im);