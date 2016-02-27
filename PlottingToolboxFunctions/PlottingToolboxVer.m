function varargout = PlottingToolboxVer
% PLOTTINGTOOLBOXVER displays the Plotting Toolbox information.
%   PLOTTINGTOOLBOXVER displays the information to the command prompt.
%
%   A = PLOTTINGTOOLBOXVER returns in A the sorted struct array of  
%   version information for the Plotting Toolbox.
%     The definition of struct A is:
%             A.Name      : toolbox name
%             A.Version   : toolbox version number
%             A.Release   : toolbox release string
%             A.Date      : toolbox release date
%
%   M. Kutzer 27Feb2016, USNA

A.Name = 'Plotting Toolbox';
A.Version = '1.0.0';
A.Release = '(R2015b)';
A.Date = '27-Feb-2016';
A.URLVer = 1;

msg{1} = sprintf('MATLAB %s Version: %s %s',A.Name, A.Version, A.Release);
msg{2} = sprintf('Release Date: %s',A.Date);

n = 0;
for i = 1:numel(msg)
    n = max( [n,numel(msg{i})] );
end

fprintf('%s\n',repmat('-',1,n));
for i = 1:numel(msg)
    fprintf('%s\n',msg{i});
end
fprintf('%s\n',repmat('-',1,n));

if nargout == 1
    varargout{1} = A;
end