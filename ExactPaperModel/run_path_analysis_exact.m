function run_path_analysis_exact(modulation, combiner)
%RUN_PATH_ANALYSIS_EXACT Shared runner for one modulation/combiner path.
%
%   Same experimental design as run_path_analysis.m in EGC_MRC_Analysis,
%   but uses the exact non-Kolmogorov correlation model and the paper's
%   log-normal channel. OOK-EGC additionally uses Gauss-Hermite quadrature
%   for the analytical BER curve.

    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));

    cfg = make_exact_config();
    rng(cfg.random_seed, 'twister');

    snapshot = prepare_channel_snapshot_exact(cfg);
    cfg = snapshot.cfg;
    print_snapshot_summary_exact(snapshot);
    h = snapshot.h;
    corr_matrix = snapshot.corr_matrix;
    sigma_i2 = snapshot.turb.sigma_i2;

    num_points = numel(cfg.avg_signal);
    results.mi = zeros(1, num_points);
    results.ber = zeros(1, num_points);
    results.outage = zeros(1, num_points);
    results.posterior_outage = zeros(1, num_points);
    results.snr_ber = zeros(1, num_points);
    results.snr_capacity = zeros(1, num_points);

    for idx = 1:num_points
        lambda_sweep = cfg.avg_signal(idx);
        lambda_signal = lambda_sweep;
        if strcmpi(cfg.photon_budget_mode, 'total')
            lambda_signal = lambda_signal / cfg.num_receivers;
        end
        metrics = simulate_path_metrics_exact( ...
            modulation, combiner, h, lambda_signal, cfg, corr_matrix, sigma_i2);
        results.mi(idx) = metrics.mi;
        results.ber(idx) = metrics.ber;
        results.outage(idx) = metrics.outage;
        if isfield(metrics, 'posterior_outage')
            results.posterior_outage(idx) = metrics.posterior_outage;
        end
        results.snr_ber(idx) = metrics.snr_ber;
        results.snr_capacity(idx) = metrics.snr_capacity;

        fprintf(['%s-%s point %02d/%02d, sweep photons=%.3f, ', ...
            'per-rx photons=%.3f: MI=%.3f, err=%.3e, GH_BER=%.3e\n'], ...
            upper(modulation), upper(combiner), idx, num_points, ...
            lambda_sweep, lambda_signal, results.mi(idx), results.ber(idx), ...
            results.snr_ber(idx));
    end

    results_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end

    title_prefix = [upper(modulation), '-', upper(combiner), ' (Exact)'];
    file_prefix = ['EXACT_', upper(modulation), '_', upper(combiner)];
    rate_threshold = get_rate_threshold(modulation, cfg);
    plot_single_path_results( ...
        cfg, results, rate_threshold, title_prefix, file_prefix, results_dir);
    plot_single_path_dB( ...
        cfg, results, rate_threshold, title_prefix, file_prefix, results_dir);

    save(fullfile(results_dir, [file_prefix, '_results.mat']), ...
        'cfg', 'snapshot', 'results', 'modulation', 'combiner');
end
