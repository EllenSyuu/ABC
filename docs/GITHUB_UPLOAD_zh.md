# 上传与 commit 指南

这是供现有 AmeerD/ABC 副本使用的增补文件包，不是完整 abcR 包。
先备份现有 README；把压缩包内各文件夹合并到仓库根目录。
不要放到 abcR/R 内，不要删除 abcR、data、docs、scripts 等上游目录。
原 scripts/ABCtest.R 保留，新增脚本不依赖它或 Console 对象。
原始测试数据请从你现有副本复制到 data/ABCtest.rda。

建议分四次提交：

1. models/ABC_indep_modern.stan 与原模型来源记录：
   fix: add Stan model with modern array syntax
2. config/ 与 scripts/：
   feat: add reproducible ABC execution and validation workflow
3. reports/user_reported/ 与 docs/validation_status.md：
   docs: record user-reported four-chain example checks
4. README.md、NOTICE.md、LICENSE.md、.gitignore 和其余说明：
   docs: document setup provenance and reproduction limits

上游已有 LICENSE.md 时保持原许可证，本包副本取自上游。
合并 .gitignore 的规则，不必覆盖你自己已有的其他忽略规则。
大型 results/ 下的 RDS 在本地保留并备份，不要上传。
reports/generated/ 默认忽略；运行成功并人工检查后，把选定的小报告复制到
reports/reviewed/ 后提交：
   docs: add reviewed four-chain reproduction outputs

reports/user_reported/ 是对已贴出数值的明确转录，不是本包独立执行生成的证据。
本包没有更改远程 GitHub。当前图片若来自旧单链，不要标为四链结果。
