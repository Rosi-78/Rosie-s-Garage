function plot_metric_comparison_dB( ...
    comparison, modulation, combiner, scenario_set, results_dir)
%PLOT_METRIC_COMPARISON_DB Comparison plots with outage in dB.
%
%   Same information as plot_metric_comparison.m, but the outage panel uses
%   a dB vertical axis (10*log10(p)) to separate very small probabilities.

    colors = lines(numel(comparison.labels));
    markers = {'o', 's', '^', 'd', 'v', '>'};

    y_floor_prob = 0.5 ./ comparison.cfg{1}.num_monte;
    y_floor_db = 10 * log10(y_floor_prob);
    outage_plot = max(comparison.outage, y_floor_prob);
    outage_db = 10 * log10(outage_plot);

    photons_dB = 10 * log10(comparison.avg_signal);
    title_prefix = [upper(modulation), '-', upper(combiner), ...
        ' ', scenario_set.title, ' (dB)'];
    legend_labels = build_legend_labels_exact(comparison, scenario_set);

    fig = figure('Color', 'w', 'Position', [80, 80, 1180, 410]);
    layout = tiledlayout(fig, 1, 3, ...
        'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile(layout);
    hold on;
    for idx = 1:numel(comparison.labels)
        plot(photons_dB, comparison.mi(idx, :), ...
            'Color', colors(idx, :), ...
            'Marker', markers{1 + mod(idx - 1, numel(markers))}, ...
            'LineWidth', 1.5, 'MarkerSize', 4);
    end
    yline(comparison.rate_threshold, 'k:', 'LineWidth', 1);
    grid on;
    xlabel('Mean signal photons (dB)');
    ylabel('MI (bit/symbol)');
    title([title_prefix, ' MI']);

    ax2 = nexttile(layout);
    hold on;
    for idx = 1:numel(comparison.labels)
        plot(photons_dB, comparison.ergodic_capacity(idx, :), ...
            'Color', colors(idx, :), ...
            'Marker', markers{1 + mod(idx - 1, numel(markers))}, ...
            'LineWidth', 1.5, 'MarkerSize', 4);
    end
    grid on;
    xlabel('Mean signal photons (dB)');
    ylabel('E[log_2(1+\gamma)] (bit/symbol)');
    title([title_prefix, ' ergodic capacity']);

    ax3 = nexttile(layout);
    hold on;
    for idx = 1:numel(comparison.labels)
        plot(photons_dB, outage_db(idx, :), ...
            'Color', colors(idx, :), ...
            'Marker', markers{1 + mod(idx - 1, numel(markers))}, ...
            'LineWidth', 1.5, 'MarkerSize', 4);
    end
    yline(y_floor_db, 'Color', [0.55, 0.55, 0.55], 'LineStyle', '--');
    grid on;
    xlabel('Mean signal photons (dB)');
    ylabel('Outage probability (dB)');
    title([title_prefix, ' channel outage (dB)']);
    lgd = legend(ax1, legend_labels, ...
        'Orientation', 'horizontal', 'NumColumns', numel(legend_labels));
    lgd.Layout.Tile = 'south';

    style_figure_for_export(fig);
    file_prefix = ['EXACT_', upper(modulation), '_', upper(combiner), '_', ...
        scenario_set.key, '_Metrics_dB_Axis'];
    exportgraphics(fig, fullfile(results_dir, [file_prefix, '.png']), ...
        'Resolution', 180);
end

function legend_labels = build_legend_labels_exact(comparison, scenario_set)
    legend_labels = cell(size(comparison.labels));
    for idx = 1:numel(comparison.labels)
        if strcmp(scenario_set.key, 'ReceiverNumber')
            legend_labels{idx} = sprintf('%s', comparison.labels{idx});
        elseif strcmp(scenario_set.key, 'Correlation')
            corr_mean = comparison.mean_corr(idx);
            corr_max = NaN;
            if isfield(comparison, 'mean_model_corr')
                corr_mean = comparison.mean_model_corr(idx);
                corr_max = comparison.max_model_corr(idx);
            end
            legend_labels{idx} = sprintf('%s, d=%.2fm, R=%s/%s', ...
                comparison.labels{idx}, comparison.mean_spacing(idx), ...
                format_corr_value(corr_mean), format_corr_value(corr_max));
        else
            legend_labels{idx} = sprintf('%s, sigma_I^2=%.2g', ...
                comparison.labels{idx}, comparison.turbulence_sigma_i2(idx));
        end
    end
end

function text = format_corr_value(value)
    if isnan(value)
        text = '-';
    elseif value == 0
        text = '0';
    elseif abs(value) < 1e-3
        text = sprintf('%.1e', value);
    else
        text = sprintf('%.3f', value);
    end
end
