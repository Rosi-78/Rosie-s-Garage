# 星地激光通信分集接收系统仿真项目

本项目围绕星地下行自由空间光通信（Free Space Optical, FSO）链路，复现并扩展了两篇核心文献：

1. **付玉龙等**：《非柯湍流对星地激光通信分集接收系统性能影响》—— 非柯尔莫哥洛夫湍流信道、空间相关性与 EGC 分集 BER 解析模型。
2. **信息速率文献**：《基于非完美光子计数通信系统的信息速率研究》—— 非完美光子计数、互信息、遍历容量与中断概率。

项目目标是把**发射调制 → 大气湍流衰落 → 空间相关性 → 光子计数噪声 → 分集合并 → 性能指标**串成可复现、可对比的仿真代码。

---

## 目录

1. [系统链路模型](#1-系统链路模型)
2. [信道建模与非柯湍流](#2-信道建模与非柯湍流)
3. [非完美光子计数模型](#3-非完美光子计数模型)
4. [分集接收：EGC 与 MRC](#4-分集接收egc-与-mrc)
5. [性能指标](#5-性能指标)
6. [代码结构](#6-代码结构)
7. [实验设计](#7-实验设计)
8. [运行方式](#8-运行方式)
9. [参考资料](#9-参考资料)

---

## 1. 系统链路模型

### 1.1 物理链路

```text
卫星激光发射端
    ↓
OOK / PPM 调制光脉冲
    ↓
自由空间传播（几何扩散、大气吸收与散射）
    ↓
非柯尔莫哥洛夫大气湍流 → 光强闪烁
    ↓
地面 M 个接收孔径（SIMO）
    ↓
非完美光子计数器 → 二项分布计数
    ↓
EGC / MRC 分集合并
    ↓
判决 / 译码 → BER、MI、Outage、Capacity
```

### 1.2 离散时间信号模型

第 $m$ 条接收支路在直接探测 IM/DD 下的输出电流：

$$
i_m(t)=R_d h_m(t)x(t)+v_m(t)
$$

其中：

- $R_d$：光电探测器响应度；
- $h_m(t)$：第 $m$ 条支路的信道衰落因子（归一化光强）；
- $x(t)$：OOK 调制信号，$x\in\{0,2P_t\}$，$P_t$ 为发射平均光功率；
- $v_m(t)$：零均值高斯白噪声，方差 $\sigma_{v,m}^2$。

EGC 合并总输出：

$$
i_{\text{EGC}}=\sum_{m=1}^{M}i_m
$$

瞬时信噪比：

$$
\xi_{\text{EGC}}=\frac{\bar\xi_0\left(\sum_{m=1}^{M}I_m\right)^2}{M}
$$

其中 $\bar\xi_0=2R_d^2A/\sigma_v^2$ 为单路平均信噪比，$A$ 为单路接收孔径面积，$I_m$ 为第 $m$ 路归一化接收光强。

---

## 2. 信道建模与非柯湍流

### 2.1 弱湍流：对数正态分布

弱大气湍流条件下，接收光强 $I_m$ 服从对数正态分布：

$$
f(I_m)=\frac{1}{I_m\sigma_{I_w}(\alpha)\sqrt{2\pi}}
\exp\left\{-
\frac{\left[\ln(I_m)+\frac{1}{2}\sigma_{I_m}^2(\alpha)\right]^2}
{2\sigma_{I_w}^2(\alpha)}
\right\}
$$

其中：

- $\sigma_{I_m}(\alpha)$：光强闪烁指数；
- $\alpha$：非柯湍流折射率功率谱幂律指数，$3<\alpha<4$。

### 2.2 HV 剖面：大气折射率结构常数

高度相关的 Hufnagel-Valley 模型：

$$
C_n^2(h)=0.00594\left(\frac{w}{27}\right)^2(10^{-5}h)^{10}e^{-h/1000}
+2.7\times10^{-16}e^{-h/1500}
+A_ce^{-h/100}
$$

典型取值：$w=21\ \text{m/s}$，$A_c=1.7\times10^{-14}\ \text{m}^{-2/3}$。

### 2.3 非柯湍流折射率功率谱

广义非柯尔莫哥洛夫功率谱：

$$
\Phi_n(\kappa,\alpha)=A(\alpha)\tilde C_n^2(h,\alpha)\kappa^{-\alpha},
\quad \frac{2\pi}{L_0}\ll\kappa\ll\frac{2\pi}{l_0}
$$

其中：

$$
A(\alpha)=\frac{\cos(\alpha\pi/2)\Gamma(\alpha-1)}{4\pi^2}
$$

非柯与传统柯氏结构常数的等价关系：

$$
\tilde C_n^2(h,\alpha)=-
\frac{\Gamma(\alpha)(k/L)^{\alpha/2-11/6}}
{8\pi^2\Gamma(1-\alpha/2)\Gamma^2(\alpha/2)\sin(\pi\alpha/4)A(\alpha)}
C_n^2(h)
$$

### 2.4 光强协方差与空间相关系数

#### 2.4.1 定义

任意两个接收孔径 $i,j$ 的信道相关系数：

$$
\gamma_{ij}(\rho_{ij},\alpha)=
\frac{\zeta_{ij}(\rho_{ij},\alpha)}
{\sqrt{\sigma_{ii}^2(\alpha)\sigma_{jj}^2(\alpha)}}
$$

星地下行链路可近似为平面波，各路闪烁指数相等：

$$
\sigma_{ii}^2(\alpha)=\sigma_{jj}^2(\alpha)=\sigma_I^2(\alpha)=\zeta_{ij}(0,\alpha)
$$

因此：

$$
\gamma_{ij}(\rho_{ij},\alpha)=\frac{\zeta_{ij}(\rho_{ij},\alpha)}{\zeta_{ij}(0,\alpha)}
$$

#### 2.4.2 光强协方差积分

$$
\zeta_{ij}(\rho_{ij},\alpha)=
\exp\Bigg\{
8\pi^2k^2\sec(\theta)
\int_{h_0}^{H}\int_0^\infty
\kappa\Phi_n(\kappa,\alpha)J_0(\kappa\rho_{ij})
\exp\left(-\frac{\kappa^2D^2}{16}\right)
\left[1-\cos\left(\frac{L\kappa^2\xi}{k}\right)\right]
d\kappa dh
\Bigg\}-1
$$

其中：

- $k=2\pi/\lambda$：光波数；
- $\theta$：天顶角；
- $h_0$：接收端地面高度；
- $H$：卫星轨道高度；
- $J_0(\cdot)$：零阶第一类贝塞尔函数；
- $D$：接收孔径直径；
- $L=(H-h_0)\sec(\theta)$：链路总传输距离；
- $\xi=1-z/L$：归一化距离变量。

#### 2.4.3 化简后的闭式

引入中间变量 $\vartheta_1,\vartheta_2$：

$$
\zeta_{ij}(\rho_{ij},\alpha)=\exp(\vartheta_1+\vartheta_2)-1
$$

**第一分量**（对应积分中的 `"1"` 项）：

$$
\vartheta_1=4\pi^2k^2A(\alpha)\sec(\theta)\Gamma\left(1-\frac{\alpha}{2}\right)
\left(\frac{D^2}{16}\right)^{\frac{\alpha}{2}-1}
{}_1F_1\left(1-\frac{\alpha}{2};1;-\frac{4\rho_{ij}^2}{D^2}\right)
\int_{h_0}^{H}\tilde C_n^2(h,\alpha)dh
$$

**第二分量**（对应积分中的 `"-\cos"` 项）：

$$
\vartheta_2=-4\pi^2k^2A(\alpha)\sec(\theta)\Gamma\left(1-\frac{\alpha}{2}\right)
\mathrm{Re}\Bigg\{
\int_{h_0}^{H}\tilde C_n^2(h,\alpha)
\left(
\frac{D^2}{16}+
\frac{i(h-h_0)\sec(\theta)}{k}
\right)^{\frac{\alpha}{2}-1}
{}_1F_1\left(
1-\frac{\alpha}{2};1;
-\frac{4\rho_{ij}^2k}{kD^2+i16(h-h_0)\sec(\theta)}
\right)dh
\Bigg\}
$$

> **注意**：付玉龙论文公式 (13) 原文印刷为 $-4\rho_{ij}/D^2$，量纲不一致，且与图 2 衰减趋势不符。本项目已修正为 $-4\rho_{ij}^2/D^2$。

---

## 3. 非完美光子计数模型

### 3.1 理想泊松计数

理想单光子计数器输出 $Y$ 服从泊松分布：

$$
P(Y=y|\lambda)=\frac{\lambda^y}{y!}e^{-\lambda},
\quad y=0,1,2,\dots
$$

其中 $\lambda=\lambda_sI+\lambda_b$ 为平均总光子数，$\lambda_s$ 为信号光子数，$\lambda_b$ 为背景光子数。

### 3.2 非完美计数：二项分布

实际计数器存在死区时间，资料中用二项分布刻画：

$$
P(Y=y|\lambda)=\binom{D_c}{y}
\left(1-e^{-\lambda/D_c}\right)^y
\left(e^{-\lambda/D_c}\right)^{D_c-y}
$$

其中 $D_c$ 为一个符号周期内最大可识别计数。等价地，可看成 $D_c$ 个独立时间桶，每个桶触发概率：

$$
p_\lambda=1-e^{-\lambda/D_c}
$$

因此：

$$
Y|\lambda\sim\mathrm{Binomial}(D_c,p_\lambda)
$$

两个极限行为：

- $\lambda\ll D_c$ 时，二项分布趋近泊松分布；
- $\lambda\gg D_c$ 时，$Y\to D_c$，计数器饱和。

---

## 4. 分集接收：EGC 与 MRC

### 4.1 EGC 等增益合并

$M$ 路计数直接等权相加：

$$
S_{\text{EGC}}=\sum_{m=1}^{M}N_m
$$

等效 SNR：

$$
\gamma_{\text{EGC}}=\frac{\bar\xi_0}{M}\left(\sum_{m=1}^{M}I_m\right)^2
$$

### 4.2 MRC 最大比合并

为每路分配与信道质量相关的权重。在光子计数二项模型中，第 $m$ 支路权重：

$$
w_m\propto\frac{E[N_m|H_1]-E[N_m|H_0]}{\mathrm{Var}_{\mathrm{avg}}[N_m]}
$$

其中 $E[N|H_0]=D_cp_0$，$E[N|H_1]=D_cp_{1,m}$，$\mathrm{Var}[N]=D_cp(1-p)$。合并统计量：

$$
S_{\text{MRC}}=\sum_{m=1}^{M}w_mN_m
$$

等效 SNR：

$$
\gamma_{\text{MRC}}=\bar\xi_0\sum_{m=1}^{M}I_m^2
$$

由 Cauchy-Schwarz 不等式，恒有 $\gamma_{\text{EGC}}\le\gamma_{\text{MRC}}$。

---

## 5. 性能指标

### 5.1 误码率 BER

OOK-EGC 条件 BER（瞬时光强已知）：

$$
P_e^{\text{EGC}}(S_{\text{EGC}})=Q\left(\sqrt{\frac{\bar\xi_0}{2M}}S_{\text{EGC}}\right)
$$

平均 BER 对 $S_{\text{EGC}}$ 分布求平均。若 $S_{\text{EGC}}$ 近似对数正态，可用高斯-埃尔米特数值积分：

$$
\bar P_e^{\text{EGC}}=
\frac{1}{\sqrt{\pi}}\sum_{k=1}^{K}w_k
Q\left\{
\sqrt{\frac{\bar\xi_0}{2M}}
\exp\left[
\sqrt{2}\sigma_{S_{\text{EGC}}}x_k-
\frac{\sigma_{S_{\text{EGC}}}^2}{2}
\right]
\right\}
$$

其中合成光强等效方差：

$$
\sigma_{S_{\text{EGC}}}^2=\sigma_I^2\left(
\frac{1}{M}+
\frac{1}{M^2}\sum_{i\ne j}\gamma_{ij}
\right)
$$

### 5.2 互信息 MI

对 OOK：

$$
I(X;Y)=\sum_{x\in\{0,1\}}p(x)\sum_y p(y|x)
\log_2\frac{p(y|x)}{\sum_{x'}p(x')p(y|x')}
$$

本项目通过直方图估计 $p(y|x)$ 与后验概率，进而计算 count-domain MI。

### 5.3 中断概率与遍历容量

等效 SNR 容量：

$$
C(\gamma)=\log_2(1+\gamma)
$$

中断概率：

$$
P_{\text{out}}(R_0)=P\{C(\gamma)<R_0\}
$$

遍历容量：

$$
C_{\text{erg}}=E_\gamma[\log_2(1+\gamma)]
$$

---

## 6. 代码结构

```text
Planet2EarthCommunicationSystemPJ/
├── README.md                          # 本文件
├── Principal.md                       # 更详细的理论推导与调研
├── main.tex / main.pdf                # LaTeX 论文/报告
├── EGC_MRC_Analysis/                  # MATLAB：工程近似模型（Gamma-Gamma + Copula）
├── ExactPaperModel/                   # MATLAB：论文精确模型（非柯积分 + 对数正态 + GH 积分）
├── Re_CorrelatedChannel_SIMO_Model/   # Python：论文公式复现与 SIMO 实验
├── CorrelatedChannelsAnalysis/        # MATLAB：早期 Week2/3 完整仿真工程
├── CorrelationStressTest/             # MATLAB：相关性压力测试
└── chapter3_work/                     # Python：第三章仿真与 LaTeX 报告
```

### 6.1 `EGC_MRC_Analysis/` — 工程近似模型

| 文件 | 说明 |
|------|------|
| `make_default_config.m` | 默认参数配置 |
| `build_receiver_array.m` | 地面圆环接收机阵列几何 |
| `hv_cn2_profile.m` | HV 剖面 $C_n^2(h)$ |
| `derive_turbulence_parameters.m` | Rytov → Gamma-Gamma 参数映射 |
| `build_physical_correlation_matrix.m` | 指数衰减相关矩阵 |
| `generate_correlated_gg.m` | Gaussian Copula 生成相关 Gamma-Gamma 光强 |
| `simulate_ook_egc.m` / `simulate_ook_mrc.m` | OOK + EGC/MRC 仿真 |
| `simulate_ppm_egc.m` / `simulate_ppm_mrc.m` | PPM + EGC/MRC 仿真 |
| `run_metric_comparison_analysis.m` | 三类对比实验主入口 |
| `plot_metric_comparison.m` | 对比图绘制 |

核心链路：

```text
Cn2(h) → Rytov 闪烁 → Gamma-Gamma(α_gg, β_gg)
       → 指数相关矩阵 R
       → Gaussian Copula → 相关 Gamma-Gamma 光强 h
       → 二项光子计数 N
       → EGC/MRC 合并 → MI / BER / Outage
```

### 6.2 `ExactPaperModel/` — 论文精确模型

| 文件 | 说明 |
|------|------|
| `A_alpha.m` | 非柯功率谱系数 $A(\alpha)$ |
| `Cn2_tilde.m` | 等效结构常数 $\tilde C_n^2(h,\alpha)$ |
| `calc_vartheta1.m` / `calc_vartheta2.m` | 协方差积分分量 |
| `zeta_exact.m` | 光强协方差 |
| `gamma_coeff_exact.m` | 空间相关系数 |
| `derive_turbulence_parameters_exact.m` | 由 $\zeta(0)$ 计算精确闪烁指数 |
| `build_correlation_matrix_exact.m` | 精确相关矩阵 |
| `generate_correlated_lognormal.m` | 相关对数正态光强 |
| `ber_ook_egc_gauss_hermite.m` | 高斯-埃尔米特 BER 积分 |
| `simulate_*_exact.m` | OOK/PPM + EGC/MRC 仿真 |
| `make_exact_config.m` | 精确模型专用配置 |
| `build_metric_scenarios_exact.m` | 精确模型对比场景 |
| `run_metric_comparison_exact.m` | 精确模型主入口 |
| `plot_*_dB.m` | dB 纵坐标 outage/BER 图 |

核心链路：

```text
Cn2(h) → 非柯等效常数 → 功率谱积分 → ζ(ρ,α) → γ(ρ,α)
       → 相关对数正态光强 h
       → 二项光子计数 N
       → EGC/MRC 合并
       → OOK-EGC: Gauss-Hermite BER; 其它: Monte Carlo
```

### 6.3 `Re_CorrelatedChannel_SIMO_Model/` — Python 参考实现

| 文件 | 说明 |
|------|------|
| `config.py` | 配置类 |
| `turbulence.py` | 非柯湍流、功率谱、相关系数 |
| `correlation.py` | 相关矩阵与对数正态信道生成 |
| `diversity.py` | EGC/MRC 合并器 |
| `modulation.py` | OOK/PPM 调制 |
| `channel.py` | 完整信道模型 |
| `experiments.py` | 三个实验 |
| `main.py` | 主入口 |

### 6.4 其它文件夹

- `CorrelatedChannelsAnalysis/`：早期完整 MATLAB 工程，含 OOK/PPM、联合似然、互信息等。
- `CorrelationStressTest/`：直接设置 Gaussian Copula 相关系数 $\rho=0/0.3/0.6/0.9$，验证“相关性机制本身是否造成分集损失”。
- `chapter3_work/`：第三章工作，含独立 Python 仿真与 LaTeX 报告。

---

## 7. 实验设计

### 7.1 三类对比实验

`EGC_MRC_Analysis` 和 `ExactPaperModel` 都实现了相同的三类对比：

1. **湍流强度（Turbulence）**
   - 固定接收机间距和数量
   - 改变 `turbulence_strength_scale`：weak / medium / strong
   - 对比不同闪烁强度下的 MI、BER、Outage

2. **空间相关性（Correlation）**
   - 固定接收机数量
   - 改变圆环半径（即改变相邻接收机间距）：compact / default / spread
   - 对比不同相关性下的性能

3. **接收机数量（ReceiverNumber）**
   - 固定湍流和相关性
   - 改变分集路数 $M$：2 / 3 / 6（或 2 / 8 / 18）
   - 对比分集增益

### 7.2 四条仿真路径

每个场景都跑四条路径：

- OOK-EGC
- OOK-MRC
- PPM-EGC
- PPM-MRC

### 7.3 精确模型与近似模型的对比口径

| 维度 | `EGC_MRC_Analysis` | `ExactPaperModel` |
|------|-------------------|-------------------|
| 光强分布 | Gamma-Gamma | 对数正态（弱湍流） |
| 空间相关性 | 指数衰减近似 $\exp[-(\rho/\rho_c)^p]$ | 非柯功率谱积分 |
| 相关信道生成 | Gaussian Copula | Cholesky 直接相关高斯 |
| OOK-EGC BER | 等效 SNR Monte Carlo | Gauss-Hermite 数值积分 |
| 适用场景 | 弱/中/强湍流通用 | 严格复现付玉龙论文 |

---

## 8. 运行方式

### 8.1 工程近似模型

```matlab
cd EGC_MRC_Analysis
run_metric_comparison_analysis      % 完整三类对比
run_ook_egc_analysis                % 单条路径
```

### 8.2 论文精确模型

```matlab
cd ExactPaperModel
test_exact_model_smoke              % 冒烟测试
run_ook_egc_analysis_exact          % 单条路径
run_metric_comparison_exact         % 完整三类对比（已按精确模型调参）
```

### 8.3 Python 参考实现

```bash
cd Re_CorrelatedChannel_SIMO_Model
python main.py --mode experiments --num_samples 1000
```

---

## 9. 参考资料

1. 付玉龙等：《非柯湍流对星地激光通信分集接收系统性能影响》
2. 《基于非完美光子计数通信系统的信息速率研究》
3. `Principal.md`：项目内更完整的理论推导与调研笔记
4. `EGC_MRC_Analysis/README.md`：工程近似模型详细说明
5. `ExactPaperModel/README.md`：精确模型详细说明
6. `Re_CorrelatedChannel_SIMO_Model/README.md`：Python 实现说明
