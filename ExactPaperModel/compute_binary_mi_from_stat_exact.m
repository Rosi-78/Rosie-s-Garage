function [mi, local_mi] = compute_binary_mi_from_stat_exact( ...
    stat0, stat1, stat_obs, grid_size)
%COMPUTE_BINARY_MI_FROM_STAT_EXACT Estimate binary MI from a scalar statistic.
%
%   Mirrors compute_binary_mi_from_stat.m in EGC_MRC_Analysis.

    all_stat = [stat0(:); stat1(:)];
    if min(all_stat) == max(all_stat)
        mi = 0;
        local_mi = zeros(size(stat_obs));
        return;
    end

    edges = linspace(min(all_stat), max(all_stat), grid_size + 1);
    p0 = histcounts(stat0, edges, 'Normalization', 'probability');
    p1 = histcounts(stat1, edges, 'Normalization', 'probability');

    bin_idx = discretize(stat_obs, edges);
    bin_idx(isnan(bin_idx) & stat_obs >= edges(end)) = grid_size;
    bin_idx(isnan(bin_idx) & stat_obs <= edges(1)) = 1;
    bin_idx(isnan(bin_idx)) = grid_size;

    like0 = max(p0(bin_idx), eps);
    like1 = max(p1(bin_idx), eps);
    post1 = like1 ./ (like0 + like1);
    local_mi = 1 - binary_entropy_exact(post1);
    mi = mean(local_mi);
end
