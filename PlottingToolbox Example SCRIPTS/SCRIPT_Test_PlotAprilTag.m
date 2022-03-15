%% SCRIPT_Test_PlotAprilTag
% Evaluate simulate/plot AprilTag functions against actual data set.
%
%   M. Kutzer, 15Mar2022, USNA

clear all
close all
clc

%% Define AprilTag
tagFamily = 'tag36h11';
tagID = 2;
tagSize = 130; % (mm)

%% Create simulated AprilTag
figTag = figure('Name','Simulated AprilTag');
axsTag = axes('Parent',figTag);
hold(axsTag,'On');

% Assume camera and axes are co-located
H_a2c = eye(4);
tagInfo = simulateAprilTag(tagFamily,tagID,tagSize);
[h_t2c,handles] = plotAprilTag(axsTag,tagInfo);

%% Load experimental data
load('Exp_AprilTag.mat','cameraParams');
imExp = imread('AprilTag009.png');

%% Get pose of experimental AprilTag
[id,loc,pose] = readAprilTag(imExp,tagFamily,cameraParams,tagSize);

%% Recover intrinsic matrix & extrinsics
% Intrinsics
A_c2m = cameraParams.IntrinsicMatrix.';
% Extrinsics (for experimental tag)
H_t2c = eye(4);
H_t2c(1:3,1:3) = pose.Rotation.';
H_t2c(1:3,4) = pose.Translation.';

%% Plot experimental result
figExp = figure('Name','Experimental AprilTag Image');
axsExp = axes('Parent',figExp);
imgExp = imshow(imExp,'Parent',axsExp);
hold(axsExp,'on');

if ~isempty(id)
    % Define corner points
    c_m = loc.';

    % Plot tag location and ID
    ps = polyshape(c_m(1,:),c_m(2,:));
    plt_loc = plot(ps,'Parent',axsExp,'FaceColor','m',...
        'FaceAlpha',0.5,'EdgeColor','m');
    [x,y] = centroid(ps);
    txt_ID = text(x,y,sprintf('%d',id),...
        'Parent',axsExp,'HorizontalAlignment','center',...
        'VerticalAlignment','middle','Color','w','FontWeight','bold',...
        'FontSize',8);
    for k = 1:size(c_m,2)
        txt_loc(k) = text(c_m(1,k),c_m(2,k),sprintf('v_{%d}',k),...
            'Parent',axsExp,'HorizontalAlignment','center',...
            'VerticalAlignment','middle','Color','k',...
            'FontWeight','bold','FontSize',6,'BackgroundColor','none');
    end

    % Display "tag frame" in image
    X_t = tagSize*eye(3);
    X_t = [zeros(3,1), X_t];
    X_t(4,:) = 1;
    % Project to image
    sX_m = A_c2m*H_t2c(1:3,:)*X_t;
    X_m = sX_m./sX_m(3,:);
    % Plot axes
    colors = 'rgb';
    for k = 2:4
        plt_pose(k) = plot(axsExp,...
            [X_m(1,1),X_m(1,k)],[X_m(2,1),X_m(2,k)],...
            colors(k-1),'LineWidth',1);
    end

end

%% Generate simulated image
set(h_t2c,'Matrix',H_t2c);
imSim = simulateImage(axsTag,cameraParams,H_a2c);

%% Get pose of simulated AprilTag
[id,loc,pose] = readAprilTag(imSim,tagFamily,cameraParams,tagSize);

%% Plot simulated result
figSim= figure('Name','Simulated AprilTag Image');
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
            'FontWeight','bold','FontSize',6,'BackgroundColor','none');
    end

    % Display "tag frame" in image
    X_t = tagSize*eye(3);
    X_t = [zeros(3,1), X_t];
    X_t(4,:) = 1;
    % Project to image
    sX_m = A_c2m*H_t2c(1:3,:)*X_t;
    X_m = sX_m./sX_m(3,:);
    % Plot axes
    colors = 'rgb';
    for k = 2:4
        plt_pose(k) = plot(axsSim,...
            [X_m(1,1),X_m(1,k)],[X_m(2,1),X_m(2,k)],...
            colors(k-1),'LineWidth',1);
    end

end