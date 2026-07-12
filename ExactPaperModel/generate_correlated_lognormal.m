function h = generate_correlated_lognormal(num_samples, sigma_i2, corr_matrix)
%GENERATE_CORRELATED_LOGNORMAL Correlated log-normal irradiance samples.
%
%   Matches the paper's weak-turbulence assumption: each branch is
%   log-normal with E[h_m] = 1, and the pairwise correlation is given by
%   corr_matrix. The mapping is performed directly via Cholesky on the
%   Gaussian domain, without a copula.
%
%   Inputs:
%       num_samples  - number of channel realizations
%       sigma_i2     - variance parameter of ln(h), i.e. zeta(0, alpha)
%       corr_matrix  - MxM correlation matrix for the Gaussian domain
%   Output:
%       h            - MxN matrix of normalized irradiance samples

    num_receivers = size(corr_matrix, 1);

    % Cholesky with small diagonal regularization for numerical stability
    chol_factor = chol(corr_matrix + 1e-10 * eye(num_receivers), 'lower');

    z = randn(num_receivers, num_samples);
    z_corr = chol_factor * z;

    % ln(h) ~ N(-sigma_i2/2, sigma_i2) so that E[h] = 1
    mu_log = -sigma_i2 / 2;
    sigma_log = sqrt(sigma_i2);

    h = exp(mu_log + sigma_log * z_corr);

    % Normalize each branch to unit mean
    h = h ./ mean(h, 2);
end
