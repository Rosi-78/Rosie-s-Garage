function y = qfunc_local(x)
%QFUNC_LOCAL Q-function without Communications Toolbox.
%
%   Q(x) = 0.5 * erfc(x / sqrt(2))

    y = 0.5 * erfc(x / sqrt(2));
end
