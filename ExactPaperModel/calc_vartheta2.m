function v2 = calc_vartheta2(alpha, rho, theta, cfg)
%CALC_VARTHETA2 Second component of the irradiance covariance integral.
%
%   Equation (14) in the paper. The integral is complex; only the real part
%   contributes to v2.
%
%   Inputs:
%       alpha - power-law exponent
%       rho   - aperture separation in meters
%       theta - zenith angle in radians
%       cfg   - configuration struct
%   Output:
%       v2    - scalar value of theta2

    k = 2 * pi / cfg.wavelength;
    sec_theta = 1 / cos(theta);
    Aa = A_alpha(alpha);
    g_1_a2 = gamma(1 - alpha / 2);
    D_sq = cfg.aperture_diameter^2;
    h0 = cfg.ground_altitude;

    const = 4 * pi^2 * k^2 * Aa * sec_theta * g_1_a2;

    integrand = @(h) integrand_v2(h, alpha, rho, theta, cfg, k, sec_theta, D_sq, h0);

    int_complex = integral(integrand, h0, cfg.satellite_altitude);
    v2 = -const * real(int_complex);
end

function val = integrand_v2(h, alpha, rho, theta, cfg, k, sec_theta, D_sq, h0)
    z1 = D_sq / 16 + 1i * (h - h0) * sec_theta / k;
    power_term = z1.^(alpha / 2 - 1);

    denom = k * D_sq + 1i * 16 * (h - h0) * sec_theta;
    arg_hyp = -(4 * rho^2 * k) ./ denom;
    hyp = hypergeom(1 - alpha / 2, 1, arg_hyp);

    val = Cn2_tilde(h, alpha, theta, cfg) .* power_term .* hyp;
end
