function g = gifwait(varargin)
% GIFWAIT plays a gif while a loop is running.
%   g = waitgif(i,msg) initializes the figure and gif where "i" specifies
%   the gif of choice
%       0 - gif is randomly selected from available files
%       1 - "The Hangover," Alan numbers scene gif
%       2 - "Winnie the Pooh," Pooh thinking gif
%       3 - "Little Rascals," Spanky waiting gif
%       4 - "Alice in Wonderland," Alice waiting gif
%
%   g = waitgif(filename,msg) initializes the figure and a user specified
%   gif. Note that not all gifs are compatible.
%
%   g = waitfig(g) updates the gif based on the time that has passed
%   between calls of gifwait.
%
%   Example:
%       g = gifwait(0,'Please wait...');
%       while true
%           g = gifwait(g);
%           if isempty(g)
%               break
%           end
%       end
%
%   M. Kutzer, 20Mar2020, USNA

%% Parse inputs
narginchk(1,2)

if nargin == 2
    % Define file name
    if ischar(varargin{1})
        filename = varargin{1};
    elseif isscalar(varargin{1})
        if varargin{1} == 0
            i = randi(4);
        elseif varargin{1} > 0 && varargin{1} < 5
            i = varargin{1};
        else
            error('The specified input must be between 0 and 4.');
        end
        %filename = fullfile('gifwait_data',sprintf('gifwait_wait%02d.gif',i));
        filename = sprintf('gifwait_wait%02d.gif',i);
    else
        error('The specified input is not a valid scalar or valid filename.');
    end
    
    if exist( filename ) ~= 2
        error('"%s" is not a valid filename.',filename);
    end
    
    % Load gif
    warning off
    try
        %fprintf('wait%02d.gif\n',i)
        [im,map] = imread( filename );
    catch
        error('"%s" is not compatible with imread.m, please choose another gif',filename);
    end
    g.im = im;
    g.map = map;
    warning on;
    
    % Initialize figure and axes
    g.fig = figure('Name',varargin{2},'MenuBar','None',...
        'ToolBar','None','Color',[1 1 1],'NumberTitle','off');
    g.axs = axes('Parent',g.fig);
    g.img = imshow(g.im(:,:,1,1),g.map,'Parent',g.axs);
    g.nFrames = size(g.im,4);
    g.fps = 10;
    g.now = now;
    
    set(g.fig,'Units','Pixels','Position',[10,10,size(g.im,2),size(g.im,1)]);
    centerfig(g.fig);
    set(g.axs,'Units','Normalized','Position',[0,0,1,1]);
    return
end

g = varargin{1};
if isempty(g) || ~ishandle(g.fig)
    warning('The gif has been closed. Please reinitialize...');
    g = [];
    return;
end

%% Update gif
newNow = now;                                   % get current system time
dt = (newNow - g.now)*1e5;                      % calculate change in time
frame = mod(round(dt * g.fps),g.nFrames) + 1;   % define current frame

%fprintf('dt = %.5f | frame = %d\n',dt,frame);

set(g.img,'CData',g.im(:,:,1,frame));
drawnow;