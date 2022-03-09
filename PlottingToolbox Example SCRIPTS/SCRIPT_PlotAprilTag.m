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
tagID = 2;
%tagSize = 130; % (mm)
tagSize = 200;

% tagFamily = 'tagCustom48h12';
% tagID = 36;
% tagSize = 300; % (mm)
%% Define pathname and filename
% Pathname (this assumes AprilTags-imgs is cloned in the base GitHub
% directory)
pname = fullfile('..\..\apriltag-imgs',tagFamily);

idx = strfind(tagFamily,'h');
fname = sprintf('tag%s_%s_%05d.png',...
    tagFamily((idx-2):(idx-1)),tagFamily((idx+1):end),tagID);

%% Read Apriltag
im = imread( fullfile(pname,fname) );
im = rgb2gray(im);

figTag = figure('Name',sprintf('%s, %s',tagFamily,fname));
axsTag = axes('Parent',figTag);
imgTag = imshow(im);
set(figTag,'Units','Normalized','Position',[0.2,0.2,0.6,0.6]);
set(axsTag,'Units','Normalized','Position',[0.1,0.1,0.8,0.8],'Visible','on');
grid(axsTag,'on');
hold(axsTag,'on');
xlabel(axsTag,'x (pixels)');
ylabel(axsTag,'y (pixels)');

%% Define tagSize box
[m,n] = size(im);
if m ~= n
    % AprilTag is not square!
    warning('AprilTag %s, %s is not square [%d,%d].',tagFamily,fname,m,n);
end

for i = 1:floor(n/2)
    ringPix = [];
    % Isolate pixels from ith ring
    ringPix(:,1) = im(i:(end-(i-1)),i);
    ringPix(:,2) = im(i:(end-(i-1)),(end-(i-1)));
    ringPix(:,3) = im(i,i:(end-(i-1))).';
    ringPix(:,4) = im((end-(i-1)),i:(end-(i-1))).';
    
    % Identify mixed/all black/all white rings
    % Mixed ring (default)
    ring(i) = -1; % Default (mixed ring)
    if nnz(ringPix == 0) == numel(ringPix)
        % All black ring
        ring(i) = 0;
    end

    if nnz(ringPix == 255) == numel(ringPix)
        % All white ring
        ring(i) = 1;
    end 

    if i > 1
        if ring(i-1) == 0 && ring(i) == 1
            % Black to white
            iStart = i;
            iEnd   = n-(i-1);
            nSize = n-i-1;
            break
        end 

        if ring(i-1) == 1 && ring(i) == 0
            % White to black
            iStart = i;
            iEnd   = n-(i-1);
            nSize = n-i;
            break
        end
    end
end

%% Define x/y coordinates
f = linspace(-tagSize/2,tagSize/2,nSize+1);
s_tagSize = (iStart-0.5):(iEnd+0.5);
p = polyfit(s_tagSize,f,1);

% x-corner locations
x = polyval(p,s_tagSize);
% y-corner locations
y = polyval(p,s_tagSize);

%% Plot resultant indices
for i = 1:numel(y)-1
    for j = 1:numel(x)-1
        v = (numel(x))*([x(j), y(i); x(j+1), y(i); x(j+1), y(i+1); x(j), y(i+1)] - x(1))./(2*x(end)) + (1/2);
        f = 1:4;
        pix(i,j) = patch('Parent',axsTag,'Vertices',v,'faces',f,...
            'FaceColor','none','EdgeColor','m');
    end
end
%{
%% Create patch representation
% SLOW METHOD, WAY TOO MANY PATCH OBJECTS!
fig = figure;
axs = axes('Parent',fig);
hold(axs,'on');
daspect(axs,[1 1 1]);

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
%}
return
%% 

s_tagBounds = 0.5:(n+0.5);
% x-corner locations
x = polyval(p,s_tagBounds);
% y-corner locations
y = polyval(p,s_tagBounds);

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

faces{1} = [];
faces{2} = [];
faces{3} = [];
for i = 1:m
    for j = 1:n
        % Define vertex indices
        idx_ij(1,:) = [j  ,i  ];
        idx_ij(2,:) = [j+1,i  ];
        idx_ij(3,:) = [j+1,i+1];
        idx_ij(4,:) = [j  ,i+1];

        % Define face indices
        for k = 1:size(idx_ij,1)
            face(1,k) = find( idx(:,1) == idx_ij(k,1) & idx(:,2) == idx_ij(k,2) );
        end

        % Packages black/white faces
        switch im(i,j)
            case 0
                % Black Face
                faces{1}(end+1,:) = face;
            case 255
                % White Face
                faces{2}(end+1,:) = face;
            otherwise
                % Unexpected Face
                % -> Error check
                faces{3}(end+1,:) = face;
                warning('Unexpected pixel value: im(%d,%d) = %d',i,j,im(i,j));
        end
    end
end

%% Create render AprilTag
% Create figure and axes
fig = figure;
axs = axes('Parent',fig);
hold(axs,'on');
daspect(axs,[1 1 1]);
% Add light to axes
%lgt = addSingleLight(axs);

% Create parent to adjust AprilTag pose relative to camera frame
h_t2c = triad('Parent',axs,'Scale',(2/3)*tagSize,'LineWidth',1);

% Render AprilTag
% -> NOTE: Magenta pixels indicate a "bad face" (i.e. a face with pixel
%    value \notin {0,255}
colors = 'kwm';
for i = 1:numel(faces)
    if ~isempty(faces{i})
        ptc(i) = patch('Parent',h_t2c,'Vertices',verts,'Faces',faces{i},...
            'EdgeColor','none','FaceColor',colors(i));
    end
end

% Overlay tagSize
x_tagSize = polyval(p,[s_tagSize(1),s_tagSize(end)]);
y_tagSize = polyval(p,[s_tagSize(1),s_tagSize(end)]);
verts_tagSize = [...
    x_tagSize(1), y_tagSize(1);...
    x_tagSize(2), y_tagSize(1);...
    x_tagSize(2), y_tagSize(2);
    x_tagSize(1), y_tagSize(2)];
faces_tagSize = 1:4;
ptc_tagSize = patch('Vertices',verts_tagSize,'Faces',faces_tagSize,...
    'Parent',h_t2c,'EdgeColor','c','FaceColor','none');

% Overlay tagBounds
x_tagBounds = polyval(p,[s_tagBounds(1),s_tagBounds(end)]);
y_tagBounds = polyval(p,[s_tagBounds(1),s_tagBounds(end)]);
verts_tagBounds = [...
    x_tagBounds(1), y_tagBounds(1);...
    x_tagBounds(2), y_tagBounds(1);...
    x_tagBounds(2), y_tagBounds(2);
    x_tagBounds(1), y_tagBounds(2)];
faces_tagBounds = 1:4;
ptc_tagBounds = patch('Vertices',verts_tagBounds,'Faces',faces_tagBounds,...
    'Parent',h_t2c,'EdgeColor','m','FaceColor','none');

% Adjust patch face lighting
% -> FaceLighting 'none' should provide high contrast regardless of
%    lighting
set(ptc,'FaceLighting','None');

return
%% Test with simulated image
load('Exp_AprilTag.mat');

% Recover extrinsics
H_t2c = eye(4);
H_t2c(1:3,1:3) = poses(1).Rotation.';
H_t2c(1:3,4) = poses(1).Translation.';

set(h_t2c,'Matrix',H_t2c);

% Simulate image
hideTriad(h_t2c); set([ptc_tagSize,ptc_tagBounds],'Visible','off');
imSim = simulateImage(axs,cameraParams,eye(4));
showTriad(h_t2c); set([ptc_tagSize,ptc_tagBounds],'Visible','on');

% Recover intrinsics from camera parameters
intrinsics = cameraParams.Intrinsics;
% Recover intrinsic matrix for reprojection
A_c2m = intrinsics.IntrinsicMatrix.';

% Read AprilTag
[id,loc,pose] = readAprilTag(imSim,tagFamily,intrinsics,tagSize);

%% Plot result
figSim = figure;
axsSim = axes('Parent',figSim);
imgSim = imshow(imSim,'Parent',axsSim);
hold(axsSim,'on');

if ~isempty(id)
    % Define corner points
    c_m = loc.';

    % Plot tag location and ID
    ps = polyshape(c_m(1,:),c_m(2,:));
    plt_loc = plot(ps,'Parent',axsSim,'FaceColor','m',...
        'FaceAlpha',0.5,'EdgeColor','m');
    [x,y] = centroid(ps);
    txt_ID = text(x,y,sprintf('%d',id),...
        'Parent',axsSim,'HorizontalAlignment','center',...
        'VerticalAlignment','middle','Color','w','FontWeight','bold',...
        'FontSize',8);
    for k = 1:size(c_m,2)
        txt_loc(k) = text(c_m(1,k),c_m(2,k),sprintf('v_{%d}',k),...
            'Parent',axsSim,'HorizontalAlignment','center',...
            'VerticalAlignment','middle','Color','k',...
            'FontWeight','bold','FontSize',6);
    end

    % Define & plot tag pose
    H_t2c_tst = eye(4);
    H_t2c_tst(1:3,1:3) = pose.Rotation.';
    H_t2c_tst(1:3,4) = pose.Translation.';

    % Define x/y/z axes in the tag frame
    X_t = tagSize*eye(3);
    X_t = [zeros(3,1), X_t];
    X_t(4,:) = 1;
    % Project to image
    sX_m = A_c2m*H_t2c_tst(1:3,:)*X_t;
    X_m = sX_m./sX_m(3,:);
    % Plot axes
    colors = 'rgb';
    for k = 2:4
        plt_pose(k) = plot(axsSim,...
            [X_m(1,1),X_m(1,k)],[X_m(2,1),X_m(2,k)],...
            colors(k-1),'LineWidth',1);
    end

    % Define projected tag outline (defined using tagSize)
    X_t = (1/2)*tagSize*[-1, 1, 1, -1; -1, -1, 1, 1];
    X_t(4,:) = 1;
    % Project to image
    sX_m = A_c2m*H_t2c_tst(1:3,:)*X_t;
    X_m = sX_m./sX_m(3,:);
    ps = polyshape(X_m(1,:),X_m(2,:));
    plt_loc(j) = plot(ps,'Parent',axsSim,'FaceColor','none',...
        'EdgeColor','c');
end