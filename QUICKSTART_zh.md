# 开始使用

1. 将这些文件夹合并到你原来 ABC-main 的根目录，先备份同名 README。
   保留 abcR/、data/ 和已有结果，不要删除目录。
2. 确认根目录下有 data/ABCtest.rda（从原项目保留）。
3. 在 RStudio 重启 R，设置工作目录为该根目录。
4. 执行：

```r
source("scripts/check_setup.R")
```

你已跑完四链，优先导入旧结果，避免重复计算：

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
包内记录了你已经报告的检查数值；新脚本尚需在你的 R 环境完成首次运行。
详细说明、限制与 commit 建议见 README.md 和 docs/GITHUB_UPLOAD_zh.md。
