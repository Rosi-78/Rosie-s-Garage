# Exact Paper Model

本文件夹实现《非柯湍流对星地激光通信分集接收系统性能影响》论文中的**精确建模方法**，与 `EGC_MRC_Analysis/` 中的工程近似模型并行存在，互不修改。

## 与 `EGC_MRC_Analysis` 的区别

| 模块 | `EGC_MRC_Analysis` | `ExactPaperModel` |
|------|-------------------|-------------------|
| 湍流光强分布 | Gamma-Gamma | 弱湍流对数正态（与论文一致） |
| 空间相关性 | 指数衰减近似 | 非柯功率谱积分 + 合流超几何函数（论文公式 7–14） |
| 相关信道生成 | Gaussian Copula | 直接对相关高斯变量做 Cholesky 变换 |
| OOK-EGC BER | 等效 SNR + Q 函数 Monte Carlo | 高斯-埃尔米特数值积分（论文公式 20） |
| OOK-MRC / PPM | Monte Carlo | Monte Carlo（论文未给出闭式） |

## 文件结构

```text
ExactPaperModel/
├── A_alpha.m                          % 非柯功率谱系数 A(α)
├── Cn2_tilde.m                        % 等效结构常数 Cn2~(h,α)
├── calc_vartheta1.m / calc_vartheta2.m % 协方差积分两个分量 θ1, θ2
├── zeta_exact.m                       % 光强协方差 ζ(ρ,α)
├── gamma_coeff_exact.m                % 空间相关系数 γ(ρ,α)
├── hv_cn2_profile_exact.m             % HV 剖面 Cn2(h)
├── derive_turbulence_parameters_exact.m
├── build_correlation_matrix_exact.m
├── nearest_correlation_matrix_exact.m
├── generate_correlated_lognormal.m    % 相关对数正态信道
├── gauss_hermite_nodes.m              % 高斯-埃尔米特节点权重
├── ber_ook_egc_gauss_hermite.m        % 论文公式 (20) BER
├── simulate_*_exact.m                 % OOK/PPM + EGC/MRC 仿真
├── run_path_analysis_exact.m          % 单条路径入口
├── run_ook_egc_analysis_exact.m       % OOK-EGC 快速入口
├── run_metric_comparison_exact.m      % 三类对比实验（保持原实验设计）
├── build_metric_scenarios_exact.m     % 为精确模型调参后的对比场景
├── make_exact_config.m                % 精确模型专用默认配置
├── plot_single_path_dB.m              % 单路径 outage/BER 纵坐标 dB 图
├── plot_metric_comparison_dB.m        % 对比实验 outage 纵坐标 dB 图
├── test_exact_model_smoke.m           % MATLAB 冒烟测试
└── README.md
```

## 运行方式

在 MATLAB 中进入 `ExactPaperModel` 文件夹：

```matlab
% 单条路径（OOK-EGC，含高斯-埃尔米特 BER）
run_ook_egc_analysis_exact

% 任意调制/合并组合
run_path_analysis_exact('ook', 'egc')
run_path_analysis_exact('ook', 'mrc')
run_path_analysis_exact('ppm', 'egc')
run_path_analysis_exact('ppm', 'mrc')

% 完整三类对比实验（湍流强度 / 相关性 / 接收机数量）
run_metric_comparison_exact
```

输出保存在 `ExactPaperModel/results/`。额外生成 outage/BER 纵坐标为 **dB**（`10*log10(p)`）的图，便于观察接近 0 的概率差异。

## 复用接口

入口脚本会自动把 `../EGC_MRC_Analysis` 加入 MATLAB 路径，从而复用：

- `make_default_config.m`（公共参数）
- `build_receiver_array.m`（圆环阵列）
- `build_metric_scenarios.m`（三类实验场景）
- `plot_single_path_results.m` / `plot_metric_comparison.m`（绘图）
- `get_rate_threshold.m`

`ExactPaperModel` 内部只保留必须自包含的辅助函数，避免修改原文件。

## 注意事项

1. **计算量**：精确空间相关性需要对高度做数值积分，且含合流超几何函数，比指数模型慢很多。`run_metric_comparison_exact` 会比较耗时。
2. **数值稳定性**：`zeta_exact` 在 α 接近 3 或 4、或孔径间距极小时可能出现溢出，已加入 `exp(700)` 上限保护。
3. **适用范围**：本模型严格对应论文的**弱湍流 + 对数正态**假设。若需研究中强湍流，请使用 `EGC_MRC_Analysis` 的 Gamma-Gamma 模型。
4. **BER 积分**：高斯-埃尔米特 BER 目前仅对 **OOK-EGC** 实现，因为论文只给出了该路径的闭式；MRC/PPM 仍用 Monte Carlo。

## 关于 SNR/光子数映射

论文公式 (20) 中的 $\bar{\xi}_0$ 是**单路平均信噪比**。为与 `EGC_MRC_Analysis` 中 `lambda_signal`（每接收机平均信号光子数）保持一致，本实现直接取

```text
xi0 = lambda_signal
```

这对应于 `simulate_ook_egc.m` 中的等效 SNR 定义 `gamma = lambda_signal/M * (sum h_m)^2`。在弱湍流（$\sigma_I^2 \ll 1$）下，$E[h_m^2] \approx 1$，该映射与论文近似等价；若需要严格的光电转换 SNR，可在 `ber_ook_egc_gauss_hermite.m` 中加入响应度、孔径面积等参数做线性缩放。
