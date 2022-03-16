%% SCRIPT_Test_simulateImage
% This assumes "debugON = true" in simulateImage
%
%   M. Kutzer, 16Mar2022, USNA

set(pAxs,'Visible','on');
set(pAxs,'Position',[0.1,0.1,0.8,0.8]);
xlabel(pAxs,'x (pixels)');
ylabel(pAxs,'y (pixels)');
zlabel(pAxs,'z^c (linear units)');
view(pAxs,3);

%% Get children of pAxs
clc
kids = get(pAxs,'Children');
for i = 1:numel(kids)
    fprintf('kids(%d).Type = %s, kids(%d).Tag = "%s"\n',i,kids(i).Type,i,kids(i).Tag);
    try
        x = get(kids(i),'XData');
        y = get(kids(i),'YData');
        z = get(kids(i),'ZData');

        fprintf('\tnnz(isnan(x)) = %d, numel(x) = %d\n',nnz(isnan(x)),numel(x));
        fprintf('\tnnz(isnan(y)) = %d, numel(y) = %d\n',nnz(isnan(y)),numel(y));
        fprintf('\tnnz(isnan(z)) = %d, numel(z) = %d\n',nnz(isnan(z)),numel(z));
    catch
        fprintf('\tNo X/Y/Z Data\n');
    end
end