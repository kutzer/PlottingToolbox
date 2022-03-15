function tf = isVisible(hndl)
% ISVISIBLE check to see if a given graphics handle is visible within a
% figure/axes.
%   tf = isVisible(hndl)
%
%   Inputs
%       hndl - MATLAB graphics handle
%
%   Outputs
%       tf - binary scalar stating whether the specified handle is visible
%
%   NOTE: This function can identify patch/line/surf/etc. objects that are
%         hidden (even with the 'Visible' property set to 'on') when when
%         hgtransform ancestors are hidden.
%
%   M. Kutzer, 15Mar2022, USNA

%% Check inputs
narginchk(1,1);

if ~ishandle(hndl)
    error('Input must be a valid graphics handle.')
end

%% Check for visibility
% Set initial value of output
tf = true;

% Initialize "parent" handle as self
mom = hndl;

% Check for objects at the top of the parent/child hierarchy
% -> We are looking for objects that cannot be the children of
%    hgtransform objects
%
% TODO - complete the cases in this list!
typ = get(mom,'Type');
switch lower( typ )
    case 'root'
        tf = true;
        return
    case 'figure'
        tf = tfVisibleProp(mom);
        return
    case 'axes'
        tf = tfVisibleProp(mom);
        return
    case 'uicontrol'
        tf = tfVisibleProp(mom);
        return
end

% Check for visibility of parent hierarchy
while ~isempty(mom)
    % Get type
    typ = get(mom,'Type');
    % NOTE: We are assuming that reaching the parent axes means we have 
    %       explored the entire hierarchy driving visibility
    switch lower( typ )
        case 'axes'
            return
    end

    tf_mom = tfVisibleProp(mom);
    if ~tf_mom && mom == hndl
        % Original handle is not visible
        tf = false;
        return
    end

    switch lower( typ )
        case 'hgtransform'
            % Parent hgtransform is not visible
            if ~tf_mom
                tf = false;
                return
            end
    end
    
    % Update parent
    mom = get(mom,'Parent');
end

end
%% Internal functions
function tf = tfVisibleProp(obj)
vis = get(obj,'Visible');
switch lower( vis )
    case 'on'
        tf = true;
    case 'off'
        tf = false;
    otherwise
        error('Unexpected visibility property value.');
end
end