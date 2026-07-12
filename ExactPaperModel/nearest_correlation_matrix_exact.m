function corr_matrix = nearest_correlation_matrix_exact(matrix_in)
%NEAREST_CORRELATION_MATRIX_EXACT Project a symmetric matrix to PSD correlation.
%
%   Same algorithm as nearest_correlation_matrix.m in EGC_MRC_Analysis;
%   duplicated here for self-containment.

    sym_matrix = (matrix_in + matrix_in.') / 2;
    [vectors, values] = eig(sym_matrix);
    values = max(diag(values), 1e-6);
    psd_matrix = vectors * diag(values) * vectors.';
    scale = sqrt(diag(psd_matrix));
    corr_matrix = psd_matrix ./ (scale * scale.');
    corr_matrix = (corr_matrix + corr_matrix.') / 2;
    corr_matrix(1:size(corr_matrix, 1) + 1:end) = 1;
end
