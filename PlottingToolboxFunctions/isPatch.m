function [tf,msg] = isPatch(ptc)
% ISPATCH checks a specified variable to see if it is a valid patch object
% or a structured array containing the fields "Vertices" and "Faces"
%
%   [tf,msg] = isPatch(ptc)
%
%   Input(s)
%       ptc - M-element array of patch objects or an M-element structured
%             array containing the fields "Vertices" and "Faces".
%
%   Output(s)
%       tf  - M-element binary array indicating whether the input variable
%             elements are valid patch object(s) or valid structured
%             array(s).
%       msg - M-element cell array with each element containing a character
%             array describing the tf value returned.
%
%   M. Kutzer, 06Feb2024, USNA

% Update(s)
%   05Mar2024 - Made patch check for patch objects faster.

%% Check input(s)
narginchk(1,1);

%% Check for empty object
if isempty(ptc)
    tf = false;
    msg{1} = 'Invalid Patch - Input is empty.';
    return
end

%% Check if the object is a handle
tf_a = ishandle(ptc);
if any(tf_a)
    % Initialize handles cell array
    hndlType = cell( size(ptc) );
    hndlType(:) = {''};
    %hndlType(tf_a) = get(ptc(tf_a),'Type');
    hndlType(tf_a) = {ptc(tf_a).Type};
    tf = matches(hndlType,'patch');
    
    if nargout > 1
        msg = cell(size(ptc));
        msg(:) = {''};
        msg(~tf) = {'Handle is not a valid patch object.'};
    end
    return
end

%% Check for valid patch object or structured array

% Check if input is a structured array
if isstruct(ptc)
    % Check structured array fields
    if all( isfield(pp,{'Vertices','Faces'}) )
        % Correct fields are defined
        
        % Check elements vertices and faces
        for i = 1:numel(ptc)
            v = ptc(i).Vertices;
            f = ptc(i).Faces;
            
            if ~ismatrix(v) || ~ismatrix(f)
                tf(i) = false;
                msg{i} = 'Invalid Patch - Structured array element does not contain "Vertices" and "Faces" that are the proper dimensions.';
                continue
            end
            
            [mv,nv] = size(v);
            [mf,nf] = size(f);
            if ~any( nv == [2,3] )
                tf(i) = false;
                msg{i} = 'Invalid Patch - Structured array element vertices must be 2D or 3D.';
                continue;
            end
            
            % TODO - consider additional checks
            
            % Element is valid
            tf(i) = true;
            msg{i} = 'Valid Patch - Structured array element contains valid patch information.';
        end
        return
        
    else
        % Invalid
        tf = false(1,numel(ptc));
        str = 'Invalid Patch - Structured array element does not contain "Vertices" and "Faces" fields.';
        msg = repmat({str},1,numel(ptc));
        return
    end
end

% Check for patch object(s)
if any( ishandle(ptc) )
    for i = 1:numel(ptc)
        if matches( lower(class(ptc(i))), 'matlab.graphics.primitive.patch' )
            tf(i) = true;
            msg{i} = 'Valid Patch - Graphics object element is a valid patch object.';
        else
            tf(i) = false;
            msg{i} = 'Invalid Patch - Graphics object element is not a valid patch object.';
        end
    end
    return
else
    % Invalid
    tf = false;
    str = 'Invalid Patch - Specified element is not a valid patch object or structured array representation of a patch.';
    msg = {str};
    return
end
