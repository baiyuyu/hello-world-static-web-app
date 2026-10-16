# Hello World - Azure Static Web Apps + Blob Storage

一个最小示例：网页（HTML/CSS/JS）和后端 API 部署在 Azure Static Web Apps，图片、视频等媒体资源放在 Azure Blob Storage。两者**分开部署**：改网页不会重新上传媒体，换图片也不需要重新部署网站。

## 当前部署信息

| 项目 | 值 |
| --- | --- |
| 网站地址 | https://brave-rock-0f0f71b03.5.azurestaticapps.net |
| API 地址 | https://brave-rock-0f0f71b03.5.azurestaticapps.net/api/hello |
| 媒体地址前缀 | https://helloworldmediabaiyuyu.blob.core.windows.net/media/ |
| GitHub 仓库 | https://github.com/baiyuyu/hello-world-static-web-app |
| Azure 资源组 | `rg-hello-world-swa`（West Europe） |
| Static Web App | `hello-world-swa-baiyuyu`（Free 计划） |
| Storage Account | `helloworldmediabaiyuyu`，容器 `media`（匿名只读） |
| GitHub Secret | `AZURE_STATIC_WEB_APPS_API_TOKEN` |

## 架构

```text
浏览器
  ├── 网页 / API ──► Azure Static Web Apps   （git push → GitHub Actions 自动部署）
  └── 图片 / 视频 ──► Azure Blob Storage     （scripts\upload-media.ps1 单独上传）
```

## 项目结构

```text
.
├── site/                              # 网站内容（只有这个文件夹会部署到 Static Web Apps）
│   ├── index.html                     # 页面结构，图片引用 Blob 地址
│   ├── styles.css
│   ├── app.js                         # 调用后端 API
│   └── staticwebapp.config.json       # API 运行时和路由配置
├── api/                               # Azure Functions 后端
│   ├── host.json
│   ├── package.json
│   └── src/functions/hello.js         # GET /api/hello
├── media/                             # 媒体资源（上传到 Blob，不随网站部署）
│   └── hello-world.svg
├── scripts/
│   └── upload-media.ps1               # 上传媒体到 Blob
└── .github/workflows/deploy.yml       # 网站自动部署（忽略 media/、scripts/、README.md 的改动）
```

## 日常修改

### 只改网页或 API

修改 `site/` 或 `api/` 下的文件，然后：

```powershell
git add .
git commit -m "Update page"
git push
```

推送后 GitHub Actions 自动部署，约 1 分钟生效。查看进度：

```powershell
gh run watch --repo baiyuyu/hello-world-static-web-app --exit-status
```

### 只换图片 / 视频（不重新部署网站）

1. 把文件放进 `media/` 文件夹（可以建子文件夹，如 `media/videos/intro.mp4`）。
2. 在项目根目录上传：

   ```powershell
   .\scripts\upload-media.ps1 media\hello-world.svg   # 只上传指定文件
   .\scripts\upload-media.ps1                         # 上传 media\ 下的全部文件
   ```

   脚本会输出文件的公开地址，例如 `https://helloworldmediabaiyuyu.blob.core.windows.net/media/hello-world.svg`。

3. **同名覆盖**：网页无需任何修改，刷新即可（缓存最长 1 小时，可按 `Ctrl + F5` 强制刷新）。
   **新文件**：在 `site/index.html` 中引用新地址，再 `git push` 部署网页，例如：

   ```html
   <video src="https://helloworldmediabaiyuyu.blob.core.windows.net/media/videos/intro.mp4" controls></video>
   ```

> 提示：想立即生效、避免缓存，可用新文件名（如 `banner-v2.jpg`）再更新网页引用。
>
> 视频等大文件（尤其超过 100 MB）不要提交到 Git：GitHub 会拒绝。可把它们加入 `.gitignore`，只保留在本地 `media/` 并用脚本上传。`media/` 的改动即使提交推送，也不会触发网站部署。

### 上传权限

脚本使用 Azure 登录身份（`--auth-mode login`），不需要存储密钥。上传者需要：

1. 已执行 `az login`；
2. 在存储账号上拥有 **Storage Blob Data Contributor** 角色（当前账号已授予）。给其他人授权：

   ```powershell
   $scope = az storage account show --name helloworldmediabaiyuyu --resource-group rg-hello-world-swa --query id -o tsv
   az role assignment create --assignee <邮箱> --role "Storage Blob Data Contributor" --scope $scope
   ```

   新授予的角色可能需要几分钟才生效。

## 从零部署（命令行）

需要 [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) 和 [GitHub CLI](https://cli.github.com/)（Windows：`winget install --id GitHub.cli -e`）。

### 1. 登录

```powershell
az login
gh auth login --hostname github.com --git-protocol https --web --scopes "repo,workflow"
```

`gh auth login` 会显示一次性验证码，在 https://github.com/login/device 输入并授权。

### 2. 创建 GitHub 仓库并推送

```powershell
gh auth setup-git
git init -b main
git add .
git commit -m "Add Hello World static web app"
gh repo create <你的账号>/hello-world-static-web-app --public --source . --remote origin --push
```

### 3. 创建 Static Web App

```powershell
az group create --name rg-hello-world-swa --location westeurope
az staticwebapp create --name hello-world-swa-baiyuyu --resource-group rg-hello-world-swa --location westeurope --sku Free
```

输出中的 `defaultHostname` 就是网站地址。

### 4. 把部署令牌写入 GitHub Secret

```powershell
$token = az staticwebapp secrets list --name hello-world-swa-baiyuyu --resource-group rg-hello-world-swa --query properties.apiKey -o tsv
$token | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --repo <你的账号>/hello-world-static-web-app
Remove-Variable token
```

### 5. 创建媒体存储并授权

存储账号名需全局唯一（3–24 位小写字母和数字）。若更换名称，同时修改 `scripts/upload-media.ps1` 中的 `$AccountName` 和 `site/index.html` 中的图片地址。

```powershell
az storage account create --name helloworldmediabaiyuyu --resource-group rg-hello-world-swa --location westeurope `
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --https-only true --allow-blob-public-access true

az storage container-rm create --storage-account helloworldmediabaiyuyu --resource-group rg-hello-world-swa `
  --name media --public-access blob

$uid = az ad signed-in-user show --query id -o tsv
$scope = az storage account show --name helloworldmediabaiyuyu --resource-group rg-hello-world-swa --query id -o tsv
az role assignment create --assignee-object-id $uid --assignee-principal-type User --role "Storage Blob Data Contributor" --scope $scope
```

`--public-access blob` 表示任何人可以通过完整地址读取文件，但不能列出容器内容，也不能写入。

### 6. 上传媒体并部署网站

```powershell
.\scripts\upload-media.ps1
```

第 2 步的推送已触发 GitHub Actions；如果当时还没设置 Secret，那次运行会失败（`deployment_token was not provided`），重跑即可：

```powershell
gh run list --repo <你的账号>/hello-world-static-web-app --limit 3
gh run rerun <run-id> --repo <你的账号>/hello-world-static-web-app
gh run watch <run-id> --repo <你的账号>/hello-world-static-web-app --exit-status
```

## 重新部署与故障处理

- **手动重新部署网站**（不改代码）：

  ```powershell
  gh workflow run "Deploy Azure Static Web App" --repo baiyuyu/hello-world-static-web-app
  ```

- **部署令牌失效**（Actions 报 `ApiToken is invalid`）：重新执行“从零部署”第 4 步，再重跑工作流。
- **上传报 403 / AuthorizationPermissionMismatch**：检查是否拥有 Storage Blob Data Contributor 角色，刚授权需等几分钟。
- **图片显示不出来**：在浏览器直接打开图片的 Blob 地址，确认返回 200；如果是 404，检查文件名和大小写（Blob 名称区分大小写）。
- Pull request 会部署预览环境，关闭 pull request 时会自动清理。

## 验证部署

```powershell
$site = "https://brave-rock-0f0f71b03.5.azurestaticapps.net"
$media = "https://helloworldmediabaiyuyu.blob.core.windows.net/media"
foreach ($u in "$site/", "$site/api/hello", "$media/hello-world.svg") {
  "{0}  {1}" -f (Invoke-WebRequest $u -UseBasicParsing).StatusCode, $u
}
```

三个地址都应返回 `200`。

## 本地运行

```powershell
cd api
npm install
npm start
```

API 默认监听 `http://localhost:7071`。另开终端，在项目根目录运行：

```powershell
npm install -g @azure/static-web-apps-cli
swa start site --api-devserver-url http://localhost:7071
```

打开 CLI 输出的本地地址即可。图片直接从 Blob 加载，本地也能显示。

## API 响应

`GET /api/hello` 返回：

```json
{
  "message": "Hello World from the Azure Functions API."
}
```

API 使用匿名访问，仅用于演示；不要在其中放置密钥或敏感数据。

## 删除资源

```powershell
az group delete --name rg-hello-world-swa --yes     # 同时删除 Static Web App 和存储账号
gh repo delete baiyuyu/hello-world-static-web-app --yes
```
