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
%       obj - hgtransform object (same as input)
%
% M. Kutzer, 17Feb2016, USNA

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

%% Define family tree and absolute transform
isRoot = false;

mom = obj;
idx = 0;
H = eye(4);
while ~isRoot
    switch lower( get(mom,'Type') )
        case 'hgtransform'
            % Compile transform
            idx = idx+1;
            H_i2j{idx} = get(mom,'Matrix');
            H_j2i{idx} = invSE(H_i2j{idx});
            H = H_i2j{idx} * H;
            familyTree(idx) = mom;
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
familyTree = fliplr(familyTree);
for i = 1:(numel(familyTree)-1)
    set(familyTree(i),'Parent',familyTree(i+1),'Matrix',H_j2i{i});
end
set(familyTree(end),'Parent',axs,'Matrix',H);