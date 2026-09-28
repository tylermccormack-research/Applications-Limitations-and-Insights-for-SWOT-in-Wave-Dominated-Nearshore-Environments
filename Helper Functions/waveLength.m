function L = waveLength(T, h)
% waveLength computes the wavelength L (in meters) for a given wave period T (in seconds)
% and water depth h (in meters), using the linear wave dispersion relation.
%
% Usage:
%   L = waveLength(T, h)
%
% Inputs:
%   T - Wave period in seconds
%   h - Water depth in meters
%
% Output:
%   L - Wavelength in meters

    g = 9.81;                     % acceleration due to gravity (m/s^2)
    omega = 2 * pi / T;          % angular frequency (rad/s)

    % Initial guess for wavelength using deep water approximation
    L0 = (g * T^2) / (2 * pi);   % deep water approximation for initial guess

    % Solve dispersion relation numerically for L
    L = fzero(@(L) (omega^2 - g * (2 * pi / L) * tanh((2 * pi / L) * h)), L0);
end
