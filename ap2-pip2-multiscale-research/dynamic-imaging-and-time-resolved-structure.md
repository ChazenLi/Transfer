# 从显微视频到构象快照：怎样研究 AP2–PIP₂ 的动态过程

“多张图像组合成视频”这个理解是对的。做实验时，再往前问一步：这些图像拍的是同一个对象连续发生的变化，还是不同时间、不同对象的快照？知道每一帧怎样获得，才知道视频适合回答什么。

这份笔记接在 [AP2–PIP₂ 主案例](ap2-pip2-multiscale-research-case-study.md) 后面，集中讨论时间信息怎样进入分子互作研究。

## 连续拍摄：看一次事件怎样发生

活细胞时间序列成像会反复记录同一区域。把图像按时间播放，就能看见 AP2 斑点出现、增长或消失；做双通道，还能比较 FCHO、AP2 和 clathrin 等组分出现的时间关系。

Zaccai 等在 2022 年的 AP2/FCHO 研究里使用了活细胞 eTIRF-SIM，并提供补充视频。论文比较了 FCHO、AP2 与 clathrin 的时间和空间组织，讨论早期 FCHO 区域怎样随小窝形成而重排。准备自己的实验时，可以先跟着一个问题拍：突变影响的是到达、早期稳定，还是后来的组装？[1]

这里还有一种不同意义的“多张合成”。该研究的方法写到，每个时间点、每个波长采集九张原始图，包含三个照明角度和三个相位，再重构成一张超分辨图像。因此，SIM 的一次时间点本身就包含多次曝光。采样速度要结合这套采集流程计算，直接数播放文件的帧数容易误解。[1]

## 想看分子形貌变化，可以考虑高速 AFM

高速原子力显微镜 HS-AFM 在液体中连续扫描样品表面，给出随时间变化的形貌。Kodera 等在 2010 年的 Nature 论文中，直接记录了 myosin V 沿 actin 行走。这是“连续图像展示单分子行为”的具体先例，原论文页面提供补充视频。[2]

放到 AP2–膜体系，HS-AFM 值得考虑的问题包括膜上结构的高度、局部组织和形貌变化。是否能进一步区分某个 AP2 构象，要看所选膜支持、蛋白取向、扫描速度与分辨能力。先在样品上建立一种能稳定识别的形貌，再问它怎样随输入改变，会比直接给每种外观命名更踏实。

## 电镜里的时间信息：有连续观察，也有分时冻结

### 时间分辨冷冻电镜

这类实验先启动反应，在不同延迟时间分别快速玻璃化，再分析各时间点的结构群体。它适合追踪短寿命状态和构象分布如何随时间改变。

Torino 等在 2023 年 Nature Methods 的工作，将液滴微流控混合与按需喷射结合，报告了毫秒尺度制样，并以 GroEL/GroES 体系研究组装过程。[3] 这里的“时间电影”由各时间点的样品重建而来：同一分子不会在一次冻结后继续运动。

对 AP2 来说，只有在问题已经具体到“加入膜、货物或伙伴后，早期结构群体怎样变化”，且反应触发、样品和时间窗口都能建立时，这条路线才值得投入。膜招募和驻留问题，通常可先用荧光时间序列摸清范围。

### 液相透射电镜

液相 TEM 用电子透明、真空密封的小室保留液体，从而连续记录其中的样品。Smith 等在 2024 年 Science Advances 的研究，将液相电镜与模型结合，分析了含膜蛋白纳米盘的纳米尺度形变。[4]

这一方向很吸引人，实际选择时要把电子剂量、样品封装、形貌保持和生物活性一起评估。该论文也讨论了束损伤和功能基团保存的问题。对 AP2–PIP₂，可以先把它作为特定纳米尺度问题的合作路线，依据预实验判断是否适合目标样品。

### 普通 cryo-EM 采集文件也常叫 movie

冷冻电镜探测器会把一次曝光记录为多帧，随后做帧对齐和运动校正。Zaccai 的方法中也有这一处理步骤。[1] 此时样品已经玻璃化，帧间位移用于改善图像质量。它与活细胞里连续追踪一次内吞事件，所记录的过程不同。

另一种常见的结构动画，是在 closed 与 open 结构之间做几何插值。Jackson 2010 的补充材料包含这类 AP2 模型动画。[5] 它方便理解位移与旋转；想测真实转换次序和速率，则还要加入时间分辨实验。

## 回到 AP2：先拍什么，怎样从视频里得到结果

| 手里的问题 | 可以从哪里开始 | 视频或结构序列里提取什么 |
|---|---|---|
| AP2 为什么在膜上变少？ | 定义膜上的时间序列，或活细胞 TIRF | 到达率、事件密度、驻留分布及短事件比例 |
| FCHO 与 AP2 怎样衔接？ | 双通道时间序列；空间上分不开时再用 SIM | 到达时间差、共同停留、空间重排 |
| AP2 留得更久，是否更容易招募 clathrin？ | AP2/clathrin 双通道重构 | clathrin 到达等待时间、每单位膜上 AP2 的招募表现 |
| 膜上的形貌或组织怎样改变？ | AFM/HS-AFM，配合膜上荧光 | 高度、局部组织、扩散与形态随时间的变化 |
| 很早的构象中间态是什么？ | 已建立触发条件后的时间分辨结构路线 | 各时间点的结构类别和群体变化 |

视频播放速度和实验采样间隔分开记录。举一个纯教学例子：每两秒采一张图，按每秒二十帧播放，画面就以四十倍速度展示过程。分析时仍使用每张图的实际采集时间。

同时留下曝光、通道切换、SIM 重构窗口、照明强度和追踪规则。斑点消失时，把解离、漂白和出焦放在一起检查；拍摄结束仍存在的事件，按右删失处理。这样，视频才能进一步变成可以比较的到达、驻留和组装数据。

## 文献与视频入口

1. Zaccai et al. (2022). *FCHO controls AP2’s initiating role in endocytosis through a PtdIns(4,5)P₂-dependent switch*. Science Advances. [原文与补充材料入口](https://pmc.ncbi.nlm.nih.gov/articles/PMC9054013/) · [DOI](https://doi.org/10.1126/sciadv.abn2018)。本笔记核对了相关正文及 eTIRF-SIM、帧处理方法。
2. Kodera et al. (2010). *Video imaging of walking myosin V by high-speed atomic force microscopy*. Nature. [论文与补充视频入口](https://www.nature.com/articles/nature09450) · [DOI](https://doi.org/10.1038/nature09450)。使用公开摘要及补充视频说明作方法实例。
3. Torino et al. (2023). *Time-resolved cryo-EM using a combination of droplet microfluidics with on-demand jetting*. Nature Methods 20, 1400–1408. [论文](https://www.nature.com/articles/s41592-023-01967-z) · [DOI](https://doi.org/10.1038/s41592-023-01967-z)。使用公开摘要、图注与数据说明。
4. Smith et al. (2024). *Electron videography of a lipid–protein tango*. Science Advances 10, eadk0217. [原文](https://pmc.ncbi.nlm.nih.gov/articles/PMC11023515/) · [DOI](https://doi.org/10.1126/sciadv.adk0217)。核对摘要及介绍中的成像、封装和束损伤讨论。
5. Jackson et al. (2010). *A large-scale conformational change couples membrane recruitment to cargo binding in the AP2 clathrin adaptor complex*. Cell. [原文与模型动画说明](https://pmc.ncbi.nlm.nih.gov/articles/PMC3655264/) · [DOI](https://doi.org/10.1016/j.cell.2010.05.006)。结构动画用于解释几何差异。

论文视频从各自出版页面访问。笔记中的实验路线是学习讨论，具体参数继续对照目标样品与原文方法。整理日期：2026-11-20。
