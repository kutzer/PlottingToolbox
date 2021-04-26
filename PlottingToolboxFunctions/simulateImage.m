function im = simulateImage(axs,params,H_a2c)
% SIMULATEIMAGE Simulate image of a specified axes handle given a
% projection matrix.
%   im = SIMULATEIMAGE(axs,params,H_c2a,dpi) returns a simulated image of
%   all objects contained in a specified axes object (axs) using camera
%   parameters and camera extrinsics.
%
%   Inputs:
%       params - MATLAB camera parameters
%         H_a2c - extrinsic matrix relating the global frame of axs to the 
%                camera axes
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
%   26Apr2021 - Fully leverage camera parameters

%% Set defaults
if nargin < 6
    %dpi = 200;
    dpi = 96;
end

%% Parse camera parameters
% TODO - allow the user to specify the intrinsic matrix only
% Define image size
vpix = params.ImageSize(1);
hpix = params.ImageSize(2);
% Define intrinsics
% - Camera frame relative to matrix frame
A_c2m = transpose( params.IntrinsicMatrix );
% Define extrinsics
% - Axes frame relative to camera frame
% H_a2c
% Define projection
P_a2m = A_c2m*H_a2c(1:3,:);

%% Setup new figure
pFig = figure('Visible','off','HandleVisibility','off',...
    'Tag','simulateImage','Name','simulateImage');
pAxs = axes('Parent',pFig,'Tag','simulateImage');

set(pFig,'Units','Pixels','Position',[0,0,hpix,vpix],...
    'Color',[1,1,1]);
centerFigure(pFig);
set(pAxs,'Units','Normalized','Position',[0,0,1,1],'Visible','Off',...
    'yDir','Reverse','zDir','Reverse');

hold(pAxs,'on');
daspect(pAxs,[1,1,1]);
xlim(pAxs,[0.5,0.5] + [0,hpix]);
ylim(pAxs,[0.5,0.5] + [0,vpix]);

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
                    H_k2a = getAbsoluteTransform(kid);
                    % Project points
                    X(4,:) = 1;
                    sX_m = P_a2m*H_k2a*X;
                    % Account for scaling
                    z_c = sX_m(3,:);
                    X_m = sX_m./repmat(z_c,3,1);
                    % Apply lens distortion
                    % TODO - confirm distortion model
                    X_m(1:2,:) = distortImagePoints(X_m(1:2,:),params);
                    % TODO - address background foreground issues
                    X_m(3,:) = z_c;
                    % Get new data
                    for i = 1:3
                        xp{i} = reshape(X_m(i,:),dim{i});
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

%% Get the image
im_struct = getframe(pFig);
im = im_struct.cdata;
% Check if image is correct size and resize as needed
% - Older versions of MATLAB create an image that is twice the size of the
%   actual pixel size of the figure when using getframe.m
if ( size(im,1) ~= vpix ) || ( size(im,2) ~= hpix ) 
    im = imresize(im,[vpix,hpix]);
end

%% Close pFig
delete(pFig);
%set(pFig,'Visible','On','HandleVisibility','on');
