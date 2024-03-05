function varargout = projectWithFalseDepth(p_f,P_f2m,varargin)
% PROJECTWITHFALSEDEPTH projects an array of points or patch objects to the
% matrix frame an creates a scaled, false depth for rendering.
%
% ------------------ USE CASE 1: Projecting points ------------------------
%   p_m = projectWithFalseDepth(p_f,P_f2m)
%
%   [p_m,obj_m] = projectWithFalseDepth(p_f,P_f2m,axs)
%
%   Input(s)
%       p_f   - 3xN array of points defined relative to a given frame f or
%               4xN array of homogeneous points defined relative to frame f
%       P_f2m - 3x4 projection matrix relating frame f to the matrix frame
%               (frame m)
%       axs   - [OPTIONAL] desired parent graphics for new patch objects
%
%   Output(s)
%       p_m   - 3xN array containing x/y pixel coordinates with an appended
%               "false depth" value for rendering.
%       obj_m - [OPTIONAL] line object child of the parent graphics object 
%
% ------------------ USE CASE 2: Projecting patch object ------------------
%   ptc_m = projectWithFalseDepth(ptc_f,P_f2m)
%
%   [ptc_m,obj_m] = projectWithFalseDepth(ptc_f,P_f2m,axs)
%
%   Input(s)
%       ptc_m - M-element array of patch objects defined relative to a 
%               given frame f
%       P_f2m - 3x4 projection matrix relating frame f to the matrix frame
%               (frame m)
%       axs   - [OPTIONAL] desired parent graphics for new patch objects
%
%   Output(s)
%       ptc_m - M-element structured array of containing "Faces" and 
%               "Vertices" fields describing the vertices defined 
%               using x/y pixel location with an appended "false depth" 
%               value for rendering.
%       obj_m - [OPTIONAL] patch object(s) child(ren) of the parent 
%               graphics object 
%
%   M. Kutzer, 25Oct2021, USNA

% Update(s)
%   06Feb2024 - Updated to parse and check inputs

%% Parse input(s)
narginchk(2,3);

tfPatch = false;
switch class(p_b)
    case 'double'
        if size(p_f,1) == 4
            p_f = p_f(1:3,:);
        end
        if size(p_f,1) ~= 3
            error('3D points ("p_f") must be defined as a 3xN array.');
        end
        
        % Update patch
        ptc_f = [];
    otherwise
        % Check for patch input
        tfChk = isPatch(p_f);
        if any( tfChk )
            % Define valid patch objects
            ptc_f = p_f(tfChk);
            
            % Display ignored elements to user
            if any( ~tfChk )
                for i = find(~tfChk)
                    fprintf('Ignoring element %d - ptc_f(%d) is not a valid patch object.\n',i,i);
                end
            end
            
            % Update point(s)
            p_f = [];
            tfPatch = true;
        end
end

% Check projection matrix
msg = 'Projection matrix must be a 3x4 array.';
if ~ismatrix(P_f2m)
    error(msg);
else
    [m,n] = size(P_f2m);
    if m ~= 3 || n ~= 4
        error(msg);
    end
end

% Check optional parent
tfPlot = false;
if nargin >= 3
    axs = varargin{1};
    
    msg = 'Specified object must be a valid parent for a line or patch object.';
    if ~ishandle(axs)
        error(msg);
    else
        % TODO - Do this better
        try 
            pltTST = plot(axs,0,0,'Visible','off');
        catch
            error(msg);
        end
        
        % Make sure the axes containing the parent has is adding next plot
        mom = ancestor(axs,'Axes');
        set(mom,'NextPlot','add');
        
        % Update plotting flag
        tfPlot = true;
    end
    
end

%% Project points
if ~tfPatch
    % Calculate projected points
    [p_m,tilde_p_m,maxTilde_z_m] = projPnts(p_f,P_f2m);
    
    % Initialize false depth points
    p_m_falseDepth = p_m;
    
    % Add false depth
    p_m_falseDepth(3,:) = -tilde_p_m(3,:) + maxTilde_z_m;
    
    % Package output(s)
    varargout{1} = p_m_falseDepth;
    
    if ~tfPlot
        return
    end
end

%% Project patch objects
if tfPatch
    for i = 1:numel(ptc_f)
        % Get vertices
        p_f = ptc_f(i).Vertices.';
        
        % Calculate projected points
        [p_m,tilde_p_m,maxTilde_z_m(i)] = projPnts(p_f,P_f2m);
    
        % Define patch referenced to matrix frame
        ptc_m(i).Faces = ptc_f(i).Faces;
        ptc_m(i).Vertices = p_m.';
        ptc_m(i).Vertices(:,3) = -tilde_p_m(3,:);
    end
    
    % Account for common false depth
    maxTilde_z_m = max( maxTilde_z_m );
    for i = 1:numel(ptc_m)
        ptc_m(i).Vertices = ptc_m(i).Vertices + maxTilde_z_m;
    end
    
    % Package output(s)
    varargout{1} = ptc_m;
    
    if ~tfPlot
        return
    end
end

%% Plot (if applicable)
if tfPlot
    % Plot points
    if ~tfPatch
        % TODO - make these nicer
        plt_m = plot(axs,p_m_falseDepth(1,:),p_m_falseDepth(2,:),p_m_falseDepth(3,:),'.');
        
        if nargout > 1
            varargout{2} = plt_m;
        end
    end
    
    % Plot patch objects
    if tfPatch
        for i = 1:numel(ptc_m)
            obj_m(i) = patch(axs,ptc_m(i),'EdgeColor','none','FaceColor',rand(1,3));
        end
        if nargout > 1
            varargout{2} = obj_m;
        end
    end
end
end

%% Internal functions 

% -------------------------------------------------------------------------
function [p_m,tilde_p_m,maxTilde_z_m] = projPnts(p_f,P_f2m)
    p_f(4,:) = 1;
    tilde_p_m = P_f2m * p_f;
    
    p_m = tilde_p_m./tilde_p_m(3,:);
    
    maxTilde_z_m = max(tilde_p_m(3,:));
end