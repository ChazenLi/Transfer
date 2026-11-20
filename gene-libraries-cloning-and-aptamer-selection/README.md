# 基因文库构建与目的分子发现：基因组与 cDNA 文库、基因克隆及 Aptamer 筛选

*Gene Libraries and Molecular Discovery: Genomic and cDNA Libraries, Gene Cloning, and Aptamer Selection*

这份案例从基因组和 cDNA 文库中的基因分离讲起，接着讨论已知基因怎样克隆，再比较 aptamer 的选择。重点是具体材料和实验结果会怎样影响下一步：为什么取这份样本，什么时候值得建库，筛不到以后先查哪里，拿到候选后怎样重新验证。

## 阅读入口

- [主案例：GitHub 直接阅读](gene-libraries-cloning-and-aptamer-selection.md)
- [主案例：独立 HTML](gene-libraries-cloning-and-aptamer-selection.html)，下载后用浏览器打开，可搜索、展开细节、使用计算工具和保存课题笔记。
- [课题笔记模板](RESEARCH-NOTEBOOK.md)
- [原始文献与核读范围](references.json) · [核查记录](VERIFICATION.md)

## 三部分怎样接起来

第一部分从未知基因出发，比较基因组文库与 cDNA 文库。CFTR 用位置线索追到候选区域和转录本；TRPV1 用细胞反应从表达库中找出受体。建库章节接着讨论取材、片段长度、克隆保存和阳性池拆分。

第二部分处理基因已经明确的情形：怎样选模板和转录本，怎样定构建体边界，以及何时用酶切连接、Gibson、Golden Gate 或 Gateway。RACE、融合标签和功能验证也在这里展开。

第三部分比较不同文库保存的候选，转入 SELEX、cell-SELEX 与 particle display。讨论目标状态、背景和反筛如何影响候选，以及富集后怎样单独合成复测。

## 怎样把它当作一个学习单元

初次阅读可从 CFTR 和 TRPV1 两个案例入手，跟着每一步看候选如何减少。准备自己的课题时，把样本、目标版本、宿主和测量条件填进笔记，再判断哪些选择可以沿用。

有结果以后，可查七种结果情境：目标区域缺失、cDNA 筛不到功能、阳性池拆开失效、正确序列没有功能，以及 aptamer 富集、背景结合和环境转换问题。Markdown 展开了全部情境，并保留计算示例；HTML 提供可调参数的版本。

适合持续补充的是“哪一条证据改变了我的选择”。以后读到新论文，可以把它接到相应步骤，记录它让取材、建库、筛选或验证的哪一项安排发生变化。

## 内容与使用

17 个章节、16 篇原始研究引用、25 项展开讨论。文献包括 Nature、Cell、Science，以及方法与专业期刊。多数条目核对到摘要；已核读的正文与方法范围逐篇列出。计算和结果情境用于研究设计练习。

HTML 是独立文件，正文和交互工具可离线使用；GitHub 文件页展示 HTML 源码，在线阅读请用上面的 Markdown 入口。笔记保存在自己的浏览器中，也可以导出。

文献检索与初稿：2026-11-20；Humanizer 全文润色与本目录整理：2026-11-21。
