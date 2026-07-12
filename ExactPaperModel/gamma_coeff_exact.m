function gamma_ij = gamma_coeff_exact(rho, alpha, theta, cfg)
%GAMMA_COEFF_EXACT Spatial correlation coefficient gamma(rho, alpha).
%
%   Equation (7): gamma = zeta(rho) / zeta(0)
%
%   Inputs:
%       rho   - aperture separation in meters
%       alpha - power-law exponent
%       theta - zenith angle in radians
%       cfg   - configuration struct
%   Output:
%       gamma_ij - correlation coefficient in [-1, 1]

    z_rho = zeta_exact(rho, alpha, theta, cfg);
    z_0 = zeta_exact(0.0, alpha, theta, cfg);

    if ~isfinite(z_rho) || ~isfinite(z_0) || abs(z_0) < 1e-12
        if rho > 0
            gamma_ij = 0.0;
        else
            gamma_ij = 1.0;
        end
        return;
    end

    gamma_ij = z_rho / z_0;

    % Numerical clamp
    gamma_ij = max(-0.9999, min(0.9999, gamma_ij));
end
