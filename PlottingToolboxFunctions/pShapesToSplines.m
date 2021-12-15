function [pps,sEnds] = pShapesToSplines(pShapes,cont)
% PSHAPESTOSPLINES converts polyshape boundaries to a set of splines that
% are approximetely arc length parameterized using Euclidean distance
% between adjacent points.
%   pps = pShapesToSplines(pShapes)
%   pps = pShapesToSplines(pShapes,cont)
%   [pps,sEnds] = pShapesToSplines(___)
%
%   Input(s)
%       pShapes - 1xN array of polyshapes
%       cont - string defining C0 or C1 continuity (default C1)
%
%   Output(s)
%       pps   - 1xM cell array containing 2D cubic splines approximating
%               each boundary
%       sEnds - 1xM array containing the approximate arc length of each
%
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

% Update(s)
%   15Dec2021 - Included C0 and C1 continuity option.

plotsON = false;

%% Set default(s)
if nargin < 2
    cont = 'C1';
end

%% Check input(s)
switch lower( class(pShapes) )
    case 'polyshape'
        % Good input
    otherwise
        error('Input must be an array of one or more polyshapes.');
end

switch lower(cont)
    case 'c0'
        % Good
    case 'c1'
        % Good'
    otherwise
        warning('Continuity must be defined as either C0 or C1. Using default C1 value.');
        cont = 'C1';
end

%% Setup debug plot(s)
if plotsON
    fig = figure;
    axs = axes('Parent',fig);
    hold(axs,'on');
    daspect(axs,[1 1 1]);
    pltP = plot(axs,0,0,'k');
    pltV = plot(axs,0,0,'g');
    pltS = plot(axs,0,0,'m');
end

%% Fit splines
n = numel(pShapes);
for i = 1:n
    pShape = pShapes(i);            % Isolate ith polyshape
    b = numboundaries( pShape );    % Identify number of boundaries
    
    % Isolate vertices for each boundary
    for j = 1:b
        [x,y] = boundary(pShape,j);
        % Combine terms
        X = [x,y].';
        % Approximate vectors
        dXdk = diff(X,1,2);
        % Estimate arc length
        ds = sqrt( sum(dXdk.^2,1) );
        ds = [0, ds];
        s = cumsum(ds);
        % Estimate velocities
        dXdk_hat = dXdk./ds(2:end);
        % OPTION 1: Average enter/exit velocities
        dXds = [...
            dXdk_hat(:,1),...                                  % Vector for first
            (dXdk_hat(:,1:(end-1)) + dXdk_hat(:,2:end))./2,... % Vectors for intermediate(s)
            dXdk_hat(:,end)];                                  % Vector for last
        % OPTION 2: Use exit velicities
        %{
        dXds = [...
            dXdk_hat(:,1),...       % Vector for first
            dXdk_hat(:,1:(end))];  % Vectors for intermediate(s)
        %}
        
        % Apply unit vector requirement
        dXds = dXds./sqrt( sum(dXds.^2,1) );
        
        % Fit splines
        if (i == 1) && (j == 1)
            switch lower(cont)
                case 'c0'
                    pps = fitpp(s,X);
                case 'c1'
                    pps = fitpp(s,X,s,dXds);
                otherwise
                    error('Unrecognized continuity definition.');
            end
            sEnds = s(end);
        else
            switch lower(cont)
                case 'c0'
                    pps(end+1) = fitpp(s,X);
                case 'c1'
                    pps(end+1) = fitpp(s,X,s,dXds);
                otherwise
                    error('Unrecognized continuity definition.');
            end
            sEnds(end+1) = s(end);
        end
        
        % Debug plot
        if plotsON
            title(axs,sprintf('Polynomial %d of %d, Curve %d of %d',i,n,j,b));
            ss = linspace(0,sEnds(end),5000);
            XX = ppval(pps(end),ss);
            set(pltP,'XData', X(1,:),'YData', X(2,:));
            set(pltS,'XData',XX(1,:),'YData',XX(2,:));
            delete(pltV);
            for k = 1:size(dXds,2)
                pltV(k) = plot(axs,...
                    [X(1,k), X(1,k)+dXds(1,k)],...
                    [X(2,k), X(2,k)+dXds(2,k)],'r');
            end
            drawnow
            pause;
        end
    end
end