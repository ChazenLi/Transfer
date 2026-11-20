# 细胞膜运输：膜融合、胞吞胞吐与受体介导胞吞

**Cell Membrane Trafficking: Membrane Fusion, Endocytosis, Exocytosis, and Receptor-Mediated Endocytosis**

一份以膜拓扑、分子机器和实验读出为主线的中文学习与分析资料。内容从膜融合、胞吐与胞吞推进到 AP2/网格蛋白、肌动蛋白、Dynamin、脱包被、内体成熟和受体分选，并比较 TfR1、LDLR 与 EGFR 的不同命运。

## 阅读入口

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
