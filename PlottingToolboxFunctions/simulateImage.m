function im = simulateImage(axs,params,H,vpix,hpix,dpi)
% SIMULATEIMAGE Simulate image of a specified axes handle given a
% projection matrix.
%   im = SIMULATEIMAGE(axs,params,H,vpix,hpix) returns a simulated
%   image of all objects contained in a specified axes object (axs) using
%   camera parameters, camera extrinsics, image dimensions (vpix and hpix)
%   and an optional dots per inch paramter.
%
%   Inputs:
%       params - MATLAB camera parameters
%            H - extrinsic matrix relating the global frame of axs to the 
%                camera axes
%         vpix - number of vertical pixels (default is 480)
%         hpix - number of horizontal pixels (default is 640)
%          dpi - [OPTIONAL, Unused] desired dots per inch (default is 96)
%
%   Outputs:
%       im - vpix x hpix RGB image
%
% M. Kutzer, 18Feb2016, USNA

% Updates
%   05Jan2021 - Updated documentation
%   05Jan2021 - Add light (TODO - allow adjustable light position & color)
%   05Jan2021 - Faster implementation using getframe
%% Set defaults
if nargin < 6
    %dpi = 200;
    dpi = 96;
end
if nargin < 5
    %hpix = 1280;
    hpix = 640;
end
if nargin < 4
    %vpix = 1024;
    vpix = 480;
end

%% Parse camera parameters
% TODO - allow the user to specify the intrinsic matrix only
A_C2M = transpose( params.IntrinsicMatrix );
H_A2C = H;
P_A2M = A_C2M*H_A2C(1:3,:);

%% Setup new figure
pFig = figure('Visible','off','HandleVisibility','off',...
    'Tag','simulateImage','Name','simulateImage');
pAxs = axes('Parent',pFig,'Tag','simulateImage');

%{
% --- OPTION 1 (slow): Setup figure for saving an image -------------------
% Setup for saving correct image dimensions
hdims = [hpix/vpix,hpix/hpix];  % dimensions for choosing horizontal figure size
vdims = [vpix/vpix,vpix/hpix];  % dimensions for choosing vertical figure size

set(pFig,'Units','normalized','Position',[0,0,min(hdims),min(vdims)]);
set(pFig,'PaperUnits','Inches','PaperPosition',[0,0,hpix/dpi,vpix/dpi]);
set(pFig,'InvertHardCopy','off');
set(pAxs,'Units','normalized','Position',[0,0,1,1]);
% -------------------------------------------------------------------------
%}

% --- OPTION 2 (fast): Setup figure for using getframe --------------------
set(pAxs,'Units','Normalized','Position',[0,0,1,1]);
set(pFig,'Units','Pixels');
pos = get(pFig,'Position');
set(pFig,'Position',[pos(1:2),hpix,vpix]);
centerFigure(pFig);
% -------------------------------------------------------------------------

set(pFig,'Color',[1,1,1]);
set(pAxs,'Visible','Off','yDir','Reverse');
hold(pAxs,'on');
daspect(pAxs,[1,1,1]);
xlim(pAxs,[0,hpix]);
ylim(pAxs,[0,vpix]);

pLgt = addSingleLight(pAxs);
set(pLgt,'Position',[1,0,1]);

%% Get list of all children
kids = findall(axs);
for idx = 1:numel(kids)
    kid = kids(idx);
    switch lower( get(kid,'Type') )
        case {'patch','surface','line'}
            switch lower(get(kid,'Visible'))
                case 'on'
                    % Get data
                    x{1} = get(kid,'XData');
                    x{2} = get(kid,'YData');
                    x{3} = get(kid,'ZData');
                    % Get dimensions and reshape data
                    clear dim X
                    for i = 1:3
                        if ~isempty(x{i})
                            % Get data dimensions (assumes all surf data is [i,j])
                            dim{i} = size(x{i});
                            % Reshape for projection
                            X(i,:) = reshape(x{i},1,[]);
                        else
                            % Account for z-direction empty set
                            % TODO - This can be done better
                            if i > 1
                                dim{i} = dim{1};
                                X(i,:) = reshape(zeros(dim{1}),1,[]);
                            else
                                % Do nothing and hope the rest populates
                            end
                        end
                    end
                    % Get absolute transform
                    H = getAbsoluteTransform(kid);
                    % Project points
                    X(4,:) = 1;
                    sXp = P_A2M*H*X;
                    % Account for scaling
                    s = sXp(3,:);
                    Xp = sXp./repmat(s,3,1);
                    % Apply lens distortion
                    % TODO - confirm distortion model
                    Xp(1:2,:) = distortImagePoints(Xp(1:2,:),params);
                    % TODO - address background foreground issues
                    Xp(3,:) = -s; % This may help
                    % Get new data
                    for i = 1:3
                        xp{i} = reshape(Xp(i,:),dim{i});
                    end
                    % Copy object and update data
                    newkid = copyobj(kid,pAxs);
                    % Update data
                    set(newkid,'XData',xp{1});
                    set(newkid,'YData',xp{2});
                    set(newkid,'ZData',xp{3});
                otherwise
                    % Ignore
            end
        otherwise
            % Ignore
    end
end

%{
% --- OPTION 1 (slow): Setup figure for saving an image -------------------
%% Save and load image
% TODO - replace print & imread with getframe or equivalent
i = 0;
fname = sprintf('tempSimImage%d.png',i);
%print(sprintf('-f%f',pFig),'-dpng',fname,sprintf('-r%d',dpi));
print(sprintf('-f%f',get(pFig,'Number')),'-dpng',fname,sprintf('-r%d',dpi));

im = imread(fname);
%delete(fname);
% -------------------------------------------------------------------------
%}

% --- OPTION 2 (fast): Setup figure for using getframe --------------------
im_struct = getframe(pFig);
im = im_struct.cdata;
% -------------------------------------------------------------------------

%% Close pFig
delete(pFig);
%set(pFig,'Visible','On','HandleVisibility','on');
