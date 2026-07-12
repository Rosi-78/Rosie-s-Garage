function cfg = make_exact_config()
%MAKE_EXACT_CONFIG Default parameters tuned for the exact paper model.
%
%   The original make_default_config.m is tuned for the Gamma-Gamma
%   approximation, whose scintillation strength and correlation decay are
%   stronger than the exact weak-turbulence log-normal model. This config
%   lowers the photon budget range and uses smaller receiver spacing so
%   that turbulence/correlation comparisons show visible differences.

    addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'EGC_MRC_Analysis'));
    cfg = make_default_config();

    % Lower photon budget so that MI/BER/outage are not already saturated.
    cfg.avg_signal = [ ...
        0.02, 0.03, 0.05, 0.07, 0.10, 0.15, 0.20, 0.30, ...
        0.50, 0.70, 1.00, 1.50, 2.00, 3.00, 5.00, 7.00];

    % Smaller rings: the exact correlation model decays to zero on the
    % centimeter scale (see paper Fig. 2 with D=5 cm).
    cfg.ring_radii = 0.05;          % m
    cfg.ring_arc_length = 0.10;     % m, gives ~3 receivers by default
    cfg.ring_num_receivers = [];    % use arc-length rule

    % Raise the outage threshold a bit so that outage transitions are
    % visible with the lowered photon budget.
    cfg.rate_threshold_ook = 0.50;
    cfg.rate_threshold_ppm = 0.50 * log2(cfg.ppm_order);

    % Fewer Monte Carlo samples are acceptable because the analytical
    % Gauss-Hermite BER does not rely on MC resolution.
    cfg.num_monte = 20000;
    cfg.comparison_num_monte = 20000;
end
