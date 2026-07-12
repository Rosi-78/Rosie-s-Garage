%% Compare MI, ergodic capacity, and outage under three scenario families.
%%
%% Same experimental design as run_metric_comparison_analysis.m in
%% EGC_MRC_Analysis, but uses the exact non-Kolmogorov correlation integral
%% and the paper's log-normal channel model.

addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));

clear; clc;

paths = { ...
    'ook', 'egc'; ...
    'ook', 'mrc'; ...
    'ppm', 'egc'; ...
    'ppm', 'mrc'};

scenario_sets = build_metric_scenarios_exact();
results_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

for path_idx = 1:size(paths, 1)
    modulation = paths{path_idx, 1};
    combiner = paths{path_idx, 2};

    for set_idx = 1:numel(scenario_sets)
        scenario_set = scenario_sets(set_idx);
        comparison = run_scenario_set_exact(modulation, combiner, scenario_set);
        plot_metric_comparison( ...
            comparison, modulation, combiner, scenario_set, results_dir);
        plot_metric_comparison_dB( ...
            comparison, modulation, combiner, scenario_set, results_dir);

        file_prefix = ['EXACT_', upper(modulation), '_', upper(combiner), '_', ...
            scenario_set.key];
        save(fullfile(results_dir, [file_prefix, '_comparison.mat']), ...
            'comparison', 'modulation', 'combiner', 'scenario_set');
    end
end

disp('Exact metric comparison analysis finished.');
