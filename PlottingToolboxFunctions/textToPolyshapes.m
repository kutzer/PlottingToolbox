function pShapes = textToPolyshapes(msg,width,height,varargin)
% TEXTTOPOLYSHAPES converts a sting or a binary a set of polyshapes.
%   TEXTTOPOLYSHAPES(msg,width,height,Name,Value,Name,Value...)
%
%   Input(s)
%       msg    - string argument containing text or a binary image (background
%                must be white)
%       width  - scalar value specifying the desired width of the text. To
%                specify height only and maintain the aspect ratio, use [].
%       height - scalar value specifying the desired height of the text. To
%                specify width only and maintain the aspect ratio, use [].
%       name/value - Name-Value pair arguments
%           'FontName'
%           'FontWeight' - {'normal',['bold']}
%           'FontSize'
%           'FontAngle' - {['normal','italic'}
%
%   Output(s)
%       pShapes - 1xN array of polyshapes where each element represents an
%                 individual character (or region for a binary image) 
%                 sorted left-to-right, top-to-bottom. 
%
%   Example(s)
%       msg = sprintf([...
%           '0123456789012345678901234567890123456789\n',...
%           '0123456789012345678901234567890123456789\n',...
%           '0123456789012345678901234567890123456789']);
%       width = 8*25.4; % 8" text width converted to mm
%       pShapes = textToPolyshapes(msg,width,[]);
%
%   M. Kutzer, 27Aug2021, USNA

debugON = false;

%% Check input(s)
% TODO - check input(s)
if nargin < 3
    height = [];
end
if nargin < 2
    width = [];
end

%% Check if binary image was provide instead of text
if ~islogical(msg)
    %-> Create text
    % Create figure for saving text as image
    fig = figure('Name','String Data','Color',[1,1,1],'Visible','on',...
        'PaperPositionMode','auto');
    
    % Create text
    uiTxt = uicontrol('Style','Text','String',msg,'FontName','Aerial',...
        'FontWeight','Bold','FontSize',120,'Parent',fig);
    if numel(varargin) > 1
        set(uiTxt,varargin{:});
    end
    % Adjust figure to correct extent
    ext = get(uiTxt,'Extent');
    set(fig,'Units','Pixels','Position',[100,100,ext(3:4)]);
    set(uiTxt,'Position',[ext(1:2), ext(3:4)],'BackgroundColor',[1,1,1]);
    
    % Get frame and recover image
    drawnow
    frm = getframe(fig);
    im = rgb2gray( frm.cdata );
    
    if debugON
        set(fig,'Visible','on');
    else
        delete(fig);
    end
else
    %-> User inputs a binary image
    im = 255*uint8(msg);
    msg = [];
end

%% Process image to get contours (exteriors)
% Create binary image
binExt = im < 0.5*255;
% Label segmented objects
[lbl,n] = bwlabel(binExt);
% Define set of all points to define bounding box
pntsAll = [];
% Find perimeter
for i = 1:n
    % Select ith segmented object
    bw = lbl == i;
    % Choose a point on the object
    [r,c] = find(bw,1,'first');
    % Define the contour of the object [x1,y1; x2,y2; ...]
    contour{i} = fliplr( bwtraceboundary(bw,[r,c],'N') );
    % Keep only unique contour points
    contour{i} = unique(contour{i},'stable','rows');
    % Assign interior/exterior flag
    interiorFlag(i) = 0;
    % Append points
    pntsAll = [pntsAll; contour{end}];
end

%% Process image to get contours (interiors)
%-> Create binary image
binInt = im >= 0.5*255;
% Label segmented objects
[lbl,n] = bwlabel(binInt);
% Find perimeter
% - This assumes the first object is the image background (i.e. 2:n vs 1:n)
for i = 2:n
    % Select ith segmented object
    bw = lbl == i;
    % Choose a point on the object
    [r,c] = find(bw,1,'first');
    % Define the contour of the object [x1,y1; x2,y2; ...]
    contour{end+1} = fliplr( bwtraceboundary(bw,[r,c],'N') );
    % Keep only unique contour points
    contour{end} = unique(contour{end},'stable','rows');
    % Assign interior/exterior flag
    interiorFlag(end+1) = 1;
    % Append points
    pntsAll = [pntsAll; contour{end}];
end

%% Visualize contours
if debugON
    fig(1) = figure('Name','Contour Check');
    img(1) = imshow(binInt);
    axs(1) = get(img(1),'Parent');
    hold(axs(1),'on');
    for i = 1:numel(contour)
        % Contour
        plt(i) = plot(axs(1),contour{i}(:,1),contour{i}(:,2),'LineWidth',1.5);
        % Start point
        plt_0(i) = plot(axs(1),contour{i}(1,1),contour{i}(1,2),'o');
        % End point
        plt_1(i) = plot(axs(1),contour{i}(end,1),contour{i}(end,2),'x');
        if interiorFlag(i)
            set(plt(i),'Color','r');
            set(plt_0(i),'Color','r');
            set(plt_1(i),'Color','r');
        else
            set(plt(i),'Color','g');
            set(plt_0(i),'Color','g');
            set(plt_1(i),'Color','g');
        end
    end
end

%% Define bounding box
xxPix = [min(pntsAll(:,1)), max(pntsAll(:,1))];
yyPix = [min(pntsAll(:,2)), max(pntsAll(:,2))];

vertsPix = [...
    xxPix(1), xxPix(2), xxPix(2), xxPix(1);...
    yyPix(1), yyPix(1), yyPix(2), yyPix(2)];

%% Define pixel bounding box & center
bbPix = polyshape(vertsPix(1,:), vertsPix(2,:));
[x,y] = centroid(bbPix);
bbCnt = [x,y];

%% Visualize bounding box
if debugON
    plt_bbPix = plot(bbPix,'Parent',axs(1),'FaceColor','c',...
        'FaceAlpha',0.2,'EdgeColor','c');
    plt_bbCnt = plot(axs(1),bbCnt(1),bbCnt(2),'*c');
    for i = 1:size(vertsPix,2)
        txt_bbPix(i) = text(axs(1),vertsPix(1,i),vertsPix(2,i),sprintf('P_%d',i));
    end
end

%% Define desired bounding box
aspect = diff(xxPix)./diff(yyPix);
if isempty(width) && ~isempty(height)
    width = height * aspect;
elseif ~isempty(width) && isempty(height)
    height = width / aspect;
else
    width = diff(xxPix);
    height = diff(yyPix);
end

xxLin = [ -width/2,  width/2];
yyLin = [-height/2, height/2];
vertsLin = [...
    xxLin(1), xxLin(2), xxLin(2), xxLin(1);...
    yyLin(2), yyLin(2), yyLin(1), yyLin(1)];

%% Define affine transform
vertsPix(3,:) = 1;
vertsLin(3,:) = 1;
A_Pix2Lin = vertsLin * pinv(vertsPix);

%% Transform contours to linear units
for i = 1:numel(contour)
    tmpPix = contour{i}.';
    tmpPix(3,:) = 1;
    tmpLin = A_Pix2Lin * tmpPix;
    contourLin{i} = tmpLin(1:2,:).';
end

%% Plot transformed contours
if debugON
    fig(2) = figure('Name','Transformed Contour Check');
    axs(2) = axes('Parent',fig(2));
    daspect(axs(2),[1 1 1]);
    hold(axs(2),'on');
    for i = 1:numel(contourLin)
        % Contour
        plt(i) = plot(axs(2),contourLin{i}(:,1),contourLin{i}(:,2),'LineWidth',1.5);
        % Start point
        plt_0(i) = plot(axs(2),contourLin{i}(1,1),contourLin{i}(1,2),'o');
        % End point
        plt_1(i) = plot(axs(2),contourLin{i}(end,1),contourLin{i}(end,2),'x');
        if interiorFlag(i)
            set(plt(i),'Color','r');
            set(plt_0(i),'Color','r');
            set(plt_1(i),'Color','r');
        else
            set(plt(i),'Color','g');
            set(plt_0(i),'Color','g');
            set(plt_1(i),'Color','g');
        end
    end
end

%% Isolate letter interior and exteriors into polyshapes
warning off
% Create exterior polygons
idxExt = find(~interiorFlag);
for i = 1:numel(idxExt)
    idx = idxExt(i);
    pshpExt(i) = polyshape(contourLin{idx}(1:(end-1),1).', contourLin{idx}(1:(end-1),2).');
end
idxInt = find(interiorFlag);
for i = 1:numel(idxInt)
    idx = idxInt(i);
    pshpInt(i) = polyshape(contourLin{idx}(1:(end-1),1).', contourLin{idx}(1:(end-1),2).');
end

% Find interiors and build polyshapes
for i = 1:numel(pshpExt)
    pShapes(i) = pshpExt(i);
    for j = 1:numel(pshpInt)
        [x,y] = boundary(pshpInt(j));
        if isinterior(pshpExt(i),[x,y])
            pShapes(i) = addboundary(pShapes(i),[x,y]);
        end
    end
end
warning on

%% Plot polyshapes
if debugON
    for i = 1:numel(pShapes)
        pp(i) = plot(pShapes(i),'Parent',axs(2));
    end
end

%% Order polyshapes left to right, top to bottom (only if text is supplied)
if isempty(msg)
    return
end

cntLin = [];
for i = 1:numel(pShapes)
    [x,y] = centroid(pShapes(i));
    cntLin(end+1,:) = [x,y];
end

nLines = nnz( msg == char(10) ) + 1;
[idx,c] = kmeans(cntLin(:,2),nLines);
[~,idxOrder] = sort(c,'descend');

pShapeLine = {};
cntLinLine = {};
for i = 1:numel(idxOrder)
    bin = (idx == idxOrder(i));
    pShapeLine{i} = pShapes(bin);
    cntLinLine{i} = cntLin(bin,:);
    
    % Sort left to right
    [~,idxLR] = sort(cntLinLine{i}(:,1));
    pShapeLine{i} = pShapeLine{i}(idxLR);
end

%% Combine ordered polyshapes
pShapes = [pShapeLine{:}];

%% Animate letters (for debug)
if debugON
    fig(3) = figure;
    axs(3) = axes('Parent',fig(3));
    hold(axs(3),'on');
    daspect(axs(3),[1 1 1]);
    xlim(axs(3),xxLin);
    ylim(axs(3),yyLin);
    drawnow;
    for i = 1:numel(pShapes)
        plot(pShapes(i),'Parent',axs(3));
        drawnow;
        pause(0.05);
    end
end