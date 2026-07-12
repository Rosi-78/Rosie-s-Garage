function cn2 = hv_cn2_profile_exact(h, cfg)
%HV_CN2_PROFILE_EXACT Hufnagel-Valley refractive-index structure profile.
%
%   Same as hv_cn2_profile.m in EGC_MRC_Analysis; duplicated here so the
%   ExactPaperModel folder is self-contained.
%
%   Equation (10) in the paper.

    cn2 = 0.00594 * (cfg.wind_speed / 27)^2 .* (1e-5 * h).^10 ...
        .* exp(-h / 1000) ...
        + 2.7e-16 .* exp(-h / 1500) ...
        + cfg.Cn2_ground .* exp(-h / 100);
    cn2 = cfg.turbulence_strength_scale .* cn2;
end
