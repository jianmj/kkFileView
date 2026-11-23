# 使用 GitHub Actions 构建 ARM64 镜像

## 发布方式

工作流：`.github/workflows/docker-arm64.yml`（Actions 页面显示为 **Docker ARM64**）。

- 使用 GitHub 原生 `ubuntu-24.04-arm` runner 和 Java 21。
- 自动编译源码，在本次任务中制作基础运行环境和应用镜像，不依赖上游基础镜像的 ARM 支持。
- 验证镜像架构、Java、LibreOffice，并启动应用检查首页；成功后才推送镜像。
- 发布到 `ghcr.io/<仓库所有者>/<仓库名小写>:arm64`。
- 同时发布 `<完整提交SHA>-arm64` 标签，方便固定版本。
- 推送 `v5.0.3` 这样的 Git 标签时，还会发布 `5.0.3-arm64`。

## 首次使用

1. 将本地修改提交并推送到自己的 GitHub 仓库 `master` 或 `main` 分支。
2. 打开仓库的 **Actions** 页面；如果 fork 的 Actions 尚未启用，先启用。
3. 选择 **Docker ARM64 → Run workflow → Run workflow**。推送到 `master` / `main` 或推送 `v*` 标签也会自动触发。
4. 等待所有步骤成功，在任务 Summary 中复制镜像拉取命令。

认证使用自动生成的 `GITHUB_TOKEN`，不需要填写 Docker Hub 账号或手动创建 PAT。
工作流声明了 `packages: write`；组织策略仍需允许该权限。
如果出现 `permission_denied: write_package`，检查组织策略及已有同名 Package 的 **Manage Actions access**，确保当前仓库有写权限。
GHCR 首次创建的包通常是私有的。如需匿名拉取，在 GitHub 个人主页的 **Packages → kkfileview → Package settings** 中将包可见性改为 Public。

## 当前仓库示例

```bash
docker pull ghcr.io/jianmj/kkfileview:arm64
docker run -d --name kkfileview --restart unless-stopped \
  -p 8012:8012 -e KK_CACHE_TYPE=jdk \
  ghcr.io/jianmj/kkfileview:arm64
```

访问 `http://<服务器IP>:8012/`。目标服务器应为 Linux ARM64（例如鲲鹏），不是 ARMv7。
包若保持私有，需要先使用具有读取 Packages 权限的凭据执行 `docker login ghcr.io`。
生产环境建议使用 `<提交SHA>-arm64` 标签固定镜像。

## ARM64 依赖与功能边界

`mvn -Pdocker-arm64 -DskipTests package` 会选择 OpenCV、OpenBLAS、FFmpeg 的 `linux-arm64` 原生依赖，并补充 JavaCPP 的 ARM64 本地库；普通 Maven 构建继续使用原来的 Linux x86_64 依赖。

现有 `sevenzipjbinding:16.02-2.01` 和 `rocksdbjni:5.17.2` 未在本次修改中升级，也不能据镜像构建成功断言它们支持 ARM64。
默认使用 JDK 缓存，避免依赖 RocksDB；不要在未验证前设置 `KK_CACHE_TYPE=default`。
压缩包预览仍需要针对 SevenZip 的 ARM64 本地库单独验证或适配。
启动检查只验证服务可以响应，Office 转换、视频转码、CAD 和压缩包预览仍需使用真实文件验收。

## 基础镜像说明

GitHub 构建保留 Ubuntu 官方架构软件源，避免 ARM ports 源被错误替换。
默认安装文泉驿中文字体；不再安装需要在线下载和额外许可交互的 Microsoft 字体安装器。
如果有授权的自定义字体，可放入 `docker/kkfileview-base/fonts/` 后重新构建。

根 Dockerfile 的 `BASE_IMAGE` 可通过构建参数覆盖。当前应用目录和启动路径为 `5.0.3`，升级 Maven 项目版本时需要同步更新 Dockerfile。
`.dockerignore` 只允许 Linux 安装包进入应用镜像构建上下文，避免上传本地 Windows LibreOffice 等无关文件。
原 **Master Auto Deploy** Windows 部署已改为手动触发；Docker 工作流不需要 `KK_DEPLOY_*` 配置。

## 本地验证与 GitHub 验证

本地没有 Docker 时，只能验证 Maven 打包、依赖和工作流语法。
实际 ARM64 镜像构建与启动检查由 GitHub Actions 执行。

参考：
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images
