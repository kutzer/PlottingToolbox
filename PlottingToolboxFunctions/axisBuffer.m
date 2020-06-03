function axisBuffer(varargin)
% AXISBUFFER adjusts the axes limits to add a buffer around the items
% rendered.
%   axisBuffer applies a default buffer of 0.3 to the current axes.
%
%   axisBuffer(b) applies a buffer specified in b to the current axes.
%
%   axisBuffer(axs) applies a default buffer of 0.3 to the specified axes. 
%
%   axisBuffer(axs,b) applies a specified buffer to the specified axes.
%
%   M. Kutzer, 02Jun2020, USNA

%% Check input(s)
narginchk(0,2)

switch nargin
    case 0
        axs = gca;
        b = 0.3;
    case 1
        if ishandle(varargin{1})
            axs = varargin{1};
            b = 0.3;
        else
            axs = gca;
            b = varargin{1};
        end
    case 2
        axs = varargin{1};
        b = varargin{2};
end

if ~ishandle(axs)
    error('Specified axes must be a valid axes handle.');
else
    switch lower( get(axs,'type') )
        case 'axes'
            % Good!
        otherwise
            error('Specified axes must be a valid axes handle.');
    end
end

if numel(b) ~= 1
    error('The specified buffer must be a scalar value.');
end

%% Apply buffer
axis(axs,'tight');
drawnow;
a = reshape(axis(axs),2,[]);
%da = diff(a,1,1);
c = sum(a,1)./2;
a_o = a - repmat(c,2,1);
a_new = (1+b)*a_o + repmat(c,2,1);
a_new = reshape(a_new,1,[]);
axis(axs,a_new);