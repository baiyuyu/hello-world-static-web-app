# Hello World - Azure Static Web Apps

一个最小的 Azure Static Web Apps 示例：HTML 页面和图片作为静态文件发布，页面通过 `/api/hello` 调用独立的 Azure Functions API。

## 项目结构

```text
.
├── index.html                         # 页面结构
├── styles.css                         # 页面样式
├── app.js                             # 调用后端 API
├── assets/
│   └── hello-world.svg                # 独立图片资源
├── api/
│   ├── host.json
│   ├── package.json
│   └── src/functions/hello.js         # GET /api/hello
├── staticwebapp.config.json           # API Node.js 运行时和页面路由配置
└── .github/workflows/deploy.yml       # GitHub Actions 自动部署
```

## 部署前准备

- Azure 订阅
- GitHub 账号和一个用于保存本项目的 GitHub 仓库
- Node.js 22（仅本地运行 API 时需要）
- Azure Functions Core Tools v4（仅本地运行 API 时需要）

## 首次部署

### 1. 创建 GitHub 仓库并推送代码

在 GitHub 创建一个空仓库，然后在本项目目录执行：

```bash
git init
git add .
git commit -m "Add Hello World static web app"
git branch -M main
git remote add origin https://github.com/<你的账号>/<仓库名>.git
git push -u origin main
```

### 2. 在 Azure 创建 Static Web App

1. 登录 [Azure Portal](https://portal.azure.com/)。
2. 选择 **Create a resource**，搜索并创建 **Static Web App**。
3. 选择订阅、资源组、名称和靠近用户的区域。
4. 定价计划选择 **Free**（本示例使用静态托管和托管 API）。
5. 部署来源选择 **Other**，创建资源。此项目的 GitHub Actions 工作流负责后续部署。
6. 创建完成后打开该 Static Web App 的 **Manage deployment token**，复制部署令牌。

### 3. 将部署令牌保存到 GitHub

在 GitHub 仓库打开 **Settings → Secrets and variables → Actions → New repository secret**：

- Name：`AZURE_STATIC_WEB_APPS_API_TOKEN`
- Secret：粘贴上一步复制的部署令牌

### 4. 触发首次部署

确认代码已推送到 `main` 分支，然后在仓库的 **Actions** 页面查看 **Deploy Azure Static Web App** 工作流。成功后，工作流日志会显示部署结果；Azure Static Web App 的 **Overview** 页面也会显示站点 URL。

## 重新部署

修改页面、图片或 API 后，将更改推送到 `main` 分支即可自动重新部署：

```bash
git add .
git commit -m "Update Hello World page"
git push
```

每次推送都会启动 GitHub Actions。可在仓库的 **Actions** 页面查看构建和部署日志。Pull request 会部署预览环境；关闭 pull request 时会清理对应的预览环境。

## 本地运行

在 `api` 目录安装依赖并启动 Functions API：

```bash
cd api
npm install
npm start
```

API 默认监听 `http://localhost:7071`。另开终端，在项目根目录通过 Azure Static Web Apps CLI 同时提供静态页面并代理 API：

```bash
npm install -g @azure/static-web-apps-cli
swa start . --api-devserver-url http://localhost:7071
```

打开 CLI 输出的本地地址，确认页面显示后端返回的问候语。直接用文件方式打开 `index.html` 不会代理 `/api/hello`。

## API 响应

`GET /api/hello` 返回 JSON：

```json
{
  "message": "Hello World from the Azure Functions API."
}
```

API 使用匿名访问，仅用于演示；不要在其中放置密钥或敏感数据。
