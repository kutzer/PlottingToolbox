function obj = setParentTransform(obj)
% SETPARENTTRANSFORM changes the parent/child relationships and associated 
% transformations to define a designated hgtransform object as the parent.
%   setParentTransform(obj)
%   obj = setParentTransform(___)
%
%   Input(s)
%       obj - hgtransform object
%   
%   Output(s)
%       obj - hgtransform object (same as input)
%
% M. Kutzer, 17Feb2016, USNA

%% Check inputs
narginchk(1,1);
if ~ishandle(obj)
    error('Specified input must be a valid graphics object handle.');
end

if ~matches(lower(get(obj,'Type')),'hgtransform')
    error('Input must be an hgtransform object');
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
            H = get(mom,'Matrix') * H;
            idx = idx+1;
            familyTree(idx) = mom;
        case 'axes'
            isRoot = true;
            return;
        case 'figure'
            isRoot = true;
            return
        case 'root'
            isRoot = true;
            return;
        otherwise
            % Keep working through the list family tree
    end
    mom = get(mom,'Parent');
end

%% Change family tree
familyTree = fliplr(familyTree);
for i = 1:(numel(familyTree)-1)
    H_i2j = get(familyTree,'Matrix');
    H_j2i = invSE(H_i2j);

    set(familyTree(i),'Parent',familyTree(j),'Matrix',H_j2i);
end
set(familyTree(end),'Matrix',H);