function metrics = attach_equivalent_snr_metrics_exact(metrics, gamma, rate_threshold)
%ATTACH_EQUIVALENT_SNR_METRICS_EXACT Add capacity and channel-outage metrics.
%
%   Mirrors attach_equivalent_snr_metrics.m in EGC_MRC_Analysis.

    gamma = max(gamma, 0);
    instant_capacity = log2(1 + gamma);

    if isfield(metrics, 'outage')
        metrics.posterior_outage = metrics.outage;
    end

    metrics.snr_capacity = mean(instant_capacity);
    metrics.snr_outage = mean(instant_capacity < rate_threshold);
    metrics.outage = metrics.snr_outage;
end
