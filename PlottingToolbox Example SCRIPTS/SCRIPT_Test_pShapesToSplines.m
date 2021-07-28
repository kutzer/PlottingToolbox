%% SCRIPT_Test_pShapesToSplines
clear all
close all
clc

%% Define message & create polyshapes
msg = sprintf([...
    '0123456789012345678901234567890123456789\n',...
    '0123456789012345678901234567890123456789\n',...
    '0123456789012345678901234567890123456789']);
width = 8*25.4; % 8" text width converted to mm
%height = 4*25.4; % 4" text height converted to mm
height = [];
pShapes = textToPolyshapes(msg,width,height);

%% Fit splines
pps = pShapesToSplines(pShapes);

%% Define path parameters
speed = 50; % desired linear speed (mm/s)
dt = 0.01;  % desired time step (s)

%% Define z-offset for transitions between paths
z = 15; % mm
sf = z;
tf = sf/speed;
t = 0:dt:tf;
s = speed*t;

pZ_up = polyfit([0,sf],[0,z],1); % polynomial transitioning from 0 to z
pZ_dn = polyfit([0,sf],[z,0],1); % polynomial transitioning from z to 0

z_up = polyval(pZ_up,s);
z_dn = polyval(pZ_dn,s);

%%
X = []; % initialize discrete path
M = numel(pps);
for i = 1:numel(pps)
    % Isolate piecewise polynomial
    pp = pps(i);
    % Define parameterization end-point
    sf = pp.breaks(end);
    % Define end-time
    tf = sf/speed;
    
    % Discretize time using dt
    t = 0:dt:tf;
    % Discretize arc length as a function of time
    s = speed*t;
    % Evaluate polynomial
    X_b = ppval(pp,s);
    X_b(3,:) = 0;
    
    % Define transition down
    X_a = repmat(X_b(1:2,1),1,numel(z_dn));
    X_a(3,:) = z_dn;
    
    % Define transition up
    X_c = repmat(X_b(1:2,end),1,numel(z_up));
    X_c(3,:) = z_up;
    
    if i < M
        % Define transition between splines
        pp_Next = pps(i+1);
        X_d_f = ppval(pp_Next,0);
        X_d_f(3,:) = X_c(3,end);
        
        % Define transition
        sf = norm( X_d_f - X_c(:,end) );
        tf = sf/speed;
        t = 0:dt:tf;
        s = speed*t;
        pX_d = polyfit([0,sf],[X_c(1,end),X_d_f(1,1)],1);
        pY_d = polyfit([0,sf],[X_c(2,end),X_d_f(2,1)],1);
        pZ_d = polyfit([0,sf],[X_c(3,end),X_d_f(3,1)],1);
        x_d = polyval(pX_d,s);
        y_d = polyval(pY_d,s);
        z_d = polyval(pZ_d,s);
        X_d = [x_d; y_d; z_d];
    else
        X_d = [];
    end
    
    % Combine path
    X = [X, X_a, X_b, X_c, X_d];
end

%% Visualize results
fig = figure;
axs = axes('Parent',fig);
daspect(axs,[1 1 1]);
hold(axs,'on');
view(axs,3);
plt = plot3(X(1,:),X(2,:),X(3,:),'Parent',axs);

%% Animate
for i = 1:size(X,2)
    set(plt,'XData',X(1,1:i),'YData',X(2,1:i),'ZData',X(3,1:i));
    drawnow;
end