function print_snapshot_summary_exact(snapshot)
%PRINT_SNAPSHOT_SUMMARY_EXACT Print satellite snapshot and channel summary.

    cfg = snapshot.cfg;
    turb = snapshot.turb;
    receiver_info = snapshot.receiver_info;
    corr_matrix = snapshot.corr_matrix;

    fprintf('=== Satellite snapshot and EXACT turbulence summary ===\n');
    fprintf('satellite altitude = %.3e m, zenith = %.2f deg\n', ...
        cfg.satellite_altitude, cfg.zenith_angle_deg);
    fprintf('slant path length = %.3e m\n', turb.path_length);
    fprintf('integral Cn2 dh = %.3e\n', turb.cn2_integral);
    fprintf('exact scintillation index sigma_I^2 = %.3e\n', turb.sigma_i2);
    fprintf('receiver rings = [%s] m, receivers per ring = [%s]\n', ...
        num2str(cfg.ring_radii), num2str(receiver_info.num_per_ring.'));
    fprintf('total receivers = %d\n', cfg.num_receivers);
    fprintf('Fried r0 = %.3f m\n', turb.r0);
    fprintf('target mean off-diagonal corr = %.3f\n', ...
        mean(corr_matrix(triu(true(cfg.num_receivers), 1))));
    fprintf('sample mean irradiance corr = %.3f\n', ...
        snapshot.mean_empirical_corr);
end
