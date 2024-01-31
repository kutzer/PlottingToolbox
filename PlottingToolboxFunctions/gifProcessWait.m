function gpTimer = gifProcessWait(varargin)
% GIFPROCESSWAIT users a timer to run a GIF while a process is running.
%
%   gpTimer = gifProcessWait(i,msg) initializes the figure and gif where 
%   "i" specifies the gif of choice
%
%   gpTimer = gifProcessWait(filename,msg) initializes the figure and a 
%   user specified gif. Note that not all gifs are compatible
%
%   gifProcessWait(gpTimer) closes the GIF following the process
%
%   Input(s)
%           i - scalar value specifying the default gif of choice
%                   0 - gif is randomly selected from available files
%                   1 - "The Hangover," Alan numbers scene gif
%                   2 - "Winnie the Pooh," Pooh thinking gif
%                   3 - "Little Rascals," Spanky waiting gif
%                   4 - "Alice in Wonderland," Alice waiting gif
%    filename - filename for custom GIF
%         msg - message to display with GIF
%     gpTimer - GIF timer (used for closing the GIF)
%
%   Output(s)
%       gpTimer - timer object used to run the GIF
%
%   Example:
%       gpTimer = gifProcessWait(0,'Please wait...');
%       pause(5)
%       gifProcessWait(gpTimer);
%
%   M. Kutzer, 31Jan2024, USNA

global gifProcessInfo

%% Check input(s)
narginchk(1,2);

%% Check if timer is being stopped
switch lower( class(varargin{1}) )
    case 'timer'
        stop(varargin{1});
        delete(varargin{1});
        return
end

%% Create gif
try
    gifProcessInfo.GIF = gifwait(varargin{:});
catch ME
    error(ME);
end

%% Create timer
gpTimer = timer('StartDelay',0,'Period',(1/(gifProcessInfo.GIF.fps)),...
    'TasksToExecute',1000,'BusyMode','drop','ExecutionMode','fixedRate',...
    'Name','GIF Process Timer (gifProcessInfo.m)',...
    'Tag','GIF Process Timer (gifProcessInfo.m)',...
    'ObjectVisibility','on');

gpTimer.StartFcn = @gifProcessCallbackStart;
gpTimer.StopFcn  = @gifProcessCallbackStop;
gpTimer.TimerFcn = @gifProcessCallback;
gpTimer.TimerFcn = @gifProcessCallback;
gpTimer.ErrorFcn = @gifProcessCallbackError;

start(gpTimer)

end

%% Internal functions
% -------------------------------------------------------------------------
function gifProcessCallbackStart(src,event)

global gifProcessInfo

if ishandle(gifProcessInfo.GIF.fig)
    gifwait(gifProcessInfo.GIF);
else
    stop(src);
end

end

% -------------------------------------------------------------------------
function gifProcessCallbackStop(src,event)

global gifProcessInfo

if ishandle(gifProcessInfo.GIF.fig)
    delete( gifProcessInfo.GIF.fig );
end

end

% -------------------------------------------------------------------------
function gifProcessCallback(src,event)

global gifProcessInfo

if ishandle(gifProcessInfo.GIF.fig)
    gifwait(gifProcessInfo.GIF);
else
    stop(src);
end


end

% -------------------------------------------------------------------------
function gifProcessCallbackError(src,event)

global gifProcessInfo

stop(src);

end

% -------------------------------------------------------------------------