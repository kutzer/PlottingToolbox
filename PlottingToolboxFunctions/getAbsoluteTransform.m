function H = getAbsoluteTransform(obj)
% GETABSOLUTETRANSFORM calculates the transformation of an object relative
% to the global frame. This assumes a parent/child relationship using
% hgtransform objects.
%
% M. Kutzer, 17Feb2016, USNA

%% Check inputs
narginchk(1,1);
if ~ishandle(obj)
    error('Specified input must be a valid graphics object handle.');
end

%% 
isRoot = false;

mom = obj;
H = eye(4);
while ~isRoot
    switch lower( get(mom,'Type') )
        case 'hgtransform'
            % Compile transform
            H = get(mom,'Matrix') * H;
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