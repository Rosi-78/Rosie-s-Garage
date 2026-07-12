function metrics = simulate_path_metrics_exact(modulation, combiner, ...
    h, lambda_signal, cfg, corr_matrix, sigma_i2)
%SIMULATE_PATH_METRICS_EXACT Dispatch one modulation/combiner path.
%
%   Same interface as simulate_path_metrics.m in EGC_MRC_Analysis, but
%   requires corr_matrix and sigma_i2 for the OOK-EGC Gauss-Hermite BER.

    switch [lower(modulation), '_', lower(combiner)]
        case 'ook_egc'
            metrics = simulate_ook_egc_exact( ...
                h, lambda_signal, cfg, corr_matrix, sigma_i2);
        case 'ook_mrc'
            metrics = simulate_ook_mrc_exact(h, lambda_signal, cfg);
        case 'ppm_egc'
            metrics = simulate_ppm_egc_exact(h, lambda_signal, cfg);
        case 'ppm_mrc'
            metrics = simulate_ppm_mrc_exact(h, lambda_signal, cfg);
        otherwise
            error('Unsupported path: %s-%s', modulation, combiner);
    end
end
