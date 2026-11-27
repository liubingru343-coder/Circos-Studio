# Circos Studio

### 交互式生物信息学环形关系可视化系统

**Circos Studio** 是一个基于 R Shiny 和 circlize 开发的交互式生物信息学可视化平台，支持样本—物种关系和基因—通路关系的环形弦图展示。

用户可以通过浏览器访问系统，导入自己的数据，调整图形参数，并导出高质量可视化图形。

## 1. 在线体验

**在线访问：**

https://01a21bda-8287-38ec-f6c2-4e0ff2e730bf.share.connect.posit.cloud/

无需安装 R 或 RStudio，即可通过浏览器使用在线版本。

## 2. 核心功能

- **双模式可视化**：支持样本—物种、基因—通路两种关系模式。
- **数据导入**：支持 CSV、XLSX 和 XLS 格式。
- **关系筛选**：根据最小连接权重筛选关系。
- **节点选择**：支持指定节点突出显示。
- **交互联动**：选择关系明细表中的记录，突出显示对应关系。
- **图形参数调整**：支持配色方案、连线透明度、节点标签和图表标题设置。
- **统计分析**：动态展示有效关系数、节点总数和权重总和。
- **图形导出**：支持 SVG 和 PNG 格式。

## 3. 技术架构

| 技术 | 主要用途 |
|---|---|
| R | 数据处理与业务逻辑 |
| Shiny | Web 交互界面 |
| circlize | 环形弦图绘制 |
| readxl | Excel 数据读取 |
| DT | 交互式数据表 |
| svglite | SVG 图形导出 |

## 4. 输入数据格式

系统要求输入文件包含以下三列：

| 字段 | 含义 | 数据类型 |
|---|---|---|
| Source | 来源节点 | 文本 |
| Target | 目标节点 | 文本 |
| Value | 连接权重 | 数值 |

示例：

```csv
Source,Target,Value
Sample_A,Species_1,100
Sample_A,Species_2,80
Sample_B,Species_1,60
```

重复的 Source-Target 组合会进行合并，缺失或无效记录不参与有效关系计算。

## 5. 本地运行

### 环境要求

- R 4.6.1 或兼容版本
- RStudio（用于本地开发和运行）

### 安装依赖

```r
install.packages(c(
  "shiny",
  "circlize",
  "readxl",
  "DT",
  "svglite"
))
```

### 启动系统

在项目根目录运行：

```r
shiny::runApp()
```

随后通过浏览器访问 Shiny 提供的本地地址。

## 6. 项目目录

```text
Circos-Studio/
├── app.R
├── manifest.json
├── README.md
├── sample_species.csv
├── gene_pathway.csv
└── docs/
    ├── Circos-Studio-V0.2-设计与测试记录.md
    └── 项目设计与实现说明书.docx
```

## 7. 项目版本

当前版本：V0.2

开发方向：交互式生物信息学关系可视化。

## 8. 项目说明

本项目用于生物信息学关系数据的交互式可视化分析与展示，旨在降低环形关系图的使用门槛，提高数据探索和图形输出效率。

源代码公开托管于 GitHub，欢迎学习、交流与改进。
