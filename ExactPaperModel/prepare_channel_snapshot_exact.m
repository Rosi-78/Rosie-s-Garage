function snapshot = prepare_channel_snapshot_exact(cfg)
%PREPARE_CHANNEL_SNAPSHOT_EXACT Build geometry, exact turbulence, channel.
%
%   Same interface as prepare_channel_snapshot.m in EGC_MRC_Analysis, but
%   uses the exact non-Kolmogorov correlation integral and log-normal
%   channel generation.

    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));

    [positions, receiver_info] = build_receiver_array(cfg);
    cfg.num_receivers = size(positions, 1);

    turb = derive_turbulence_parameters_exact(cfg);
    corr_matrix = build_correlation_matrix_exact(positions, turb, cfg);

    h = generate_correlated_lognormal( ...
        cfg.num_monte, turb.sigma_i2, corr_matrix);

    empirical_corr = corrcoef(h.');
    mean_empirical_corr = mean( ...
        empirical_corr(triu(true(cfg.num_receivers), 1)));

    snapshot.cfg = cfg;
    snapshot.positions = positions;
    snapshot.receiver_info = receiver_info;
    snapshot.turb = turb;
    snapshot.corr_matrix = corr_matrix;
    snapshot.h = h;
    snapshot.mean_empirical_corr = mean_empirical_corr;
end
