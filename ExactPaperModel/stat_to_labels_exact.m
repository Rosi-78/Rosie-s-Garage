function labels = stat_to_labels_exact(stat, edges)
%STAT_TO_LABELS_EXACT Quantize a statistic matrix/vector into positive labels.
%
%   Mirrors stat_to_labels.m in EGC_MRC_Analysis.

    labels = discretize(stat, edges);
    labels(isnan(labels) & stat <= edges(1)) = 1;
    labels(isnan(labels) & stat >= edges(end)) = numel(edges) - 1;
    labels(isnan(labels)) = numel(edges) - 1;
end
