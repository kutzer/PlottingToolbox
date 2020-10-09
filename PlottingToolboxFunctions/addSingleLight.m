function h = addSingleLight(axs)
% ADDSINGLELIGHT adds a single light object to a specified axes if one
% does not already exist.
%   ADDSINGLELIGHT adds a single light object to the current axes and
%   returns the light handle. If a light object already exists, the light
%   object handle is returned. If multiple light objects exists, a warning
%   is given, and excess lights are removed.
%
%   ADDSINGLELIGHT(axs) adds a single light object to the axes specified
%   with axs and returns the light handle. If a light object already
%   exists, the light object handle is returned. If multiple light objects 
%   exists, a warning is given, and excess lights are removed.
%
%   h = ADDSINGLELIGHT(___) returns the light object.
%
%   See also light
%
%   M. Kutzer 01Dec2014, USNA

% Updates:
%   08Oct2020 - Updated documentation, removed (c), and updated to use
%               contains.

%% Set defaults
if nargin < 1
    axs = gca;
end

%% Check/Add/Remove
kids = get(axs,'Children');

if isempty(kids)
    h = light('Parent',axs);
    return;
end

kTypes = get(kids,'Type');
if iscell(kTypes)
    bin = ~cellfun(@isempty,strfind(kTypes,'light'),'UniformOutput',1);
else
    bin = contains(kTypes,'light');
end

idx = find(bin);
if isempty(idx)
    h = light('Parent',axs);
elseif numel(idx) > 1
    %TODO add user dialog to allow them to select which light(s) to keep.
    warning('Multiple lights detected, removing extra lights.');
    h = kids(idx(1));
    delete(kids(idx(2:end)));
else
    h = kids(idx);
end