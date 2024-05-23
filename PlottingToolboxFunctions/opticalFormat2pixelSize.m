function pixSize = opticalFormat2pixelSize(optFmt,res)
% OPTICALFORMAT2PIXELSIZE converts an imaging sensor optical format to an 
% an approximate pixel size. 
%   pixSize = opticalFormat2pixelSize(optFmt,res)
%
%   Input(s)
%       optFmt - a character array defining optical format (e.g. '1/2"')
%          res - 1x2 array specifying [column resolution, row resolution] 
%                of the imaging sensor in pixels.
%
%   Output(s)
%       pixSize - scalar defining nominal pixel size in micrometers
%
%   References
%       [1] "The Image Sensor Size And Pixel Size Of A Camera Is Critical
%            To Image Quality," 
%            https://commonlands.com/blogs/technical/cmos-sensor-size
%   
%   M. Kutzer, 23May2024, USNA

%% Check input(s)
narginchk(2,2);

if ~ischar(optFmt)
    error('Optical format must be defined as a character array (e.g. ''1/2"''');
end

if ~isnumeric(res) || numel(res) ~= 2
    error('Sensor size must be defined as a 1x2 array defining the  [column resolution, row resolution].');
end

%% Parse optical format
if ~matches(optFmt(end),'"')
    error('Optical formats other than inches are not supported.')
end

% Define full diameter
dMicroMeters = eval(optFmt(1:(end-1)))*25400;
% Account for "cathode ray tube" outer diameter
dMicroMeters = dMicroMeters*0.71;
% Define diagonal pixel dimension
dPixels = sqrt(res(1).^2 + res(2).^2);

pixSize = dMicroMeters/dPixels;