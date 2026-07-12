function comparison = run_scenario_set_exact(modulation, combiner, scenario_set)
%RUN_SCENARIO_SET_EXACT Run one scenario family for one modulation/combiner path.
%
%   Same interface as run_scenario_set.m in EGC_MRC_Analysis.

    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));

    base_cfg = make_exact_config();
    num_scenarios = numel(scenario_set.scenarios);
    num_points = numel(base_cfg.avg_signal);

    comparison.avg_signal = base_cfg.avg_signal;
    comparison.mi = zeros(num_scenarios, num_points);
    comparison.ergodic_capacity = zeros(num_scenarios, num_points);
    comparison.outage = zeros(num_scenarios, num_points);
    comparison.posterior_outage = zeros(num_scenarios, num_points);
    comparison.mean_corr = zeros(1, num_scenarios);
    comparison.mean_model_corr = zeros(1, num_scenarios);
    comparison.max_model_corr = zeros(1, num_scenarios);
    comparison.mean_spacing = zeros(1, num_scenarios);
    comparison.num_receivers = zeros(1, num_scenarios);
    comparison.turbulence_sigma_i2 = zeros(1, num_scenarios);
    comparison.labels = cell(1, num_scenarios);
    comparison.cfg = cell(1, num_scenarios);
    comparison.snapshot = cell(1, num_scenarios);

    for scenario_idx = 1:num_scenarios
        cfg = base_cfg;
        cfg.num_monte = cfg.comparison_num_monte;
        scenario = scenario_set.scenarios(scenario_idx);
        for field_idx = 1:numel(scenario.fields)
            cfg.(scenario.fields{field_idx}) = scenario.values{field_idx};
        end
        cfg.random_seed = base_cfg.random_seed + 1000 * scenario_idx;
        rng(cfg.random_seed, 'twister');

        snapshot = prepare_channel_snapshot_exact(cfg);
        cfg = snapshot.cfg;
        h = snapshot.h;
        corr_matrix = snapshot.corr_matrix;
        sigma_i2 = snapshot.turb.sigma_i2;

        comparison.labels{scenario_idx} = scenario.label;
        comparison.mean_corr(scenario_idx) = snapshot.mean_empirical_corr;
        off_diag_corr = snapshot.corr_matrix( ...
            triu(true(cfg.num_receivers), 1));
        comparison.mean_model_corr(scenario_idx) = mean(off_diag_corr);
        comparison.max_model_corr(scenario_idx) = max(off_diag_corr);
        comparison.mean_spacing(scenario_idx) = mean_pairwise_spacing_exact( ...
            snapshot.positions);
        comparison.num_receivers(scenario_idx) = cfg.num_receivers;
        comparison.turbulence_sigma_i2(scenario_idx) = snapshot.turb.sigma_i2;
        comparison.cfg{scenario_idx} = cfg;
        snapshot_for_save = snapshot;
        snapshot_for_save.h = [];
        comparison.snapshot{scenario_idx} = snapshot_for_save;

        fprintf('\n%s-%s, %s: %s\n', upper(modulation), upper(combiner), ...
            scenario_set.title, scenario.label);
        fprintf(['M=%d, mean spacing=%.3f m, model corr mean/max=%.3f/%.3f, ', ...
            'sample corr=%.3f, sigma_I^2=%.3g\n'], ...
            cfg.num_receivers, comparison.mean_spacing(scenario_idx), ...
            comparison.mean_model_corr(scenario_idx), ...
            comparison.max_model_corr(scenario_idx), ...
            snapshot.mean_empirical_corr, snapshot.turb.sigma_i2);

        for point_idx = 1:num_points
            lambda_sweep = base_cfg.avg_signal(point_idx);
            lambda_signal = lambda_sweep;
            if strcmpi(cfg.photon_budget_mode, 'total')
                lambda_signal = lambda_signal / cfg.num_receivers;
            end

            metrics = simulate_path_metrics_exact( ...
                modulation, combiner, h, lambda_signal, cfg, corr_matrix, sigma_i2);
            comparison.mi(scenario_idx, point_idx) = metrics.mi;
            comparison.ergodic_capacity(scenario_idx, point_idx) = ...
                metrics.snr_capacity;
            comparison.outage(scenario_idx, point_idx) = metrics.outage;
            if isfield(metrics, 'posterior_outage')
                comparison.posterior_outage(scenario_idx, point_idx) = ...
                    metrics.posterior_outage;
            end

            fprintf('  point %02d/%02d, photons=%.3f: MI=%.3f, Cerg=%.3f, outage=%.3e, GH_BER=%.3e\n', ...
                point_idx, num_points, lambda_sweep, metrics.mi, ...
                metrics.snr_capacity, metrics.outage, metrics.snr_ber);
        end
    end

    comparison.rate_threshold = get_rate_threshold(modulation, base_cfg);
end

function spacing = mean_pairwise_spacing_exact(positions)
    num_receivers = size(positions, 1);
    if num_receivers < 2
        spacing = 0;
        return;
    end

    delta_x = positions(:, 1) - positions(:, 1).';
    delta_y = positions(:, 2) - positions(:, 2).';
    distance = sqrt(delta_x.^2 + delta_y.^2);
    spacing = mean(distance(triu(true(num_receivers), 1)));
end
