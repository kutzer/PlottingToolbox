%% SCRIPT_UR3e_Write
clear all
close all
clc

%% Create points
SCRIPT_Test_pShapesToSplines;

%% Define writing box
xx = [-370,-181];
yy = [ 190, 352];
zz = 215;

x_c = xx(1) + diff(xx);
y_c = yy(1) + diff(yy);
z_c = zz;

%% Transform path to new center point
H_p2c = Tx(x_c)*Ty(y_c)*Tz(z_c);

X(4,:) = 1;
X_c = H_p2c * X;

%% Plot position and velocity
t = 0:dt:(size(X_c,2)-1)*dt;
fig = figure;
axs = axes('Parent',fig);
hold(axs,'on')
plot(axs,t,X_c(1,:),'r');
plot(axs,t,X_c(2,:),'g');
plot(axs,t,X_c(3,:),'b');

%% Create simulation 
sim = URsim;
sim.Initialize('UR3');

%% Write
sim.Joints = [-0.95; -0.68; 1.1; -1.98; -1.69; 0.79];
for i = 1:size(X_c,2)
    H = Rx(pi);
    H(1:3,4) = X_c(1:3,i);
    
    
    sim.Pose = H;
    q(:,i) = sim.Joints;
end