function fig = pptFigure(fig)

%% set figure dimensions
set(fig,'Units','Inches','Position',[0,0,9.3,5.4]);
set(fig,'PaperSize',[5.4,9.3],'PaperPosition',[0,0,9.3,5.4]);
%% setup text
kids = get(fig,'Children');

%TODO - check if kids are type axes
axs = kids;

set(axs,'FontName','Calibri','FontSize',14);

directions = 'xyz';
for k = 1:numel(axs)
    for i = 1:numel(directions)
        lbl(i) = get(axs(k),sprintf('%slabel',directions(i)));
    end
    set(lbl,'FontName','Calibri','FontSize',16);
    ttl = get(axs(k),'Title');
    set(ttl,'FontName','Calibri','FontSize',16);
end
