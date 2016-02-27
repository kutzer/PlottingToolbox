function plotImageDistortion(params,xlims,ylims)

% params - MATLAB camera parameters

%% Set defaults
if nargin < 3
    ylims = [0,480];
end
if nargin < 2
    xlims = [0,640];
end

%%
xlims = sort(xlims);
ylims = sort(ylims);

xdir = linspace(xlims(1)+10,xlims(2)-10,100);
ydir = linspace(ylims(1)+10,ylims(2)-10,100);

xtick = linspace(xlims(1)+10,xlims(2)-10,10);
ytick = linspace(ylims(1)+10,ylims(2)-10,10);

fig = figure;
axs = axes('Parent',fig);
hold on
daspect([1 1 1]);
xlim(xlims);
ylim(ylims);

Xc = params.PrincipalPoint;
plot(Xc(1),Xc(2),'*g');

% Plot vertical
for i = 1:numel(xtick)
    Xu = [repmat(xtick(i),1,numel(ydir));ydir];
    Xd = distortImagePoints(Xu,params);
    plot(axs,Xd(1,:),Xd(2,:),':k');
end

% Plot horizontal
for i = 1:numel(ytick)
    Xu = [xdir; repmat(ytick(i),1,numel(xdir))];
    Xd = distortImagePoints(Xu,params);
    plot(axs,Xd(1,:),Xd(2,:),':k');
end