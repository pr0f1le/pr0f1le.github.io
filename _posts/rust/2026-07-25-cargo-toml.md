---
title:      Cargo.toml 文件速记
time:       2026-07-25 18:36:56 +0800 CST
author:     me
tags:       [rust, cargo]
categories: [Code]
---

### 包/项目信息

```toml
[package]
name = "project_name" # 项目名称，必须唯一
version = "0.1.0" # 版本号，遵循语义化版本控制
authors = ["Author <email@example.com>"] # 作者信息
edition = "2021" # Rust 版本，一般由 cargo new 自动创建
rust-version = "1.56" # 项目支持的最低 Rust 版本，需要大于等于 edition 引入的 Rust 版本，可选
description = "A short description of the project" # 项目简介
documentation = "https://docs.rs/project_name" # 文档链接
readme = "README.md" # README 文件路径
homepage = "https://project-homepage.com" # 项目主页
repository = "https://github.com/user/project" # 源代码仓库
license = "MIT OR Apache-2.0" # 开源协议
keywords = ["rust", "example"] # 关键词，最多 5 个，需要匹配 https://crates.io/category_slugs 上的类别
categories = ["command-line-utilities"] # 项目分类
workspace = "path/to/workspace/root" # 默认向目录树上方寻找第一个设置了 [workspace] 的 Cargo.toml，
                                     # 表示是某个工作空间的成员，不能同时设置 [workspace]
build = "build.rs" # 指定构建脚本
links = "foo" # 指定项目链接的本地库的名称
publish = false # 避免失手将项目发布到 crates.io
```

### 依赖

```toml
[dependencies]
serde = "1.0" # 一般依赖
[dev-dependencies]
tokio = "1.0" # 开发环境依赖
[build-dependencies]
cc = "1.0" # 构建脚本依赖
```

### 构建

```toml
[package]
build = "build.rs" # 构建脚本路径
[lib] # 一个项目只能有一个库对象
name = "library_name" # 库名称
path = "src/lib.rs" # 库入口文件
[[bin]] # 但是可以有多个二进制对象
name = "main" # 二进制文件名称，可选
path = "src/main.rs" # 二进制入口文件，默认对象
[[bin]]
name = "b" # 必选
path = "src/foo.rs" # 不是默认对象
required-features = ["feature1"] # 可以指定依赖的 feature
```

通过 `cargo run --bin <bin-name>` 的方式构建并运行二进制对象

但是对于库对象和默认二进制对象 `src/main`{: .filepath} ，它们的 `name` 字段默认为 `package.name`

对于其他的二进制对象，`name` 字段是必须的，没有默认值

### 工作空间

如果一个包/项目的 `Cargo.toml`{: .filepath} 同时包含 `[package]` 和 `[workspace]` 字段，那么这个包/项目被称为工作空间的根

如果一个 `Cargo.toml`{: .filepath} 只有 `[workspace]` 字段，则它被称为虚拟清单类型的工作空间，这种工作空间很适合没有主
package 或需要将各个 package 组织到单独的目录的情况

使用工作空间可以让各个 package 共享一个 `Cargo.lock`{: .filepath} 和同一个输出目录
同时由根 workspace 管理 `[patch]`，`[replace]`，`[profile.*]` 等，成员的相应字段将被忽略

```toml
[workspace]
members = ["member1", "path/to/the/member", "crates/*"]
exclude = ["crates/test", "path/to/some/other"]
```

### 特性

```toml
[features]
default = ["feature1"] # 默认启用的特性
feature1 = ["serde"] # 依赖的特性
feature2 = [] # 无依赖的特性
```
通过 `cargo build --features "feature1 feature2"` 启用特性。

在代码中使用 `cfg` 表达式进行条件编译

```rust
#[cfg(feature = "feature1")]
pub mod feat1;
```

在这里的意思是，启用了 `feature1` 后 `feat1` 模块才会被引入

