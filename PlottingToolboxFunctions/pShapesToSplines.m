function [pps,sEnds] = pShapesToSplines(pShapes)
% PSHAPESTOSPLINES converts polyshape boundaries to a set of splines that
% are approximetely arc length parameterized using Euclidean distance
% between adjacent points.
%   pps = pShapesToSplines(pShapes)
%
%   Input(s)
%       pShapes - 1xN array of polyshapes
%
%   Output(s)
%       pps   - 1xM cell array containing 2D cubic splines approximating 
%               each boundary
%       sEnds - 1xM array containing the approximate arc length of each 
%   Example(s)
%       msg = sprintf([...
%           '0123456789012345678901234567890123456789\n',...
%           '0123456789012345678901234567890123456789\n',...
%           '0123456789012345678901234567890123456789']);
%       width = 8*25.4; % 8" text width converted to mm
%       pShapes = textToPolyshapes(msg,width,[]);
%       pps = pShapesToSplines(pShapes)
%
%   See also textToPolyshapes
%
%   NOTE: This function uses the PiecewisePolynomialToolbox
%
%   M. Kutzer, 28Jul2021, USNA

%% Check input(s)
switch lower( class(pShapes) )
    case 'polyshape'
        % Good input
    otherwise
        error('Input must be an array of one or more polyshapes.');
end

%% Fit splines
for i = 1:numel(pShapes)
    pShape = pShapes(i);            % Isolate ith polyshape
    b = numboundaries( pShape );    % Identify number of boundaries 
    
    % Isolate vertices for each boundary
    for j = 1:b
        [x,y] = boundary(pShape,j);
        % Estimate arc length
        ds = sqrt( diff(x).^2 + diff(y).^2 );
        ds = [0; ds];
        s = cumsum(ds);
        
        if (i == 1) && (j == 1)
            pps = fitpp(s.', [x,y].');
            sEnds = s(end);
        else
            pps(end+1) = fitpp(s.', [x,y].');
            sEnds(end+1) = s(end);
        end
    end
end