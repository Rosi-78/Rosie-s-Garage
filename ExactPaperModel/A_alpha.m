function Aa = A_alpha(alpha)
%A_ALPHA Non-Kolmogorov power-spectrum coefficient A(alpha).
%   非柯湍流功率谱系数
%   Equation (9) in the paper:
%       A(alpha) = cos(alpha*pi/2) * Gamma(alpha-1) / (4*pi^2)
%
%   Input:
%       alpha - power-law exponent, 3 < alpha < 4
%   Output:
%       Aa    - coefficient value

    Aa = cos(alpha * pi / 2) * gamma(alpha - 1) / (4 * pi^2);
end
