# QATrack

Software Test & Quality Management Platform · 软件测试与质量管理平台

以可追踪性为核心，将需求、测试用例、测试计划、测试执行、测试结果与缺陷关联起来。
项目用于《Web应用开发实践》课程设计，并计划作为长期维护的个人项目。

当前已完成 Maven WAR 骨架，并宣布 QATrack V1 Domain Model Freeze v1.0。
19 表数据库结构、680 条测试数据及 SQL 验证已在 MySQL 8.0.46 执行；尚无 Java/前端业务实现，空 WAR 不代表应用可用。

## 技术约束

- 目标环境：JDK 21 LTS、Maven 3.9.x、MySQL 8.0.46、Tomcat 10.1.x。
- Servlet 体系：Jakarta Servlet 6.0，后续使用 `jakarta.servlet.*`，不混用 `javax.servlet.*`。
- 后端采用原生 Java、JDBC、Jackson JSON；不使用 Spring 或 ORM 框架。
- 调用方向：Servlet → Service → DAO → JDBC → MySQL；Model 为数据模型。
- DAO 必须分离接口与实现；业务规则和事务控制归 Service，Servlet 只处理 HTTP。
- 前端采用 HTML、CSS、JavaScript、jQuery、Bootstrap、Bootstrap Table、ECharts 和 AJAX。
- 后续使用 JUnit 5、Mockito、JaCoCo 验证 Service，核心业务覆盖率至少 60%。

目前 POM 不包含应用依赖。实现首个 Servlet 时再加入 Servlet API 6.0 的 `provided` 依赖，
其余依赖随对应功能引入。

## 目录

```text
docs/                         审计和后续设计文档
src/main/java/io/github/lz007001cn/qatrack/
  model/                      数据模型
  dao/                        DAO 接口及 JDBC 实现
  service/                    业务规则与事务
  servlet/                    HTTP 接口
  util/                       职责明确的基础工具
  exception/                  异常类型
src/main/resources/           应用资源
src/main/webapp/WEB-INF/       Web 应用配置
src/main/webapp/static/        css、js、images
src/test/java/                后续测试
```

空目录使用 `.gitkeep` 保留，打包时排除这些占位文件。

## 构建

先确保终端的 `JAVA_HOME` 指向 JDK 21，`PATH` 包含该 JDK 和 Maven 的 `bin` 目录。

```shell
java -version
mvn -version
mvn validate
mvn clean package
```

输出为 `target/qatrack-0.1.0-SNAPSHOT.war`。目前没有 Java 测试，不产生业务代码覆盖率结论；数据库验证单独见下方入口。
本机已验证的 PowerShell 环境设置及限制见 [环境审计](docs/ENVIRONMENT-AUDIT.md)。

## IntelliJ IDEA

打开仓库根目录的 `pom.xml` 并作为 Maven 项目加载。Project SDK、Maven importer 和
Maven runner 均应选择 JDK 21，语言级别以 POM 中的 `maven.compiler.release=21` 为准。
本地 `.idea/`、`*.iml`、构建产物和本地敏感配置已由 `.gitignore` 排除。

## V1 冻结模型与数据库

- [领域模型](docs/DOMAIN-MODEL.md)：冻结的业务边界、关系、状态、快照与事务。
- [数据库设计](docs/DATABASE-DESIGN-DRAFT.md)：19 表、154 字段及与真实 DDL 一致的约束和索引。
- [Mermaid ER 源文件](docs/V1-ER.mmd)：19 表、40 条外键关系。
- [Freeze v1.0 决策](docs/DOMAIN-FREEZE-v1.0.md)：Run 直接保存非空 project_id 的七维比较。
- [数据库执行说明](database/README.md)：schema、seed、约束测试、核心查询及验证脚本。
- [数据库实测报告](docs/DATABASE-VALIDATION-v1.0.md)：178 项测试、22 项数据一致性检查及对象统计。
- [上一轮设计审计](docs/V1-DESIGN-AUDIT.md)：20 表阶段的历史记录，已由冻结模型取代。

Run 支持可选 Plan、Ad-hoc 与无计划 JUnit/CI 导入；执行项/快照与 Attempt 结果分离，SKIPPED 单独统计，自动化身份通过独立映射关联用例。

本轮明确使用 MySQL 8.0.46；环境审计中的 8.4 目标保留为历史记录。
Run 项目归属直接保存在 test_runs.project_id；本轮数据库验证完成后，业务模块仍待分阶段实现。
