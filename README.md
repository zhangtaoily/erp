# EERP - 企业资源计划系统

基于元数据驱动的企业资源计划（ERP）系统，采用 Spring Boot + Vue 3 技术栈，实现业务对象、表单、列表、状态机等全配置化管理。

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **后端框架** | Spring Boot 3.2.5 | Java 17 |
| **ORM** | MyBatis-Plus 3.5.5 | 雪花算法主键 |
| **数据库** | MySQL 8.4 | 开发环境：192.168.0.75:3306/eerp |
| **缓存** | Redis | 元数据缓存 |
| **认证** | JJWT 0.12.5 | HS256 Token，24h 过期 |
| **前端框架** | Vue 3.4 + TypeScript | Composition API |
| **UI 组件** | Element Plus 2.7 | 按需自动导入 |
| **构建工具** | Vite 5.3 | 开发端口 5173 |
| **表达式引擎** | ANTLR 4.13 | 自研 bos-expr 语法（Expr.g4），支持字段引用、函数调用、三元运算 |
| **流程图** | @antv/x6 | 状态机可视化 |
| **代码编辑器** | Monaco Editor | 表达式编辑器 |

## 项目结构

```
d:\prj\erp
├── backend/                        # 后端 Maven 多模块
│   ├── eerp-common/               # 公共模块（BaseEntity、JWT、雪花ID）
│   ├── eerp-meta/                 # 元数据模块（业务对象、字段、状态机等元数据CRUD）
│   ├── eerp-plugin/               # 插件模块
│   ├── eerp-bos/                  # BOS 业务对象服务（表单、列表、操作、状态机、下推）
│   ├── eerp-integration/          # 集成模块（附件、API日志、工作流）
│   ├── eerp-master/               # 基础数据模块（物料、客户、供应商等35+主数据表）
│   ├── eerp-scm/                  # 供应链模块（预留）
│   ├── eerp-mfg/                  # 生产制造模块（预留）
│   ├── eerp-fin/                  # 财务会计模块（预留）
│   ├── eerp-tax/                  # 税务管理模块（预留）
│   ├── eerp-sys-ext/              # 系统扩展模块（预留）
│   ├── eerp-msg/                  # 消息通知模块（预留）
│   ├── eerp-api/                  # API 入口（Controller 层、Spring Boot 启动类）
│   └── eerp-test/                 # 集成测试（H2 内存库）
├── frontend/                       # Vue 3 前端
│   └── src/
│       ├── api/                   # 接口封装
│       ├── components/            # 通用组件
│       │   ├── MasterDetailEditor/ # 主从表动态编辑器
│       │   ├── BillToolbar/        # 单据工具栏
│       │   ├── BoPicker/           # 业务对象选择器
│       │   ├── StateMachineGraph/  # 状态机流程图（@antv/x6）
│       │   └── ExpressionEditor/   # 表达式编辑器（Monaco）
│       ├── layouts/               # 布局（顶栏+侧边菜单+标签页）
│       ├── router/                # 路由配置（动态路由 /bill/:boCode）
│       ├── types/                 # TypeScript 类型定义
│       ├── utils/                 # 工具函数（枚举、请求拦截器等）
│       ├── views/
│       │   ├── bill/runtime/      # 通用单据列表/详情（元数据驱动）
│       │   ├── bos/               # BOS 平台管理（业务对象、表单设计器、列表配置等）
│       │   └── master/            # 基础数据管理
│       └── styles/                # 全局样式
└── README.md
```

## 快速开始

### 环境要求

- JDK 17+
- Maven 3.6+
- Node.js 18+
- MySQL 8.4
- Redis（可选，用于元数据缓存）

### 1. 数据库初始化

在 MySQL 中创建数据库：

```sql
CREATE DATABASE eerp DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

系统启动时会通过 `SchemaMigrationRunner` 自动执行以下迁移：
- 补充缺失的数据库字段（如 `entity_code`、`is_readonly`）
- 修正种子数据（如设置 `amount` 字段的 `formula`）

### 2. 后端启动

```bash
cd backend

# 安装依赖模块
mvn install -DskipTests -U

# 启动 API 服务
mvn -pl eerp-api spring-boot:run
```

服务启动后访问 `http://localhost:8080`。

### 3. 前端启动

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

浏览器自动打开 `http://localhost:5173`，API 请求通过 Vite proxy 转发至后端 8080 端口。

### 4. 登录

默认测试账号由种子数据初始化，或通过 `/api/auth/login` 注册。

## 核心功能

### 元数据驱动

系统核心设计理念是"元数据驱动"——业务对象、表单布局、列表字段、状态流转等全部通过元数据配置，无需硬编码。

| 功能 | 说明 | 入口 |
|------|------|------|
| **业务对象管理** | 定义 BO 编码、主表、状态机开关等 | `/bos/business-object` |
| **表单设计器** | 可视化配置主表/子表/孙表字段，设置只读/隐藏/必填/计算公式 | `/bos/form-designer` |
| **列表配置** | 配置列表显示列、查询字段，自动 JOIN 多表 | `/bos/list-config` |
| **状态机设计** | 定义状态节点与流转路径，可视化编辑 | `/bos/state-machine` |
| **编码规则** | 配置单据号生成规则（前缀+日期+流水） | `/bos/code-rule` |
| **按钮权限** | 按状态控制按钮显隐/可用性 | `/bos/button-availability` |

### 表达式引擎（ANTLR4）

系统内置自研 `bos-expr` 表达式语言，基于 ANTLR4 文法定义，用于驱动实体服务规则、插件脚本、校验表达式等场景。

**语法文件**：[`Expr.g4`](backend/eerp-meta/src/main/resources/grammar/Expr.g4)

**支持特性**：
- 字段引用：`$qty`、`$goods.price`
- 算术运算：`+ - * / %`
- 比较运算：`> < >= <= == !=`
- 逻辑运算：`&& || !`
- 三元条件：`$qty > 0 ? $qty * $price : 0`
- 函数调用：`SUM(...)`、`IF(...)`、`LOOKUP(...)` 等
- 赋值联动：`$amount = $qty * $price`
- 校验抛错：`error('数量不能为零')`

**应用场景**：

| 场景 | 说明 | 示例 |
|------|------|------|
| 实体服务规则 | 联动赋值、校验规则、可用性控制 | `$amount = $qty * $price` |
| 插件脚本 | 自定义业务逻辑 | `IF($qty > 100, error('超限'), null)` |
| 校验规则 | 字段值校验 | `$qty > 0 && $price > 0` |
| 下推规则 | 字段映射转换 | `$out_qty = $qty - $pushed_qty` |

**实现方式**：当前运行时采用手写递归下降解析器（`ExprLexer` / `ExprParser`），与 ANTLR4 文法 `Expr.g4` 保持一致。未来可激活 `antlr4-maven-plugin` 切换为 ANTLR4 代码生成方案。

### 通用单据组件

- **GenericBillList**：动态加载列配置与查询字段，支持自动多表 JOIN、行内编辑
- **GenericBillDetail**：动态加载表单元数据，主表/子表/孙表三段式布局，支持公式计算、汇总、联查

### 业务流程

- 单据状态流转：暂存 → 已创建 → 已提交 → 已审核（可驳回/撤销）
- 下推机制：单据行可下推生成下游单据
- 反写机制：下游审核后自动回写上游数量

### 基础数据

已预置纺织行业 35+ 主数据表，包括：
物料、供应商、客户、仓库、币别、汇率、单位、品牌、色系、质量标准等。

测试种子数据见 `eerp-test/src/test/resources/data-h2-master-data-seed.sql`。

## 运行测试

```bash
cd backend

# 运行全部集成测试（使用 H2 内存库）
mvn -pl eerp-test test
```

## 配置说明

### 环境切换

- **开发环境**：`eerp-api/src/main/resources/application.yml`，连接 MySQL 192.168.0.75:3306/eerp
- **测试环境**：`eerp-test/src/test/resources/application-test.yml`，使用 H2 MySQL 兼容模式，端口随机

### 关键配置项

```yaml
# JWT
jwt:
  secret: <your-secret-key>   # 至少 256 位
  expiration: 86400000        # Token 有效期（ms），默认 24h

# Jackson 命名策略
spring.jackson.property-naming-strategy: SNAKE_CASE  # 前后端统一使用 snake_case

# 附件存储
eerp.storage.type: local      # local / oss / minio
eerp.storage.local.base-path: ./data/attachments
```

## 技术约定

- 前后端统一使用 `snake_case` 字段名（Jackson `SNAKE_CASE` + 前端响应拦截器 `toSnakeKeys`）
- 数据库兼容 MySQL 8.4 + H2 MySQL 模式（不使用 `MERGE INTO`，改用 `REPLACE INTO`）
- 主键策略：`ASSIGN_ID`（雪花算法）
- 逻辑删除字段统一为 `deleted`（0 未删 / 1 已删）
- 单据状态：0-暂存, 1-已创建, 2-已提交, 3-已审核, 4-已驳回


## 联系与交流

微信扫码添加好友，欢迎交流企业ERP、 AI Agent / 数字分身方向的话题：

<img src="./img/c5fbcf54-cd88-406a-96c6-aed80f19a874.png" alt="微信联系方式" width="220" />