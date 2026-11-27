# Circos Studio
# Interactive Circos chord-diagram application
# Run in RStudio with: shiny::runApp()

required_packages <- c("shiny", "circlize", "readxl", "DT", "svglite")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) {
  stop(
    "缺少 R 包：", paste(missing_packages, collapse = ", "),
    "\n请在 RStudio Console 运行：install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    "))"
  )
}

library(shiny)
library(circlize)
library(readxl)
library(DT)

# ---------- 示例数据 ----------
sample_data <- function() {
  data.frame(
    Source = c("Sample_A","Sample_A","Sample_A","Sample_B","Sample_B",
               "Sample_B","Sample_C","Sample_C","Sample_C","Sample_D",
               "Sample_D","Sample_D","Sample_E","Sample_E","Sample_E"),
    Target = c("Species_1","Species_2","Species_3","Species_1","Species_3",
               "Species_4","Species_2","Species_3","Species_5","Species_1",
               "Species_4","Species_5","Species_2","Species_4","Species_5"),
    Value = c(120,85,35,65,150,42,95,72,110,88,60,125,55,105,90),
    stringsAsFactors = FALSE
  )
}

# ---------- 基因—通路内置示例数据 ----------
gene_data <- function() {
  data.frame(
    Source = c("Gene_B","Gene_E","Gene_D","Gene_A","Gene_C","Gene_E","Gene_A","Gene_B","Gene_C","Gene_D"),
    Target = c("Pathway_1","Pathway_4","Pathway_4","Pathway_1","Pathway_2","Pathway_3","Pathway_2","Pathway_3","Pathway_4","Pathway_2"),
    Value = c(15,14,13,12,11,10,9,8,7,6),
    stringsAsFactors = FALSE
  )
}
# ---------- 输入数据标准化与验证 ----------
standardize_data <- function(x) {
  if (!is.data.frame(x) || nrow(x) == 0) {
    stop("数据为空，或文件中没有可读取的数据行。")
  }

  names(x) <- trimws(names(x))
  lower_names <- tolower(names(x))
  required <- c("source", "target", "value")
  idx <- match(required, lower_names)

  if (anyNA(idx)) {
    stop("数据必须包含三列：Source、Target、Value（列名大小写不限）。")
  }

  out <- data.frame(
    Source = trimws(as.character(x[[idx[1]]])),
    Target = trimws(as.character(x[[idx[2]]])),
    Value = suppressWarnings(as.numeric(as.character(x[[idx[3]]]))),
    stringsAsFactors = FALSE
  )

  valid <- !is.na(out$Source) & nzchar(out$Source) &
           !is.na(out$Target) & nzchar(out$Target) &
           !is.na(out$Value) & is.finite(out$Value) & out$Value > 0

  removed <- sum(!valid)
  out <- out[valid, , drop = FALSE]

  if (nrow(out) == 0) {
    stop("没有有效数据。请检查 Source、Target 和 Value；Value 必须是大于 0 的数值。")
  }

  # 合并重复的 Source-Target 组合，权重求和
  out <- aggregate(Value ~ Source + Target, data = out, FUN = sum)
  out <- out[order(out$Source, out$Target), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "removed_rows") <- removed
  out
}

read_uploaded_file <- function(path, name) {
  ext <- tolower(tools::file_ext(name))
  if (ext == "csv") {
    utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  } else if (ext %in% c("xlsx", "xls")) {
    as.data.frame(readxl::read_excel(path, sheet = 1, .name_repair = "minimal"))
  } else {
    stop("暂不支持该文件格式。请上传 CSV、XLSX 或 XLS 文件。")
  }
}

# ---------- 配色 ----------
make_palette <- function(n, palette_name) {
  if (n <= 0) return(character(0))
  palette_map <- c(
    "科研蓝" = "Blues",
    "海洋色" = "Teal",
    "柔和多彩" = "Set 2",
    "高对比" = "Dark 3"
  )
  hcl_name <- unname(palette_map[palette_name])
  if (is.na(hcl_name)) hcl_name <- "Dark 3"
  grDevices::hcl.colors(n, palette = hcl_name)
}

# ---------- 核心 Circos 绘图函数 ----------
draw_circos <- function(dat, selected_node = character(0),
                        palette_name = "科研蓝", show_labels = TRUE,
                        transparency = 0.35, title_text = "Circos 关系弦图") {
  circlize::circos.clear()
  on.exit(circlize::circos.clear(), add = TRUE)

  if (is.null(dat) || nrow(dat) == 0) {
    plot.new()
    text(0.5, 0.5, "当前筛选条件下没有可绘制的数据", cex = 1.2)
    return(invisible(NULL))
  }

  nodes <- sort(unique(c(dat$Source, dat$Target)))
  node_cols <- make_palette(length(nodes), palette_name)
  names(node_cols) <- nodes

  # 选中一个或多个节点时，突出相关连线并弱化其他连线。
  link_cols <- unname(node_cols[dat$Source])
  selected_nodes <- intersect(as.character(selected_node), nodes)
  if (length(selected_nodes) > 0) {
    related <- dat$Source %in% selected_nodes | dat$Target %in% selected_nodes
    link_cols[!related] <- grDevices::adjustcolor("#B8C0CC", alpha.f = 0.18)
    link_cols[related] <- grDevices::adjustcolor(link_cols[related], alpha.f = 0.95)
  }

  graphics::par(mar = c(2, 2, 5, 2), xpd = NA)
  circlize::circos.par(
    start.degree = 90,
    gap.after = rep(3, length(nodes)),
    track.margin = c(0.01, 0.01),
    cell.padding = c(0, 0, 0, 0),
    points.overflow.warning = FALSE
  )

  circlize::chordDiagram(
    x = dat[, c("Source", "Target", "Value")],
    order = nodes,
    grid.col = node_cols,
    col = link_cols,
    transparency = transparency,
    directional = 0,
    annotationTrack = if (show_labels) c("name", "grid") else "grid",
    preAllocateTracks = if (show_labels) 1 else 0,
    link.sort = TRUE,
    link.decreasing = FALSE,
    scale = FALSE
  )

  graphics::title(main = title_text, cex.main = 1.35, font.main = 2, line = 2)
}

# ---------- UI ----------
ui <- fluidPage(
  tags$head(
    tags$title("Circos Studio"),
    tags$style(HTML("
      body { background:#f4f7fb; color:#243247; }
      .main-header { padding:18px 22px; margin-bottom:16px; background:#12345a;
        color:white; border-radius:10px; }
      .main-header h2 { margin:0 0 5px 0; font-weight:700; }
      .main-header p { margin:0; color:#d8e6f5; }
      .well { background:white; border:1px solid #e1e8f0; border-radius:10px; }
      .panel-card { background:white; padding:15px; border:1px solid #e1e8f0;
        border-radius:10px; margin-bottom:14px; }
      .stat { font-size:22px; font-weight:700; color:#1763a6; }
      .muted { color:#68788d; font-size:12px; }
      .btn-primary { background:#1763a6; border-color:#1763a6; }
      .control-label { font-weight:600; }
    "))
  ),
  div(class = "main-header",
      h2("Circos Studio"),
      p("交互式生物信息学环形关系可视化系统 · 样本–物种 / 基因–通路")
  ),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      h4("① 数据导入"),
      fileInput("file", "上传 CSV / Excel 文件",
                accept = c(".csv", ".xlsx", ".xls")),
      helpText("数据必须包含 Source、Target、Value 三列。未上传文件时使用内置示例数据。"),
      radioButtons("mode", "关系模式",
                   choices = c("样本–物种" = "sample",
                               "基因–通路" = "gene"),
                   selected = "sample"),
      hr(),
      h4("② 图形设置"),
      selectInput("selected_node", "突出显示节点",
                  choices = c("全部节点")),
      sliderInput("threshold", "最小连接权重",
                  min = 0, max = 100, value = 0, step = 1),
      selectInput("palette", "配色方案",
                  choices = c("科研蓝", "海洋色", "柔和多彩", "高对比"),
                  selected = "科研蓝"),
      sliderInput("transparency", "连线透明度",
                  min = 0, max = 0.9, value = 0.35, step = 0.05),
      checkboxInput("show_labels", "显示节点标签", TRUE),
      textInput("chart_title", "图表标题", "Circos 关系弦图"),
      actionButton("reset", "恢复默认设置", class = "btn-default"),
      hr(),
      h4("③ 图形导出"),
      downloadButton("download_svg", "导出 SVG"),
      br(), br(),
      downloadButton("download_png", "导出 PNG")
    ),
    mainPanel(
      width = 9,
      fluidRow(
        column(4, div(class="panel-card",
                      div(class="muted", "有效关系数"),
                      textOutput("n_links", inline=TRUE))),
        column(4, div(class="panel-card",
                      div(class="muted", "节点总数"),
                      textOutput("n_nodes", inline=TRUE))),
        column(4, div(class="panel-card",
                      div(class="muted", "权重总和"),
                      textOutput("total_value", inline=TRUE)))
      ),
      div(class="panel-card",
          h4("关系弦图"),
          plotOutput("chord_plot", height = "720px",
                     width = "100%")),
      div(class="panel-card",
          h4("数据预览与关系明细"),
          DTOutput("data_table"),
          br(),
          uiOutput("selection_info")
      ),
      div(class="muted",
          "说明：本工具将 Source–Target–Value 长表转换为关系矩阵输入，按连接权重绘制环形弦图。")
    )
  )
)

# ---------- Server ----------
server <- function(input, output, session) {

  observeEvent(input$reset, {
    updateSelectInput(session, "palette", selected = "科研蓝")
    updateSliderInput(session, "threshold", value = 0)
    updateSliderInput(session, "transparency", value = 0.35)
    updateCheckboxInput(session, "show_labels", value = TRUE)
    updateSelectInput(session, "selected_node", selected = "全部节点")
    updateTextInput(session, "chart_title", value = "Circos 关系弦图")
  })

  # 上传数据优先；未上传时按模式切换对应内置示例数据。
  imported <- reactive({
    if (!is.null(input$file)) {
      read_uploaded_file(input$file$datapath, input$file$name)
    } else if (identical(input$mode, "gene")) {
      gene_data()
    } else {
      sample_data()
    }
  })
  cleaned <- reactive({
    standardize_data(imported())
  })

  observeEvent(cleaned(), {
    dat <- cleaned()
    nodes <- sort(unique(c(dat$Source, dat$Target)))
    choices <- c("全部节点", nodes)
    current <- isolate(input$selected_node)
    selected <- if (!is.null(current) && current %in% choices) current else "全部节点"
    updateSelectInput(session, "selected_node",
                      choices = choices, selected = selected)
    max_value <- max(dat$Value, na.rm = TRUE)
    updateSliderInput(session, "threshold",
                      min = 0, max = max(1, ceiling(max_value)),
                      value = min(isolate(input$threshold), max_value))
  }, ignoreInit = FALSE)

  filtered <- reactive({
    dat <- cleaned()
    dat <- dat[dat$Value >= input$threshold, , drop = FALSE]
    dat
  })

  output$n_links <- renderText({
    paste0(nrow(filtered()), " 条")
  })

  output$n_nodes <- renderText({
    dat <- filtered()
    paste0(length(unique(c(dat$Source, dat$Target))), " 个")
  })

  output$total_value <- renderText({
    paste0(format(sum(filtered()$Value), big.mark = ","), "")
  })

  sorted_data <- reactive({
    dat <- filtered()
    if (nrow(dat) == 0) return(dat)
    dat[order(-dat$Value), , drop = FALSE]
  })

  selected_nodes <- reactive({
    node <- input$selected_node
    if (!is.null(node) && !identical(node, "全部节点")) return(node)
    idx <- input$data_table_rows_selected
    dat <- sorted_data()
    if (length(idx) == 1 && idx >= 1 && idx <= nrow(dat)) {
      return(c(dat$Source[idx], dat$Target[idx]))
    }
    character(0)
  })

  output$chord_plot <- renderPlot({
    draw_circos(
      filtered(),
      selected_node = selected_nodes(),
      palette_name = input$palette,
      show_labels = input$show_labels,
      transparency = input$transparency,
      title_text = input$chart_title
    )
  }, res = 120)

  output$data_table <- renderDT({
    datatable(sorted_data(), rownames = FALSE, selection = "single",
              options = list(pageLength = 8, scrollX = TRUE, dom = "tip"),
              colnames = c("来源节点 Source", "目标节点 Target", "连接权重 Value"))
  })

  output$selection_info <- renderUI({
    idx <- input$data_table_rows_selected
    dat <- sorted_data()
    if (length(idx) == 1 && nrow(dat) >= idx) {
      row <- dat[idx, ]
      div(class="alert alert-info",
          strong("选中关系："),
          paste(row$Source, "→", row$Target,
                "；权重：", format(row$Value, big.mark=",")),
          br(),
          span("弦图已突出显示该关系的两个节点及其关联连线。"))
    } else {
      div(class="muted", "在关系表中选择一行，可联动突出显示来源节点、目标节点及其连接。")
    }
  })
  output$download_svg <- downloadHandler(
    filename = function() paste0("Circos-Studio-", Sys.Date(), ".svg"),
    content = function(file) {
      svglite::svglite(file, width = 10, height = 8, bg = "white")
      device_id <- grDevices::dev.cur()
      tryCatch(
        draw_circos(filtered(), selected_nodes(), input$palette,
                    input$show_labels, input$transparency, input$chart_title),
        finally = if (device_id %in% grDevices::dev.list()) grDevices::dev.off(device_id)
      )
    }
  )

  output$download_png <- downloadHandler(
    filename = function() paste0("Circos-Studio-", Sys.Date(), ".png"),
    content = function(file) {
      grDevices::png(file, width = 2400, height = 1900, res = 300, bg = "white")
      device_id <- grDevices::dev.cur()
      tryCatch(
        draw_circos(filtered(), selected_nodes(), input$palette,
                    input$show_labels, input$transparency, input$chart_title),
        finally = if (device_id %in% grDevices::dev.list()) grDevices::dev.off(device_id)
      )
    }
  )
}
 shinyApp(ui = ui, server = server)
