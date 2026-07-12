function H = binary_entropy_exact(p)
%BINARY_ENTROPY_EXACT Binary entropy in bits.
%
%   H(p) = -p*log2(p) - (1-p)*log2(1-p)

    p = max(min(p, 1 - eps), eps);
    H = -p .* log2(p) - (1 - p) .* log2(1 - p);
end
