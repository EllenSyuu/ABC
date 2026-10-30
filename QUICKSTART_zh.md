# 开始使用

1. 克隆本仓库。
2. 从上游仓库 AmeerD/ABC 取得公开测试数据，放到 data/ABCtest.rda（本仓库不重新分发该数据）。
3. 在 RStudio 重启 R，设置工作目录为该根目录。
4. 执行：

```r
source("scripts/check_setup.R")
```

若已有四链结果，可先导入，避免重复计算：

```r
source("scripts/import_existing_fits.R")
import_existing_fits("results/validation_4chains", attest_same_example = TRUE)
source("scripts/validate_ABC.R")
source("scripts/process_results.R")
source("scripts/plot_results.R")
```

导入需你确认原结果对应相同测试数据；程序核对维度和采样配置，但无法独立
追回旧抽样的数据来源。导入可在中断后重新运行；相同文件和配置将跳过，冲突时停止，不会覆盖。

若要从头做一次完整复现，则不导入，直接：

```r
source("scripts/run_ABC_modern.R")
```

原始抽样保存在 results/reproduction/，新表格与四链图片在 reports/generated/。
reports/reference_run/ 记录的是参考运行的检查数值；本仓库脚本尚未在全新会话中完整运行过。
详细说明与限制见 README.md 和 docs/validation_status.md。
