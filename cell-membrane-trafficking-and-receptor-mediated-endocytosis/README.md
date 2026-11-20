# 受体介导胞吞与内体分选：科研知识框架与研究基座

**Receptor-Mediated Endocytosis and Endosomal Sorting: A Research Foundation · V2**

面向具有细胞生物学基础、希望进一步判断证据和选择实验的读者。以受体介导胞吞—内体分选为核心，将膜拓扑、局部力学、膜脂、化学环境、细胞器互作、营养与信号连接到可研究的问题；融合和胞吐作为必要背景。

## V2 阅读入口

- [科研基座正文（Markdown，GitHub 可直接阅读）](receptor-mediated-endocytosis-research-foundation-v2.md)
- [交互图文版（HTML）](receptor-mediated-endocytosis-research-foundation-v2.html)：下载本主题目录，保留 `figures/` 后以浏览器打开。GitHub 文件页显示源码。
- [V1 深度审计](V1-DEPTH-AUDIT.md) · [V2 核查与交付说明](V2-VERIFICATION.md)
- [32 份机制与案例文献及实际核查范围](research-sources-v2.json)
- [18 幅论文图的来源与许可](FIGURE-SOURCES-V2.md) · [结构化图源](figure-sources-v2.json)

案例从研究者面对的问题开始，沿着实验结果，讨论为什么选择某个体系和对照，以及换一种受体或条件后怎样调整方法。论文结果随作者和引用说明，实验取舍与可借鉴做法接在对应结果后展开。

## V2 的四个阅读层次

| 层次 | 主要问题 | 内容 |
|---|---|---|
| 机制正文 | 谁在膜哪一侧，以何种状态改变哪一步？ | AP2 激活、包被弯曲、actin、Dynamin、脱包被、系留/融合、Rab 转换、酸化、回收与 ILV |
| 环境与尺度地图 | 哪些条件改变过程，哪些条件改变我们看到的结果？ | 膜两侧、糖萼/ECM、皮层、局部张力、离子/pH、ER、代谢及采样条件 |
| 实验决策手册 | 常规设备能先区分什么，何时需要合作升级？ | 表面结合/内化、回收/再内化、降解、共定位、标记、遗传恢复和统计单位 |
| 论文案例推演 | 为什么这些研究动作能推进判断？ | AP2、起始校准、条件性 actin、EGFR 剂量、Retriever、ER 接触、内体信号，共 7 例 |

共 **18 章、18 幅论文图、32 份机制与案例文献**，涉及 Nature、Cell、Science 及相关专门期刊。各条文献记录提供实际核读范围和继续阅读的位置。

以共聚焦、流式、Western 和遗传扰动为起点，进一步讨论 TIRF、超分辨、电镜、结构、单粒子和力学合作能解决什么问题。具体协议可结合受体、细胞和处理条件，从原文方法继续选择。

HTML 提供全文搜索、目录跳转、深入说明与文献折叠、论文图放大、实验决策练习、手机布局及打印样式。通量模型分别改变入口、回收、分流、移除及探针亮度；曲线来自合成教学模型，未拟合实验数据。

HTML 与 Markdown 共用 `figures/`。新增 N01 为内源 Commander 的互作和纯化研究工作流，原论文从文献链接访问。

资料采用定向文献阅读，部分工作用于摘要定位，部分核读到指定结果和方法；范围逐篇记录。用于新课题时，可沿自己的问题补充检索。

## V1 背景导读与文件

V1 以膜拓扑、分子机器和实验读出为主线，包含更宽的膜融合、胞吐与胞吞背景。以下入口和内容说明对应 V1。

- [完整学习资料（Markdown，GitHub 可直接阅读）](cell-membrane-trafficking-and-receptor-mediated-endocytosis.md)
- [图文阅读版（HTML）](cell-membrane-trafficking-and-receptor-mediated-endocytosis.html)：下载本主题**完整目录**后用浏览器打开，支持目录搜索、补充说明折叠、论文图放大和打印。GitHub 文件页显示 HTML 源码。
- [17 幅论文图的来源与许可](FIGURE-SOURCES.md) · [结构化图源与读图记录](figure-sources.json)
- [验证记录](VERIFICATION.md)

## 学习主线

| 阶段 | 要回答的问题 | 阅读时关注什么 |
|---|---|---|
| 膜拓扑与融合 | 哪两个单层先接触？脂质混合是否等于内容物连通？ | 近端/远端单层、半融合、融合孔；区分模型与测量 |
| 胞吐与胞吞 | 膜形态、货物位置和膜朝向怎样改变？ | 双通道时间序列、pH 敏感读出、形态快照 |
| 受体介导胞吞 | 受体选择如何与膜脂、包被装配、力和裂变连接？ | FCHo2/PIP₂、AP2/网格蛋白、actin、Dynamin、脱包被 |
| 内体与运输 | 区室身份、酸化、运动和分选是否一定同步？ | Rab 转换、ILV 电镜、内体运动的干预实验 |
| 受体案例 | 为什么 TfR1、LDLR 和 EGFR 的内吞结局不同？ | 配体与受体分开追踪；回收、铁/脂质摄取与信号调控 |

每幅论文图都按“**观察对象和方法 → 面板读法 → 能支持什么 → 不能支持什么**”解读。建议先读主线，再回看方法章节，最后尝试独立解释一张原图。

## 内容与文件

资料包含 **17 幅真实论文图**（13 幅来自原始研究、4 幅综述机制模型），另保留 1 幅膜方向辅助图。实验形式包括电镜、AFM、TIRF、SIM、STORM、流式回收测定和活细胞粒子追踪。

```text
cell-membrane-trafficking-and-receptor-mediated-endocytosis/
├── README.md
├── cell-membrane-trafficking-and-receptor-mediated-endocytosis.md
├── cell-membrane-trafficking-and-receptor-mediated-endocytosis.html
├── figures/                  # 两种阅读入口共用的完整图像
├── FIGURE-SOURCES.md          # 作者、原图号、DOI、许可
├── figure-sources.json        # 图注、边界、下载 URL 与校验值
└── VERIFICATION.md
```

Markdown 与 HTML 共享本地图片，避免重复保存图片数据。只下载 HTML 文件不会同时下载 `figures/`；可以下载仓库 ZIP 后保留本主题目录，或直接克隆仓库阅读。

## 证据范围与许可

所选图版已核对来源、图注和许可，并区分综述模型、方法校准、静态结构与动态实验。正文保留细胞类型、重构体系和处理条件等限制；这是学习资料及证据解读，不是该领域的系统综述。

论文图按各自原许可提供，尤其 Kaplan 等的图采用 **CC BY-NC-SA 4.0**；详见 [图源说明](FIGURE-SOURCES.md)。本目录没有给第三方图像重新指定统一许可。

整理与图版核查日期：2026-11-20。
