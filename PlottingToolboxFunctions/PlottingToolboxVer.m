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

% Updates
%   07Mar2018 - Updated to include try/catch for required toolbox
%               installations
%   15Mar2018 - Updated to include msgbox warning when download fails
%   08Jan2020 - Updated to use preview objects instead of camera objects.
%   17Mar2020 - Updated to include view angle estimation from intrinsic
%               matrices.
%   09Oct2020 - Updated to add getFOVSnapshot and updated initCameraSim
%   05Jan2021 - Updated install function and simulateImage
%   08Jan2021 - Updated ToolboxUpdate
%   26Apr2021 - Updated simualteImage.m
%   15Dec2021 - Added C0 and C1 options to pShapesToSplines
%   03Mar2022 - Added appendLine function
%   14Mar2022 - Added simulateAprilTag and plotAprilTag
%   15Mar2022 - Added isVisible and cameraParam support for plotCameraFOV
%   16Mar2022 - Updated simulateImage to remove points lying behind the
%               camera
%   17Mar2022 - Updated simulateImage to remove points outside FOV (see
%               "Known Issues") and incorporated common lighting between
%               the simulation and simulated image
%   24Mar2022 - Added try/catch in plotCameraFOV
%   14Apr2022 - Documentation update and bug fixed for plotCheckerboard
%   18Apr2022 - Updated simulateAprilTag
%   06Feb2024 - Added projectWithFalseDepth
%   05Mar2024 - Corrected projectWithFalseDepth
%   25Mar2024 - Added setParentTransform

A.Name = 'Plotting Toolbox';
A.Version = '1.1.9';
A.Release = '(R2020b)';
A.Date = '16-Apr-2024';
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