%% SCRIPT_Test_setParentTransform
% This script tests set parent transform using the UR3e simulation
% environment.
%
%   M. Kutzer, 26Mar2024, USNA
clear all
close all
clc

%% Initialize robot simulation
% Initialize robot
sim = URsim;
sim.Initialize('UR3');

% Hide component frames
for i = 0:6
    hideTriad(sim.(sprintf('hFrame%d',i)));
end
% Hide tool frame
hideTriad(sim.hFrameT);
% Hide end-effecot frame
hideTriad(sim.hFrameE);
% Tag end-effector frame (for use later)
set(sim.hFrameE,'Tag','Frame E');

%% Define i/j joint configurations
q_i = [pi/2; -pi/4; pi/2; -pi/2; pi/2; pi/2];
q_j = [pi/4; -pi/4; pi/4;     0;    0; pi/2];

%% Show transformations (H_fi^fj)
% Copy configuration i
sim.Joints = q_i;
drawnow;
sim_i = copyobj(sim.hFrame0,sim.Axes);

% Copy configuration j
sim.Joints = q_j;
drawnow;
sim_j = copyobj(sim.hFrame0,sim.Axes);

% Adjust x/y/z limits
axis(sim.Axes,'tight');

%% Change color of sim_i and sim_j
ptc_i = findobj(sim_i,'Type','Patch');
set(ptc_i,'FaceColor','r','FaceAlpha',0.5);

ptc_j = findobj(sim_j,'Type','Patch');
set(ptc_j,'FaceColor','g','FaceAlpha',0.5);

%% Recover end-effector frames
h_e2o_i = findobj(sim_i,'Type','hgtransform','Tag','Frame E');
h_e2o_j = findobj(sim_j,'Type','hgtransform','Tag','Frame E');

%% Redefine parent transform
sim.Joints = q_j;
familyTree = setParentTransform(h_e2o_j);

%% Overlay end-effectors
set(h_e2o_j,'Parent',h_e2o_i,'Matrix',eye(4));
