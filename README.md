# Circos Studio

交互式生物信息学环形关系可视化系统（第38题）

## 运行环境
- R（建议使用已安装的 R 4.6.1）
- RStudio
- 浏览器

## 安装依赖
在 RStudio Console 中执行：

```r
install.packages(c("shiny", "circlize", "readxl", "DT", "svglite"))
```

## 启动
1. 解压项目文件夹。
2. 使用 RStudio 打开 `app.R`。
3. 点击右上角 `Run App`，或在 Console 执行 `shiny::runApp()`。
4. 浏览器将打开本地交互页面。

## 输入数据格式
支持 CSV、XLSX、XLS。文件必须包含三列（大小写不限）：
- `Source`：来源节点
- `Target`：目标节点
- `Value`：连接权重，必须为大于 0 的数值

重复的 Source-Target 组合会自动合并并对 Value 求和。缺失、非数值、无穷或非正权重记录会被剔除。

## 示例数据
- `data/sample_species.csv`
- `data/gene_pathway.csv`

## 当前版本功能
- CSV / Excel 数据导入
- 样本–物种与基因–通路两类关系数据
- 数据格式校验、无效记录过滤、重复关系聚合
- 权重阈值筛选
- 节点选择与关联连接高亮
- 配色、透明度、标签和标题控制
- 关系明细表
- SVG 与 300 dpi PNG 导出

## 重要说明
当前版本是可运行的第一阶段基础版。图形布局由 `circlize::chordDiagram()` 计算和绘制；后续开发应继续增加更细粒度的节点/分组筛选、交互式图中节点点击、异常数据提示、自动化测试和性能测试。请勿在未测试前将其描述为已完成全部验收。
