function plot_single_path_dB(cfg, results, rate_threshold, title_prefix, file_prefix, results_dir)
%PLOT_SINGLE_PATH_DB Single-path performance with outage/BER in dB.
%
%   Same information as plot_single_path_results.m, but the BER and outage
%   panels use a dB vertical axis (10*log10(p)) so that very small
%   probabilities are spread out and differences become visible.
%
%   Inputs mirror plot_single_path_results.m exactly.

    y_floor_prob = 0.5 / cfg.num_monte;
    y_floor_db = 10 * log10(y_floor_prob);

    % Clip probabilities before converting to dB
    ber_plot = max(results.ber, y_floor_prob);
    outage_plot = max(results.outage, y_floor_prob);
    snr_ber_plot = max(results.snr_ber, y_floor_prob);

    ber_db = 10 * log10(ber_plot);
    outage_db = 10 * log10(outage_plot);
    snr_ber_db = 10 * log10(snr_ber_plot);

    photons_dB = 10 * log10(cfg.avg_signal);

    fig = figure('Color', 'w', 'Position', [80, 80, 1100, 360]);
    tiledlayout(fig, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    plot(photons_dB, results.mi, 'b-', 'LineWidth', 1.6); hold on;
    yline(rate_threshold, 'k:', 'LineWidth', 1);
    grid on; xlabel('Mean signal photons (dB)');
    ylabel('MI (bit/symbol)');
    title([title_prefix, ' MI']);

    nexttile;
    plot(photons_dB, ber_db, 'r-', 'LineWidth', 1.6); hold on;
    plot(photons_dB, snr_ber_db, 'k:', 'LineWidth', 1.1);
    yline(y_floor_db, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--');
    grid on; xlabel('Mean signal photons (dB)');
    ylabel('BER / SER (dB)');
    title([title_prefix, ' error rate (dB)']);
    legend({'count-domain', 'equivalent-SNR / GH', 'MC resolution'}, ...
        'Location', 'southoutside', 'Orientation', 'horizontal');

    nexttile;
    plot(photons_dB, outage_db, 'm-', 'LineWidth', 1.6); hold on;
    yline(y_floor_db, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--');
    grid on; xlabel('Mean signal photons (dB)');
    ylabel('Outage probability (dB)');
    title([title_prefix, ' channel outage (dB)']);

    style_figure_for_export(fig);
    exportgraphics(fig, fullfile(results_dir, [file_prefix, '_Performance_dB_Axis.png']), ...
        'Resolution', 180);
end
