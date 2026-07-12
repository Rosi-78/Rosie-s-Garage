function turb = derive_turbulence_parameters_exact(cfg)
%DERIVE_TURBULENCE_PARAMETERS_EXACT Physical parameters using the paper's exact integral.
%
%   Unlike derive_turbulence_parameters.m, this function computes the
%   scintillation index from zeta(0, alpha) (equation 12) and does not
%   introduce the Gamma-Gamma mapping.
%
%   Input:
%       cfg - configuration struct
%   Output:
%       turb - struct with path length, scintillation index, etc.

    k = 2 * pi / cfg.wavelength;
    theta = deg2rad(cfg.zenith_angle_deg);
    sec_theta = 1 / cos(theta);
    vertical_path = cfg.satellite_altitude - cfg.ground_altitude;
    path_length = vertical_path * sec_theta;

    % HV profile integral (used for r0 and diagnostics)
    h_grid = linspace(cfg.ground_altitude, cfg.satellite_altitude, 1200);
    cn2_grid = hv_cn2_profile_exact(h_grid, cfg);
    cn2_integral = trapz(h_grid, cn2_grid);

    % Exact scintillation index from the paper: sigma_I^2 = zeta(0, alpha)
    sigma_i2 = zeta_exact(0.0, cfg.alpha_nonK, theta, cfg);
    sigma_i2 = max(1e-4, sigma_i2);

    % Fried parameter (kept for diagnostics)
    r0 = (0.423 * k^2 * sec_theta * cn2_integral)^(-3 / 5);

    % rho_c is not used by the exact correlation model, but kept for
    % compatibility with diagnostic printing.
    rho_c = NaN;

    turb.path_length = path_length;
    turb.vertical_path = vertical_path;
    turb.cn2_integral = cn2_integral;
    turb.sigma_rytov2 = NaN;
    turb.sigma_i2 = sigma_i2;
    turb.alpha_gg = NaN;
    turb.beta_gg = NaN;
    turb.r0 = r0;
    turb.rho_c = rho_c;
end
