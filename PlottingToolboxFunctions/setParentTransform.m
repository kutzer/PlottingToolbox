function familyTree = setParentTransform(obj,axs)
% SETPARENTTRANSFORM changes the parent/child relationships and associated 
% transformations to define a designated hgtransform object as the parent.
%   setParentTransform(obj)
%   setParentTransform(obj,mom)
%   familyTree = setParentTransform(___)
%
%   Input(s)
%       obj - hgtransform object
%       axs - [OPTIONAL] parent for new parent transform
%
%   Output(s)
%       familyTree - array of hgtransform objects starting with obj
%           familyTree(1)
%
% M. Kutzer, 26Mar2024, USNA

debug = true;

%% Check inputs
narginchk(1,2);
if ~ishandle(obj)
    error('Specified input must be a valid graphics object handle.');
end

if ~matches(lower(get(obj,'Type')),'hgtransform')
    error('Input must be an hgtransform object');
end

if nargin < 2
    axs = ancestor(obj,'Axes');
end

%% Setup debug
if debug
    dAxs = ancestor(axs,'Axes');
    XX(1,:) = xlim(dAxs);
    XX(2,:) = ylim(dAxs);
    XX(3,:) = zlim(dAxs);
    
    dX = diff(XX,1,2);
    sc = (1/5)*min(dX);
end

%% Define family tree and absolute transform
isRoot = false;

mom = obj;
idx = 0;
H_c2w = eye(4);
while ~isRoot
    switch lower( get(mom,'Type') )
        case 'hgtransform'
            % Compile transforms
            idx = idx+1;
            % -> Child to parent
            H_c2p{idx} = get(mom,'Matrix');
            % -> Parent to child
            H_p2c{idx} = invSE(H_c2p{idx});
            % -> First child to world (axs)
            H_c2w = H_c2p{idx} * H_c2w;
            familyTree(idx) = mom;
            
            if debug
                h_c2p(idx) = triad('Parent',mom,'Matrix',eye(4),'Scale',sc,...
                    'LineWidth',1.5,'AxisLabels',{...
                    sprintf('x_{%d}',idx),...
                    sprintf('y_{%d}',idx),...
                    sprintf('z_{%d}',idx)});
            end
        case 'axes'
            isRoot = true;
            break;
        case 'figure'
            isRoot = true;
            break
        case 'root'
            isRoot = true;
            break;
        otherwise
            % Keep working through the list family tree
    end
    mom = get(mom,'Parent');
end

%% Initialize common parent
set(familyTree,'Parent',axs);

%% Change family tree
% -> The new trunk of the family tree is familyTree(1)
% -> The old trunk of the family tree is familyTree(n)
n = numel(familyTree);
for i = n:-1:2
    set(familyTree(i),'Parent',familyTree(i-1),'Matrix',H_p2c{i-1});
end
set(familyTree(1),'Parent',axs,'Matrix',H_c2w);