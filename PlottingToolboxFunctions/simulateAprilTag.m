function tagInfo = simulateAprilTag(tagFamily,tagID,tagSize)
% SIMULATEAPRILTAG creates a simulated AprilTag using pre-generated
% AprilTag 3 families available in the AprilRobotics/apriltag-imgs Github
% repository.
%   tagInfo = simulateAprilTag(tagFamily,tagID,tagSize)
%
%   Inputs:
%       tagFamily - character array specifying the AprilTag family (must
%                   exist apriltag-imgs)
%       tagID     - scalar integer specifying AprilTag ID (must exist
%                   apriltag-imgs)
%       tagSize   - positive scalar value specifying the AprilTag size
%                   (e.g. in millimeters)
%
%   Outputs:
%       tagInfo - structured array containing AprilTag information 
%           *.Family - character array specifying the AprilTag family
%           *.ID     - scalar integer specifying AprilTag ID
%           *.Size   - scalar value specifying the AprilTag size
%           *.Location - 4x2 array containing the x/y corners of the tag
%                        associated with the tagSize
%           *.Boundary - 4x2 array containing the x/y corners of the tag
%                        associated with the tag boundary
%           *.Vertices - Nx2 array containing x/y locations of the pixel
%                        corners scaled according to tagSize 
%           *.BlackFaces - Bx4 array containing vertex indices associated
%                          with black AprilTag pixels/faces
%           *.WhiteFaces - Wx4 array containing vertex indices associated
%                          with black AprilTag pixels/faces
%           *.p_idx2tag - polynomial coefficients relating index
%                         coordinates (i.e. pixel coordinates) to tag
%                         coordinates
%           *.p_tag2idx - polymomial coeffients relating tag coordinates to
%                         index coordinates (i.e pixel coordinates)
%           *.Filename  - filename of AprilTag used for simulation
%           *.Pathname  - pathname containing AprilTag filename used for
%                         simulation
%
%   See also plotAprilTag
%
%   M. Kutzer, 14Mar2022, USNA

% Updates
%   18Apr2022 - Corrected tagFname generation using regexp tokens
%   21Sep2022 - Replaced tagPathFile calls with 
%               fullfile(userpath,tagPathFile)

debugOn = false;

%% Check input(s)
narginchk(3,3);

if ~ischar(tagFamily)
    error('tagFamily must be specified as a character array.');
end

if numel(tagID) ~= 1 || tagID < 0 || tagID ~= round(tagID)
    error('tagID must be specified as a scalar integer.')
end

if numel(tagSize) ~= 1 || tagSize <= 0
    error('tagSize must be specified as a positive scalar value.');
end

%% Check for 'apriltag-imgs'
tagFolder = 'apriltag-imgs';
tagPathFile = sprintf('%s_path.mat',tagFolder);

tagPath = fullfile(userpath,tagFolder);
if exist(tagPath,'dir') == 7
    % apriltag-imgs appears to exist in the current user path
else
    tagPath = [];
    if exist( fullfile(userpath,tagPathFile),'file') == 2
        try
            load( fullfile(userpath,tagPathFile),'tagPath' )
        catch
            % Unable to load
        end
    end
end

%% Prompt user if apriltag-imgs does not exist
if exist(tagPath,'dir') ~= 7
    answer = questdlg(...
        'Do you currently have a copy of "apriltag-imgs" cloned/downloaded?',...
        'apriltag-imgs','Yes','No','Yes');

    switch answer
        case 'Yes'
            selpath = uigetdir([],'Select "apriltags-imgs" folder');
            if numel(selpath) == 1 && selpath == 0
                % No path selected, apriltags-imgs
                downloadTags = true;
            else
                tagPath = selpath;
                downloadTags = false;
                % TODO - check selected path
                save( fullfile(userpath,tagPathFile),'tagPath' );
            end
        case 'No'
            % Download apriltags-imgs
            downloadTags = true;
        otherwise
            % Download apriltags-imgs
            downloadTags = true;
    end

    if downloadTags
        fprintf('Downloading the "%s"...',tagFolder);
        % Download and unzip toolbox (GitHub)
        url = 'https://github.com/AprilRobotics/apriltag-imgs/archive/refs/heads/master.zip';
        try
            % Save *.zip file
            zipFname = sprintf('%s.zip',tagFolder);
            zipPath = fullfile(userpath,zipFname);
            websave(zipPath,url);
            fprintf('SUCCESS\n');

            % Unzip *.zip file
            fprintf('Unzipping "%s"...',zipFname);
            unzip(zipPath,userpath);
            delete(zipPath);
            fprintf('SUCCESS\n');

            % Rename *.zip contents
            fprintf('Naming folder "%s"...',tagFolder);
            tmpFname = 'apriltag-imgs-master';
            tmpPath = fullfile(userpath,tmpFname);
            tagPath = fullfile(userpath,tagFolder);
            [status,msg,msgID] = copyfile(tmpPath,tagPath);
            % TODO - confirm copy file

            if isfolder(tmpPath)
                % Remove existing directory
                [ok,msg] = rmdir(tmpPath,'s');
            end
            fprintf('SUCCESS\n');

            confirm = true;
        catch ME
            fprintf('FAILED\n');
            confirm = false;
            error('Unable to download "%s" try manually downloading using\n%s\n\nERROR MESSAGE:\n\t%s\n',...
                tagFolder,url,ME.message);
        end
    end
end

%% Final directory check
if exist(tagPath,'dir') ~= 7
    error('Unable to locate "%s" directory.',tagFolder);
end

%% Define available families
% Get a list of all files and folders in tag path
files = dir(tagPath);
% Define all directories
tf_dir = [files.isdir];
% Show tag families
tagFamilies = {files(tf_dir).name};
% Isolate families only
tf_fam = ~contains(tagFamilies,'.');
tagFamilies = tagFamilies(tf_fam);

%% Define pathname and filename
% Pathname
tagPname = fullfile(tagPath,tagFamily);
% Filename
%idx = strfind(tagFamily,'h');
%tagFname = sprintf('tag%s_%s_%05d.png',...
%    tagFamily((idx-2):(idx-1)),tagFamily((idx+1):end),tagID);
expression = '(\d+)';
tokens = regexp(tagFamily, expression, 'tokens');
if numel(tokens) == 2
    val(1) = str2double(tokens{1}{1});
    val(2) = str2double(tokens{2}{1});
else
    str = sprintf('Unexpected tag family name "%s".\n\nAvailable families:\n',tagFamily);
    fams = sprintf('\t%s\n',tagFamilies{:});
    error('%s%s',str,fams);
end
tagFname = sprintf('tag%02d_%02d_%05d.png',val(1),val(2),tagID);

%% Confirm tag exists
if exist(fullfile(tagPname,tagFname),'file') ~= 2
    str = sprintf('Unexpected tag family name "%s".\n\nAvailable families:\n',tagFamily);
    fams = sprintf('\t%s\n',tagFamilies{:});
    error('%s%s',str,fams);
end
    
%% Read tag
im = imread( fullfile(tagPname,tagFname) );
im = rgb2gray(im);

%% [DEBUG] Plot AprilTag in native pixel (index) coordinates
if debugOn
    figIdx = figure('Name',sprintf('simulateAprilTag.m - Loaded Tag: %s, %s',tagFamily,tagFname));
    axsIdx = axes('Parent',figIdx);
    imgIdx = imshow(im);
    set(figIdx,'Units','Normalized','Position',[0.2,0.2,0.6,0.6]);
    set(axsIdx,'Units','Normalized','Position',[0.1,0.1,0.8,0.8],'Visible','on');
    grid(axsIdx,'on');
    hold(axsIdx,'on');
    xlabel(axsIdx,'x (pixels)');
    ylabel(axsIdx,'y (pixels)');
end

%% Define tagSize box
[m,n] = size(im);
if m ~= n
    % AprilTag is not square!
    warning('AprilTag %s, %s is not square [%d,%d].',tagFamily,fname,m,n);
end

for i = 1:floor(n/2)
    ringPix = [];
    % Isolate pixels from ith ring
    ringPix(:,1) = im(i:(end-(i-1)),i);
    ringPix(:,2) = im(i:(end-(i-1)),(end-(i-1)));
    ringPix(:,3) = im(i,i:(end-(i-1))).';
    ringPix(:,4) = im((end-(i-1)),i:(end-(i-1))).';

    % Identify mixed/all black/all white rings
    % Mixed ring (default)
    ring(i) = -1; % Default (mixed ring)
    if nnz(ringPix == 0) == numel(ringPix)
        % All black ring
        ring(i) = 0;
    end

    if nnz(ringPix == 255) == numel(ringPix)
        % All white ring
        ring(i) = 1;
    end

    if i > 1
        if ring(i-1) == 0 && ring(i) == 1
            % Black to white
            iStart = i;
            iEnd   = n-(i-1);
            nSize = n-i-1;
            break
        end

        if ring(i-1) == 1 && ring(i) == 0
            % White to black
            iStart = i;
            iEnd   = n-(i-1);
            nSize = n-i;
            break
        end
    end
end

%% Define conversion from pixel index to linear units & vice versa
% Define scaled tag coordinates
f_tag = linspace(-tagSize/2,tagSize/2,nSize+1);
% Define associated index coordinates
s_idxTagSize = (iStart-0.5):(iEnd+0.5);
% Define polynomial converting index to scaled tag coordinates
p_idx2tag = polyfit(s_idxTagSize,f_tag,1);
% Define polynomial converting scaled tag coordinates to index
p_tag2idx = polyfit(f_tag,s_idxTagSize,1);

% x-corner locations
x_tag = polyval(p_idx2tag,s_idxTagSize);
% y-corner locations
y_tag = polyval(p_idx2tag,s_idxTagSize);

%% [DEBUG] Visualize resultant tagSize indices
if debugOn
    for i = 1:numel(y_tag)-1
        for j = 1:numel(x_tag)-1
            v_tag =[...
                x_tag(j  ), y_tag(i  );...
                x_tag(j+1), y_tag(i  );...
                x_tag(j+1), y_tag(i+1);...
                x_tag(j  ), y_tag(i+1)];

            % Covert v_tag to v_idx (overlay on loaded tag)
            v_idx = v_tag;
            for k = 1:numel(v_tag)
                v_idx(k) = polyval(p_tag2idx,v_tag(k));
            end

            f = 1:4;
            ptc_idx(i,j) = patch('Parent',axsIdx,'Vertices',v_idx,'faces',f,...
                'FaceColor','m','EdgeColor','m','FaceAlpha',0.1,'LineWidth',2);
        end
    end
end

%% Define coordinates for entire tag
% Define indices for entire tag
s_idx = (1-0.5):(n+0.5);

% x-corner locations
x_tag = polyval(p_idx2tag,s_idx);
% y-corner locations
y_tag = polyval(p_idx2tag,s_idx);

%% [DEBUG] Visualize resultant tagSize indices over entire tag
if debugOn
    for i = 1:numel(y_tag)-1
        for j = 1:numel(x_tag)-1
            v_tag =[...
                x_tag(j  ), y_tag(i  );...
                x_tag(j+1), y_tag(i  );...
                x_tag(j+1), y_tag(i+1);...
                x_tag(j  ), y_tag(i+1)];

            % Covert v_tag to v_idx (overlay on loaded tag)
            v_idx = v_tag;
            for k = 1:numel(v_tag)
                v_idx(k) = polyval(p_tag2idx,v_tag(k));
            end

            f = 1:4;
            ptc_idx(i,j) = patch('Parent',axsIdx,'Vertices',v_idx,'faces',f,...
                'FaceColor','none','EdgeColor','c','FaceAlpha',0.1);
        end
    end
end

%% Create patch representation in "tag" coordinates using two patch objects
% TODO - speed-up the indexing by reducing/removing loops
idx = [];
verts = [];
for i = 1:numel(y_tag)
    for j = 1:numel(x_tag)
        idx(end+1,:) = [j,i];
        verts(end+1,:) = [x_tag(j),y_tag(i)];
    end
end

faces{1} = [];  % Black faces
faces{2} = [];  % White faces
faces{3} = [];  % "Bad" faces (neither black nor white, indicating problem)
for i = 1:(numel(y_tag)-1)
    for j = 1:(numel(x_tag)-1)
        % Define vertices of current face
        idx_ij(1,:) = [j  ,i  ];
        idx_ij(2,:) = [j+1,i  ];
        idx_ij(3,:) = [j+1,i+1];
        idx_ij(4,:) = [j  ,i+1];

        % Define face index locations in "verts" array
        for k = 1:size(idx_ij,1)
            face(1,k) = find( idx(:,1) == idx_ij(k,1) & idx(:,2) == idx_ij(k,2) );
        end

        % Identify black/white faces
        switch im(i,j)
            case 0
                % Black Face
                faces{1}(end+1,:) = face;
            case 255
                % White Face
                faces{2}(end+1,:) = face;
            otherwise
                % Unexpected Face
                % -> Error check
                faces{3}(end+1,:) = face;
                warning('Unexpected pixel value: im(%d,%d) = %d',i,j,im(i,j));
        end
    end
end

%% Define tag "location"
x_tagLocation = polyval(p_idx2tag,[s_idxTagSize(1),s_idxTagSize(end)]);
y_tagLocation = polyval(p_idx2tag,[s_idxTagSize(1),s_idxTagSize(end)]);
% Define tag "location"
% -> flipud.m is used to match the "loc" order produced by readAprilTag.m
verts_tagLocation = flipud([...
    x_tagLocation(1), y_tagLocation(1);...
    x_tagLocation(2), y_tagLocation(1);...
    x_tagLocation(2), y_tagLocation(2);
    x_tagLocation(1), y_tagLocation(2)]);

%% Define tag "boundary"
x_tagBounds = polyval(p_idx2tag,[s_idx(1),s_idx(end)]);
y_tagBounds = polyval(p_idx2tag,[s_idx(1),s_idx(end)]);
% Define tag "bounds"
% -> flipud.m is used to mimic the "loc" order produced by readAprilTag.m
verts_tagBounds = flipud([...
    x_tagBounds(1), y_tagBounds(1);...
    x_tagBounds(2), y_tagBounds(1);...
    x_tagBounds(2), y_tagBounds(2);
    x_tagBounds(1), y_tagBounds(2)]);

%% Package output
tagInfo.Family = tagFamily;
tagInfo.ID = tagID;
tagInfo.Size = tagSize;
tagInfo.Location = verts_tagLocation;
tagInfo.Boundary = verts_tagBounds;
tagInfo.Vertices = verts;
tagInfo.BlackFaces = faces{1};
tagInfo.WhiteFaces = faces{2};
tagInfo.p_idx2tag = p_idx2tag;
tagInfo.p_tag2idx = p_tag2idx;
tagInfo.Filename = tagFname;
tagInfo.Pathname = tagPname;

%% Render simulated AprilTag
if debugOn
    % Create figure and axes
    figTag = figure('Name',sprintf('simulateAprilTag.m - Simulted Tag: %s, %s',tagFamily,tagFname));
    axsTag = axes('Parent',figTag);
    hold(axsTag,'on');
    daspect(axsTag,[1 1 1]);
    view(axsTag,[180,-90]);
    xlabel(axsTag,'x (tagSize linear units)');

    ylabel(axsTag,'y (tagSize linear units)');
    % Create parent to adjust AprilTag pose relative to camera frame
    % H_t2c - transformation relating the body-fixed "tag" frame to the camera
    %         frame
    h_t2c = triad('Parent',axsTag,'Scale',(2/3)*tagSize,'LineWidth',1);

    % Render AprilTag
    % -> Magenta pixels indicate a "bad face" (i.e. a face with pixel
    %    value \notin {0,255})
    colors = 'kwm';
    for i = 1:numel(faces)
        if ~isempty(faces{i})
            ptc_tag(i) = patch('Parent',h_t2c,'Vertices',verts,'Faces',faces{i},...
                'EdgeColor','none','FaceColor',colors(i));
        end
    end

    % Display tag location
    faces_tagSize = 1:4;
    ptc_tagSize = patch('Vertices',verts_tagLocation,'Faces',faces_tagSize,...
        'Parent',h_t2c,'EdgeColor','c','FaceColor','none');
    
    % Display location numbering
    for i = 1:size(verts_tagLocation,1)
        txt_loc(i) = text(verts_tagLocation(i,1),verts_tagLocation(i,2),...
            sprintf('loc_%d',i),'Parent',h_t2c);
    end

    % Display tag bounds
    faces_tagBounds = 1:4;
    ptc_tagBounds = patch('Vertices',verts_tagBounds,'Faces',faces_tagBounds,...
        'Parent',h_t2c,'EdgeColor','m','FaceColor','none');
    
    % Display bounds numbering
    for i = 1:size(verts_tagBounds,1)
        txt_bnd(i) = text(verts_tagBounds(i,1),verts_tagBounds(i,2),...
            sprintf('bnd_%d',i),'Parent',h_t2c);
    end

    legend([ptc_tagSize,ptc_tagBounds],'tagSize','tagBoundary');

    % Adjust patch face lighting
    % -> FaceLighting 'none' should provide high contrast regardless of
    %    lighting
    set(ptc_tag,'FaceLighting','None');
end
