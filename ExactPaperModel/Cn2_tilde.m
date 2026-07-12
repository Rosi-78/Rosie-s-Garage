function ctn = Cn2_tilde(h, alpha, theta, cfg)
%CN2_TILDE Equivalent non-Kolmogorov refractive-index structure constant.
%
%   Equation (11) in the paper:
%       Cn2~(h,alpha) = coeff * Cn2(h)
%   where coeff involves Gamma functions and the slant-path length L.
%
%   Inputs:
%       h     - height(s) in meters (scalar or array)
%       alpha - power-law exponent, 3 < alpha < 4
%       theta - zenith angle in radians
%       cfg   - configuration struct with wavelength, satellite_altitude,
%               ground_altitude, wind_speed, Cn2_ground, turbulence_strength_scale
%   Output:
%       ctn   - equivalent structure constant at height h

    k = 2 * pi / cfg.wavelength;
    sec_theta = 1 / cos(theta);
    L = (cfg.satellite_altitude - cfg.ground_altitude) * sec_theta;

    Aa = A_alpha(alpha);

    g_alpha = gamma(alpha);
    g_1_a2 = gamma(1 - alpha / 2);
    g_a2_2 = gamma(alpha / 2)^2;
    sin_term = sin(pi * alpha / 4);
    base = (k / L)^(alpha / 2 - 11 / 6);

    coeff = -g_alpha * base / (8 * pi^2 * g_1_a2 * g_a2_2 * sin_term * Aa);

    % HV profile, equation (10)
    term1 = 0.00594 * (cfg.wind_speed / 27)^2 .* (1e-5 * h).^10 .* exp(-h / 1000);
    term2 = 2.7e-16 * exp(-h / 1500);
    term3 = cfg.Cn2_ground * exp(-h / 100);
    cn2 = cfg.turbulence_strength_scale * (term1 + term2 + term3);

    ctn = coeff .* cn2;
end
