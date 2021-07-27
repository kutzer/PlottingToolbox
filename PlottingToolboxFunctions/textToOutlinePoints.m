function textToOutlinePoints(msg,varargin)
% TEXTTOOUTLINEPOINTS converts a sting or a binary into the points defining
% the contours (interior and exterior).
%   TEXTTOOUTLINEPOINTS(msg)
%
%   Input(s)
%       msg - string argument containing text or a binary image (background
%             must be white)
%
%   M. Kutzer, 17Aug2016, USNA

% Updates
%   26Jul2021 - Updated to isolate textToOutlinePoints function

%% Check if binary image was provide instead of text
if ~islogical(msg)
    %-> Create text
    % Create figure for saving text as image
    fig(1) = figure('Name','String Data','Color',[1,1,1]);
    
    % Create text
    %txt = text(0,0,msg,....
    %    'HorizontalAlignment','Center','VerticalAlignment','Middle',...
    %    'FontName','Aerial','FontWeight','Bold','FontSize', 32,...
    %    'Parent',axs(1));
    uiTxt = uicontrol('Style','Text','String',msg,'FontName','Aerial',...
        'FontWeight','Bold','FontSize', 32);
    % Adjust figure to correct extent
    ext = get(uiTxt,'Extent');
    set(fig(1),'Units','Pixels','Position',[100,100,ext(3:4)]);
    set(uiTxt,'Position',[ext(1:2), ext(3:4)],'BackgroundColor',[1,1,1]);
    
    % Get frame and recover image
    drawnow
    frm = getframe(fig(1));
    im = rgb2gray( frm.cdata );
else
    %-> User inputs a binary image
    im = 255*uint8(msg);
    msg = 'Binary';
end

%% Process image to get contours (exteriors)
% Create binary image
binExt = im < 0.5*255;
% Label segmented objects
[lbl,n] = bwlabel(binExt);
% Find perimeter
for i = 1:n
    % Select ith segmented object
    bw = lbl == i;
    % Choose a point on the object
    [r,c] = find(bw,1,'first');
    % Define the contour of the object [x1,y1; x2,y2; ...]
    contour{i} = fliplr( bwtraceboundary(bw,[r,c],'N') );
    interiorFlag(i) = 0;
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
    interiorFlag(end+1) = 1;
end

%% Visualize contours
fig(2) = figure('Name','Contour Check');
img(2) = imshow(binInt);
axs(2) = get(img(2),'Parent');
hold(axs(2),'on');
for i = 1:numel(contour)
    % Contour
    plt(i) = plot(axs(2),contour{i}(:,1),contour{i}(:,2),'LineWidth',1.5);
    % Start point
    plt_0(i) = plot(axs(2),contour{i}(1,1),contour{i}(1,2),'o');
    % End point
    plt_1(i) = plot(axs(2),contour{i}(end,1),contour{i}(end,2),'x');
    if interiorFlag(i)
        set(plt(i),'Color','r');
        set(plt_0(i),'Color','r');
        set(plt_1(i),'Color','r');
    else
        set(plt(i),'Color','g');
        set(plt_0(i),'Color','r');
        set(plt_1(i),'Color','r');
    end
end
%% Isolate letter interior and exteriors into polyshapes
% Create exterior polygons
idxExt = find(~interiorFlag);
for i = 1:numel(idxExt)
    idx = idxExt(i);
    pshpExt(i) = polyshape(contour{idx}(1:(end-1),1).', contour{idx}(1:(end-1),2).');
end
idxInt = find(interiorFlag);
for i = 1:numel(idxInt)
    idx = idxInt(i);
    pshpInt(i) = polyshape(contour{idx}(1:(end-1),1).', contour{idx}(1:(end-1),2).');
end

% Find interiors and build polyshapes
for i = 1:numel(pshpExt)
    pshp(i) = pshpExt(i);
    for j = 1:numel(pshpInt)
        [x,y] = boundary(pshpInt(j));
        if isinterior(pshpExt(i),[x,y])
            pshp(i) = addboundary(pshp(i),[x,y]);
        end
    end
end

%% Plot final polyshapes
fig(3) = figure('Name','Contour Check');
img(3) = imshow(binInt);
axs(3) = get(img(3),'Parent');
hold(axs(3),'on');
for i = 1:numel(pshp)
    pp(i) = plot(pshp(i),'Parent',axs(3));
end

%% Sort letter exteriors/interiors
% This sorting will draw contours from left to write. If/when there are
% multiple lines of text, all of the left-most letters will be created from
% top-to bottom.
for i = 1:numel(contour)
    sPnt(i) = contour{i}(1,1);
end
[~,idx] = sort(sPnt);

%% Display results
fig(2) = figure;
img = imshow(binInt);
axs = get(img,'Parent');
hold(axs,'on');
cnt_All = [];
idx_All = [];

for i = 1:numel(contour)
    % Combine contour coordinates for each letter
    % -> Include a "wrap-around" to close the letter
    cnt_All = [...
        cnt_All;...     % Previous contours
        [nan, nan];...  % NaN to break plots
        [contour{idx(i)}; contour{idx(i)}(1:2,:)] ]; % Fully wrapped contour
    
    % Define index transitions for letters
    if isempty(idx_All)
        idx_All(i,:) = [1,size(cnt_All,1)];
    else
        idx_All(i,:) = [idx_All(i-1,2)+2,size(cnt_All,1)];
    end
    
    % Plot evolution of contour (for debugging)
    %plt(i) = plot(contour{idx(i)}(:,2),contour{idx(i)}(:,1),'m');
    %for j = 1:size(contour{idx(i)},1)
    %    set(plt(i),...
    %        'XData',contour{idx(i)}(1:j,2),...
    %        'YData',contour{idx(i)}(1:j,1));
    %    drawnow
    %end
end

plt = plot(axs,cnt_All(:,1),cnt_All(:,2),'m');

% Close figure
%close(fig(2));