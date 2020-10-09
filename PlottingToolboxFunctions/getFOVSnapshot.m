function im = getFOVSnapshot(sim)
% GETFOVSNAPSHOT returns an image from simulated camera FOV.
%   im = GETFOVSNAPSHOT(sim) returns an simulated image given a structured
%   array specifying a simulated camera.
%
%   Input(s):
%       sim - stuctured array containing
%           sim.Figure - figure handle for simulated FOV
%           sim.Axes   - (unused) axes handle for simulated FOV
%           sim.hRes   - horizontal resolution of the camera
%           sim.vRes   - vertical resolution of the camera
%           sim.hAOV   - (unused) approximate horizontal angle of view for 
%                        the camera
%           sim.vAOV   - (unused) approximate vertical angle of view for 
%                        the camera
%
%   See also initCameraSim
%
%   M. Kutzer, 08Oct2020, USNA

% Updates:
%   08Oct2020 - Migrated from EW309 COVID simulation
%   08Oct2020 - Created a general use function

%% Check inputs
narginchk(1,1);

% TODO - Check h

%% Get image
frm = getframe(sim.Figure);
im = frm.cdata;

if size(im,1) ~= sim.vRes
    % Wrong image size!
    %   - Brute force correct!
    im = imresize(im,[sim.vRes,sim.hRes]);
end