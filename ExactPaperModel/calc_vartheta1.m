function v1 = calc_vartheta1(alpha, rho, theta, cfg)
%CALC_VARTHETA1 First component of the irradiance covariance integral.
%
%   Equation (13) in the paper.
%
%   Inputs:
%       alpha - power-law exponent
%       rho   - aperture separation in meters
%       theta - zenith angle in radians
%       cfg   - configuration struct
%   Output:
%       v1    - scalar value of theta1

    k = 2 * pi / cfg.wavelength;
    sec_theta = 1 / cos(theta);
    Aa = A_alpha(alpha);
    g_1_a2 = gamma(1 - alpha / 2);
    D_sq = cfg.aperture_diameter^2;

    term_d = (D_sq / 16)^(alpha / 2 - 1);
    arg_hyp = -4 * rho^2 / D_sq;
    hyp = hypergeom(1 - alpha / 2, 1, arg_hyp);

    integrand = @(h) Cn2_tilde(h, alpha, theta, cfg);
    int_cn2 = integral(integrand, cfg.ground_altitude, cfg.satellite_altitude);

    coeff = 4 * pi^2 * k^2 * Aa * sec_theta * g_1_a2;
    v1 = coeff * term_d * hyp * int_cn2;
end
