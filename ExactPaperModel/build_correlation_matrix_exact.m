function corr_matrix = build_correlation_matrix_exact(positions, turb, cfg)
%BUILD_CORRELATION_MATRIX_EXACT Spatial correlation from the paper's integral.
%
%   Replaces the exponential-decay approximation in
%   build_physical_correlation_matrix.m with the exact gamma(rho, alpha)
%   derived from the non-Kolmogorov power spectrum.
%
%   Inputs:
%       positions - Nx2 receiver coordinates [x, y] in meters
%       turb      - turbulence parameter struct (sigma_i2, etc.)
%       cfg       - configuration struct
%   Output:
%       corr_matrix - NxN correlation matrix

    num_receivers = size(positions, 1);
    theta = deg2rad(cfg.zenith_angle_deg);
    alpha = cfg.alpha_nonK;

    delta_x = positions(:, 1) - positions(:, 1).';
    delta_y = positions(:, 2) - positions(:, 2).';
    distance = sqrt(delta_x.^2 + delta_y.^2);

    corr_matrix = eye(num_receivers);
    for i = 1:num_receivers
        for j = i + 1:num_receivers
            rho_ij = distance(i, j);
            gamma_ij = gamma_coeff_exact(rho_ij, alpha, theta, cfg);
            corr_matrix(i, j) = gamma_ij;
            corr_matrix(j, i) = gamma_ij;
        end
    end

    % Project to nearest positive-semidefinite correlation matrix
    corr_matrix = nearest_correlation_matrix_exact(corr_matrix);
end
