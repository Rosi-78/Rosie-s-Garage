%% Smoke test for the exact paper model functions.
%   Run this in MATLAB before the full analysis to verify basic correctness.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));

cfg = make_default_config();
theta = deg2rad(cfg.zenith_angle_deg);
alpha = cfg.alpha_nonK;

fprintf('=== Test 1: A(alpha) ===\n');
Aa = A_alpha(alpha);
fprintf('A(%.4f) = %.6e\n\n', alpha, Aa);

fprintf('=== Test 2: Exact scintillation index sigma_I^2 ===\n');
sigma_i2 = zeta_exact(0.0, alpha, theta, cfg);
fprintf('sigma_I^2 = %.6e\n\n', sigma_i2);

fprintf('=== Test 3: Spatial correlation gamma(rho) ===\n');
rho_list = [0, 0.01, 0.05, 0.10, 0.30];
for rho = rho_list
    g = gamma_coeff_exact(rho, alpha, theta, cfg);
    fprintf('gamma(%.2f cm) = %.6f\n', rho * 100, g);
end

fprintf('\n=== Test 4: Gauss-Hermite quadrature nodes ===\n');
[x, w] = gauss_hermite_nodes(8);
fprintf('Sum of weights should be sqrt(pi) = %.6f; actual = %.6f\n', ...
    sqrt(pi), sum(w));

fprintf('\n=== Test 5: Correlation matrix for 3 receivers ===\n');
cfg.ring_radii = 0.10;
cfg.ring_num_receivers = 3;
snapshot = prepare_channel_snapshot_exact(cfg);
disp(snapshot.corr_matrix);
fprintf('Mean off-diagonal correlation = %.4f\n', ...
    mean(snapshot.corr_matrix(triu(true(3), 1))));

fprintf('\n=== Test 6: Analytical OOK-EGC BER at one SNR point ===\n');
lambda_signal = 10.0;
ber = ber_ook_egc_gauss_hermite(lambda_signal, snapshot.corr_matrix, sigma_i2);
fprintf('BER (lambda=%.1f) = %.6e\n', lambda_signal, ber);

fprintf('\nSmoke test completed.\n');
