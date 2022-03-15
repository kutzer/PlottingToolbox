function im = simulateImage(axs,params,H_a2c)
% SIMULATEIMAGE Simulate image of a specified axes handle given a
% projection matrix.
%   im = SIMULATEIMAGE(axs,params,H_a2c) returns a simulated image of
%   all objects contained in a specified axes object (axs) using camera
%   parameters and camera extrinsics.
%
%   Inputs:
%          axs - Axes handle containing environment for simulating image
%       params - MATLAB camera parameters or fisheye parameters
%         H_a2c - extrinsic matrix relating the global frame of axs to the 
%                camera axes
%          dpi - [Not Implemented] desired dots per inch 
%                (default is 96)
%
%   Outputs:
%       im - vpix x hpix RGB image
%
%   Example: Using Camera Parameters
%       im = simulateImage(axs,cameraParams,H_a2c);
%
%   Example: Use pinhole camera definition only
%       params.IntrinsicMatrix = cameraParams.IntrinsicMatrix;
%       params.ImageSize = cameraParams.ImageSize;
%       im = simulateImage(axs,cameraParams,H_a2c);
%
%   Example: Use Fisheye Parameters
%       im = simulateImage(axs,fisheyeParams,H_a2c);
%
%   See also plotCameraFOV
%
%   M. Kutzer, 18Feb2016, USNA

% Updates
%   05Jan2021 - Updated documentation
%   05Jan2021 - Add light (TODO - allow adjustable light position & color)
%   05Jan2021 - Faster implementation using getframe
%   26Apr2021 - Fully leverage camera parameters (except lens
%               distortion/model)
%   15Mar2022 - Updated to ignore children of hidden hgtransform objects
%   15Mar2022 - Updated to include image distortion using worldToImage.m
%   15Mar2022 - Updated to include examples

% TODO - account for pixels that are behind the camera

debugON = false;

%% Set defaults
narginchk(3,3);

%dpi = 96; % <--- Unused

%% Parse camera parameters
% TODO - allow the user to specify the intrinsic matrix only

% Define flags indicating use of camera/fisheye parameters
%   useParams - we are using camera/fisheye parameters
%   isFisheye - parameters are fisheye (applies to "apply distortion")
% Identify type of camera parameters
switch lower( class(params) )
    case 'cameraparameters'
        useParams = true;
        isFisheye = false;
        res = params.ImageSize;
        intrinsics = params;
    case 'fisheyeparameters'
        useParams = true;
        isFisheye = true;
        res = params.Intrinsics.ImageSize;
        intrinsics = params.Intrinsics;
    otherwise
        useParams = false;
        isFisheye = false;
        res = params.ImageSize;
        warning('"params" should be specified as a valid camera paramters or fisheye parameters (see cameraCalibrator.m)');
end

% Define image size
vpix = res(1);
hpix = res(2);

if ~useParams
    % Define intrinsics
    % - Camera frame relative to matrix frame
    A_c2m = transpose( params.IntrinsicMatrix );
    % Define extrinsics
    % - Axes frame relative to camera frame
    % H_a2c
    % Define projection
    P_a2m = A_c2m*H_a2c(1:3,:);
end

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
    % Check if kid is visible
    if ~isVisible(kid)
        continue
    end
    % Project visible kids into the simulated image
    switch lower( get(kid,'Type') )
        case {'patch','surface','line'}
            switch lower(get(kid,'Visible'))
                case 'on'
                    % Get data
                    x_k{1} = get(kid,'XData');
                    x_k{2} = get(kid,'YData');
                    x_k{3} = get(kid,'ZData');
                    % Get dimensions and reshape data
                    clear dim X_k
                    for i = 1:3
                        if ~isempty(x_k{i})
                            % Get data dimensions (assumes all surf data is [i,j])
                            dim{i} = size(x_k{i});
                            % Reshape for projection
                            X_k(i,:) = reshape(x_k{i},1,[]);
                        else
                            % Account for z-direction empty set
                            % TODO - This can be done better
                            if i > 1
                                dim{i} = dim{1};
                                X_k(i,:) = reshape(zeros(dim{1}),1,[]);
                            else
                                % Do nothing and hope the rest populates
                            end
                        end
                    end
                    % Get absolute transform
                    H_k2a = getAbsoluteTransform(kid);
                    % Project points
                    if useParams
                        % Use camera parameters (with distortion)
                        X_k(4,:) = 1;
                        % Define combine extrinsics
                        H_k2c = H_a2c*H_k2a;
                        % Define points relative to camera frame
                        X_c = H_k2c*X_k;
                        % Define image points
                        % -> rigid3d provides a "rigid3d" object
                        %    representing H_c2c (i.e. the identity) 
                        if isFisheye
                            X_m = worldToImage(...
                                intrinsics,...
                                rigid3d,...
                                X_c(1:3,:).');
                        else
                            X_m = worldToImage(...
                                intrinsics,...
                                rigid3d,...
                                X_c(1:3,:).',...
                                'ApplyDistortion',true);
                        end
                        X_m = X_m.';
                        z_c = X_c(3,:);
                    else
                        % Use pinhole model ignoring distortion
                        X_k(4,:) = 1;
                        sX_m = P_a2m*H_k2a*X_k;
                        % Account for scaling
                        z_c = sX_m(3,:);
                        X_m = sX_m./repmat(z_c,3,1);
                        % Apply lens distortion
                        % TODO - confirm distortion model
                        %X_m(1:2,:) = distortImagePoints(X_m(1:2,:),params);
                    end
                    % TODO - better address background foreground issues
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
if debugON
    set(pFig,'Visible','on');
    assignin('base','pFig',pFig);
    assignin('base','pAxs',pAxs);
else
    delete(pFig);
end
%set(pFig,'Visible','On','HandleVisibility','on');
