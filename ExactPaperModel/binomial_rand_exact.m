function counts = binomial_rand_exact(n, p)
%BINOMIAL_RAND_EXACT Draw binomial samples without Statistics Toolbox.
%
%   Same algorithm as binomial_rand.m in EGC_MRC_Analysis.

    counts = zeros(size(p));
    for trial = 1:n
        counts = counts + (rand(size(p)) < p);
    end
end
