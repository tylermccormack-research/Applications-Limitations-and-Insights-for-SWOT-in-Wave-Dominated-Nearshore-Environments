function C = calculateCelerity(h, T)
% Calculates wave celerity (phase speed) based on depth and wave period
% Inputs:
%   h - water depth [m]
%   T - wave period [s]
% Output:
%   C - wave celerity [m/s]

g = 9.81;                      % gravitational acceleration [m/s^2]
L0 = (g * T.^2) / (2*pi);      % deep water wavelength estimate
h_over_L0 = h ./ L0;

if h_over_L0 < 1/20
    % Shallow water: C = sqrt(g*h)
    C = sqrt(g * h);
    
elseif h_over_L0 > 0.5
    % Deep water: C = L/T = (gT)/(2pi)
    C = (g * T) / (2 * pi);
    
else
    % Intermediate depth: solve dispersion relation
    % omega = 2 * pi / T;
    % k = omega^2 / g;  % initial guess
    % for i = 1:100
    %     k = omega^2 / (g * tanh(k * h));
    % end
    % C = omega / k;
    w = 2*pi/T;
    k0h = w^2*h/9.8;
    % Vatankhan and Aghashariatmadari (2013)
    kh = k0h*(1+k0h*exp(-(1.835+1.225*k0h^1.35)))/sqrt(tanh(k0h));
    k  = kh/h;
    C = w / k;
end

end
