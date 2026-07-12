function z = zeta_exact(rho, alpha, theta, cfg)
%ZETA_EXACT Irradiance covariance zeta(rho, alpha) from the paper.
%
%   Equation (12): zeta = exp(theta1 + theta2) - 1
%
%   Inputs:
%       rho   - aperture separation in meters
%       alpha - power-law exponent
%       theta - zenith angle in radians
%       cfg   - configuration struct
%   Output:
%       z     - covariance value

    v1 = calc_vartheta1(alpha, rho, theta, cfg);
    v2 = calc_vartheta2(alpha, rho, theta, cfg);

    if ~isfinite(v1) || ~isfinite(v2)
        z = 1.0;
        return;
    end

    total = v1 + v2;
    % Avoid overflow: exp(700) ~ 1e304
    if total > 700
        z = exp(700) - 1;
    else
        z = exp(total) - 1;
    end
end
