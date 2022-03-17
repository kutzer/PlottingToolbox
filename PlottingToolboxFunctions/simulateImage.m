function im = simulateImage(axs,params,H_a2c)
% SIMULATEIMAGE Simulate image of a specified axes handle given a
% projection matrix.
%   im = SIMULATEIMAGE(axs,params,H_a2c) returns a simulated image of
%   all objects contained in a specified axes object (axs) using camera
%   parameters and camera extrinsics.
%
%   Inputs:
%          axs - Axes handle containing environment for simulating image
%       params - MATLAB camera parameters, fisheye parameters, or
%                structured array containing fields "IntrinsicMatrix" and
%                "ImageSize".
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
%   Example: Use pinhole camera definition only (ignore distortion)
%       params.IntrinsicMatrix = cameraParams.IntrinsicMatrix;
%       params.ImageSize = cameraParams.ImageSize;
%       im = simulateImage(axs,params,H_a2c);
%
%   Example: Use Fisheye Parameters
%       im = simulateImage(axs,fisheyeParams,H_a2c);
%
%   See also plotCameraFOV
%
%   Known Issues:
%       (1) When using Camera Parameters that include non-zero distortion,
%           objects close to the camera that are outside of the camera FOV
%           appear in the foreground of the image.
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
%   15Mar2022 - Updated to check for user-defined parameters
%   16Mar2022 - Updated to remove points lying behind the camera
%   17Mar2022 - Updated to place light in image simulation in a position
%               matching the simulation

% TODO - address foreground issue!

%% Debug flag
% NOTE: When debugON = true, the variables "pFig" and "pAxs" are assigned
%       to the base workspace. These handles are associated with the
%       simulated figure and axes handles.
% See: ..\PlottingToolbox Example SCRIPTS\SCRIPT_Test_simulateImage
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
        % MATLAB Camera Parameters
        useParams = true;
        isFisheye = false;
        res = params.ImageSize;
        intrinsics = params;
    case 'fisheyeparameters'
        % MATLAB Fisheye Parameters
        useParams = true;
        isFisheye = true;
        res = params.Intrinsics.ImageSize;
        intrinsics = params.Intrinsics;
    otherwise
        % User-defined intrinsics & image size
        if ~isstruct(params)
            error('"params" must be a camera/fisheye parameters variable or structured array');
        end

        rq_fields = {'ImageSize','IntrinsicMatrix'};
        bin = isfield(params,rq_fields);
        if nnz(bin) ~= numel(bin)
            error('User-defined "params" must include the fields "ImageSize" and "IntrinsicMatrix".');
        end

        useParams = false;
        isFisheye = false;
        res = params.ImageSize;
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

%% Get current light and light position
% Existing light in current axes (adds light if no light exists)
%
% TODO - Consider checking if a light exists and only adding if one does
lgt = addSingleLight(axs);

% Light position relative to simulation axes frame
pLgt_a = get(lgt,'Position').';
pLgt_a(4,:) = 1;

% Define light position relative to camera frame
pLgt_c = H_a2c*pLgt_a;

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
%set(pLgt,'Position',[1,0,1]);

% Match lighting position to simulation
if useParams
    if isFisheye
        xLgt_m = worldToImage(...
            intrinsics,...
            rigid3d,...
            pLgt_c(1:3,:).');
        z_c = pLgt_c(3,:);
    else
        xLgt_m = worldToImage(...
            intrinsics,...
            rigid3d,...
            pLgt_c(1:3,:).',...
            'ApplyDistortion',true);
        z_c = pLgt_c(3,:);
    end
else
    % Use pinhole model ignoring distortion
    sxLgt_m = A_c2m*pLgt_c;
    % Account for scaling
    z_c = sxLgt_m(3,:);
    xLgt_m = sxLgt_m./repmat(z_c,3,1);
end
% Append artificial depth
xLgt_m(3,:) = z_c;
% Set light postion
set(pLgt,'Position',xLgt_m(1:3).');

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
                    end

                    % Apply simulated depth to image
                    % -> This allows projected points closer to the camera
                    %    to occlude points farther from the camera. This
                    %    also allows lighting to provide the appearance of
                    %    depth
                    %
                    % TODO - better address background/foreground rendering
                    X_m(3,:) = z_c;

                    % Remove projected points behind the camera
                    % -> Remove vertices with a negative z_c
                    %
                    % TODO - consider keeping points contained on faces
                    %        partially infront of the camera. This current
                    %        approach may yield a saw-tooth pattern along
                    %        the edge of the image for objects close to the
                    %        camera.
                    bin = z_c < 0;
                    X_m(:,bin) = nan;

                    if useParams
                        % Remove projected points outside the known image
                        % resolution
                        %
                        % TODO - consider keeping points contained on faces
                        %        partially within the image
                        bin =...
                            (X_m(1,:) < 0 | X_m(1,:) > hpix) | ...
                            (X_m(2,:) < 0 | X_m(2,:) > vpix);
                        X_m(:,bin) = nan;
                    end
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
    set(pFig,'Visible','on','HandleVisibility','on');
    assignin('base','pFig',pFig);
    assignin('base','pAxs',pAxs);
else
    delete(pFig);
end
%set(pFig,'Visible','On','HandleVisibility','on');
