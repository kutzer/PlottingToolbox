function plt = projectTriad(varargin)
% PROJECTTRIAD projects a triad representation of a coordinate frame into
% an image.
%   plt = projectTriad(P_t2m,sc)
%   ___ = projectTriad(axs,P_t2m,sc)
%   ___ = projectTriad(axs,P_t2m,sc,tfFalseDepth)
%
%   Input(s)
%            axs - [OPTIONAL] handle of project triad's parent. 
%          P_t2m - 3x4 array defining a projection matrix.
%             sc - scalar value defining triad scale
%   tfFalseDepth - [OPTIONAL] logical scalar indicating whether or not to
%                  use "false depth" in the projection.
%       tfFalseDepth = true [DEFAULT] 
%       tfFalseDepth = false
%
%   Output(s)
%       plt - 1x3 array of line objects defining the projected triad
%
%   See also projectWithFalseDepth
%
%   M. Kutzer, 06Mar2025, USNA

%% Parse input(s)
narginchk(2,4);
% Define parent
if numel(varargin{1}) == 1 && ishandle(varargin{1})
    axs = varargin{1};
    varargin(1) = [];
else
    axs = gca;
end

switch numel(varargin)
    case 2
        P_t2m = varargin{1};
        sc = varargin{2};
        tfFalseDepth = true;
    case 3
        P_t2m = varargin{1};
        sc = varargin{2};
        tfFalseDepth = varargin{3};
end
ax = ancestor(axs, 'axes');
hold(ax,'on');

%% Define points
p_t = sc.*[zeros(3,1),eye(3)];
p_t(4,:) = 1; % Make homogeneous

%% Project points
if tfFalseDepth
    p_m = projectWithFalseDepth(p_t,P_t2m);
else
    tilde_p_m = P_t2m*p_t;
    z_c = tilde_p_m(3,:);
    p_m = tilde_p_m./z_c;
end

%% Plot result
colors = 'rgb';
for i = 1:3
    if tfFalseDepth
        plt(i) = plot3(axs,p_m(1,[1,i+1]),p_m(2,[1,i+1]),p_m(3,[1,i+1]),...
            colors(i),'LineWidth',1.5);
    else
        plt(i) = plot(axs,p_m(1,[1,i+1]),p_m(2,[1,i+1]),colors(i),...
            'LineWidth',1.5);
    end
end
