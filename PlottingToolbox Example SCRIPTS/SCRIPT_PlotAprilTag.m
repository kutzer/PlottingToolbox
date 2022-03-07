%% SCRIPT_PlotAprilTag
% This script explores using the images of all tags from all the 
% pre-generated AprilTag 3 families [1] to generate simulated tags.
%
% References:
%   AprilTags-imgs, https://github.com/AprilRobotics/apriltag-imgs
%
%   M. Kutzer, 07Mar2022, USNA

clear all
close all
clc

%% Specify tagFamily, tagID, and tagSize
tagFamily = 'tag36h11';
tagID = 3;
tagSize = 50; % (mm)

%% Define pathname and filename
% Pathname (this assumes AprilTags-imgs is cloned in the base GitHub
% directory)
pname = fullfile('..\..\apriltag-imgs',tagFamily);

idx = strfind(tagFamily,'h');
fname = sprintf('%s_%s_%05d.png',...
    tagFamily(1:(idx-1)),tagFamily((idx+1):end),tagID);

%% Read Apriltag
im = imread( fullfile(pname,fname) );
im = rgb2gray(im);
figure; imshow(im);
% Flip data (not sure if this is necessary)
% -> Move reference from upper left to lower left 
im = flipud(im);
figure; imshow(im);

%% Define x/y coordinates
% TODO - figure out if white border is included in scale!
[m,n] = size(im);
% x-corner locations
x = linspace(-tagSize/2,tagSize/2,n+1);
% y-corner locations
y = linspace(-tagSize/2,tagSize/2,m+1);

%% Create patch representation
fig = figure;
axs = axes('Parent',fig);
hold(axs,'on');
daspect(axs,[1 1 1]);

% SLOW METHOD, WAY TOO MANY PATCH OBJECTS!
for i = 1:m
    for j = 1:n
        v_ij(1,:) = [x(j)  , y(i)  , 0];
        v_ij(2,:) = [x(j+1), y(i)  , 0];
        v_ij(3,:) = [x(j+1), y(i+1), 0];
        v_ij(4,:) = [x(j)  , y(i+1), 0];
        
        f_ij = 1:4;
        ptc(i,j) = patch('Vertices',v_ij,'Faces',f_ij,'EdgeColor','m');
        switch im(i,j)
            case 0
                set(ptc(i,j),'FaceColor','k');
            case 255
                set(ptc(i,j),'FaceColor','w');
            otherwise
                set(ptc(i,j),'FaceColor','b');
        end
    end
end

%% Create patch representation, two patch objects
% TODO - actually work out indexing...
idx = [];
verts = [];
for i = 1:m+1
    for j = 1:n+1
        idx(end+1,:) = [j,i];
        verts(end+1,:) = [x(j),y(i),0];
    end
end

faces_k = [];
faces_w = [];
faces_b = [];
for i = 1:m
    for j = 1:n
        idx_ij(1,:) = [j  ,i  ];
        idx_ij(2,:) = [j+1,i  ];
        idx_ij(3,:) = [j+1,i+1];
        idx_ij(4,:) = [j  ,i+1];
        
        for k = 1:size(idx_ij,2)
            face(1,k) = find( idx(:,1) == idx_ij(k,1) & idx(:,2) == idx_ij(k,2) );
        end

        switch im(i,j)
            case 0
                faces_k(end+1,:) = face;
            case 255
                faces_w(end+1,:) = face;
            otherwise
                % Error check
                faces_b(end+1,:) = face;
        end
    end
end

% Create patches
fig = figure;
axs = axes('Parent',fig);
hold(axs,'on');
daspect(axs,[1 1 1]);
ptc_k = patch('Vertices',verts,'Faces',faces_k,'EdgeColor','m','FaceColor','k');
ptc_w = patch('Vertices',verts,'Faces',faces_w,'EdgeColor','m','FaceColor','w');
ptc_b = patch('Vertices',verts,'Faces',faces_b,'EdgeColor','m','FaceColor','b');