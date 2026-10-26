# Hello World - Azure Static Web Apps + Blob Storage

一个最小示例：网页（HTML/CSS/JS）和后端 API 部署在 Azure Static Web Apps，图片、视频等媒体资源放在 Azure Blob Storage。两者**分开部署**：改网页不会重新上传媒体，换图片也不需要重新部署网站。

网站开启了**邀请制登录**：只有被邀请（拥有 `viewer` 角色）的微软账号才能访问网页和 API。

## 当前部署信息

| 项目 | 值 |
| --- | --- |
| 网站地址 | https://thankful-moss-0f5c50d03.5.azurestaticapps.net |
| API 地址 | https://thankful-moss-0f5c50d03.5.azurestaticapps.net/api/hello |
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
│   ├── app.js                         # 显示登录用户、调用后端 API
│   ├── unauthorized.html              # 已登录但未受邀时显示的页面
│   └── staticwebapp.config.json       # API 运行时、访问权限和路由配置
├── api/                               # Azure Functions 后端
│   ├── host.json
│   ├── package.json
│   └── src/functions/hello.js         # GET /api/hello
├── media/                             # 媒体资源（上传到 Blob，不随网站部署）
│   ├── hello-world.svg
│   └── videos/                        # 视频（已在 .gitignore 中忽略，只保留在本地）
│       └── hello-world-demo.mp4
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
> 视频等大文件（尤其超过 100 MB）不要提交到 Git：GitHub 会拒绝。`media/videos/` 已加入 `.gitignore`，视频只保留在本地并用脚本上传。`media/` 的改动即使提交推送，也不会触发网站部署。

### 添加视频（示例：`media/videos/hello-world-demo.mp4`）

1. 把视频放进 `media/videos/`。网页播放建议使用 MP4（H.264 视频 + AAC 音频），并带 `faststart`，这样不用下载完整文件就能开始播放。用 ffmpeg 转码：

   ```powershell
   ffmpeg -i 原视频.mov -c:v libx264 -crf 23 -pix_fmt yuv420p -c:a aac -movflags +faststart media\videos\my-video.mp4
   ```

2. 上传（网站不会重新部署）：

   ```powershell
   .\scripts\upload-media.ps1 media\videos\my-video.mp4
   ```

3. 在 `site/index.html` 中引用，然后 `git push`：

   ```html
   <video controls muted playsinline preload="metadata">
     <source src="https://helloworldmediabaiyuyu.blob.core.windows.net/media/videos/my-video.mp4" type="video/mp4" />
   </video>
   ```

   `preload="metadata"` 只预加载时长等信息，用户点播放时才下载视频内容。

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

# 让匿名请求使用新版 API，返回 Accept-Ranges 头，视频才能在所有浏览器（含 Safari / iOS）中拖动进度条
az storage account blob-service-properties update --account-name helloworldmediabaiyuyu --resource-group rg-hello-world-swa `
  --set defaultServiceVersion=2021-08-06

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
- **视频能播放但无法拖动进度条**：确认已执行“从零部署”第 5 步中的 `defaultServiceVersion` 设置，可用 `curl.exe -I <视频地址>` 检查是否返回 `Accept-Ranges: bytes`。
- **视频无法播放**：确认 Content-Type 是 `video/mp4`（脚本会自动设置），且编码是 H.264 + AAC。
- Pull request 会部署预览环境，关闭 pull request 时会自动清理。

## 邀请制登录

### 工作原理

[site/staticwebapp.config.json](site/staticwebapp.config.json) 中的规则（按顺序匹配）：

| 规则 | 作用 |
| --- | --- |
| `/.auth/login/github` → 404 | 禁用 GitHub 登录，只允许微软账号 |
| `/login`、`/logout` | 登录 / 退出的友好地址 |
| `/unauthorized.html` 允许 `anonymous` | “无权限”页面任何人都能看到 |
| `/*` 只允许 `viewer` | 其余所有页面和 `/api/*` 都需要 `viewer` 角色 |
| 401 → 跳转 `/.auth/login/aad` | 未登录时自动跳转到微软登录，登录后回到原页面 |
| 403 → 显示 `unauthorized.html` | 已登录但未受邀时显示“没有访问权限” |

访问流程：

```text
未登录 ──► 微软登录 ──► 已受邀（有 viewer 角色）──► 看到网页
                     └► 未受邀 ──────────────────► “没有访问权限”页面
```

### 邀请用户

```powershell
az staticwebapp users invite --name hello-world-swa-baiyuyu --resource-group rg-hello-world-swa `
  --authentication-provider AAD --user-details someone@example.com --roles viewer `
  --domain thankful-moss-0f5c50d03.5.azurestaticapps.net --invitation-expiration-in-hours 168
```

- 命令会输出 `invitationUrl`，把这个链接发给对方。对方打开后用**同一个邮箱**的微软账号登录并同意授权，就获得了 `viewer` 角色。
- 链接有有效期（最长 168 小时），过期后需要重新生成。
- Free 和 Standard 计划最多都只能通过邀请给 25 个用户分配角色。
- 也可以在 Azure Portal 中操作：Static Web App → **Role management** → **Invite**。

### 查看、修改与移除用户

```powershell
# 查看已分配角色的用户
az staticwebapp users list --name hello-world-swa-baiyuyu --resource-group rg-hello-world-swa -o table

# 移除访问权限：把角色改为仅 anonymous（移除 viewer）
az staticwebapp users update --name hello-world-swa-baiyuyu --resource-group rg-hello-world-swa `
  --authentication-provider AAD --user-details someone@example.com --roles anonymous
```

角色变更在用户**下次登录**时生效。已登录的用户可以访问 `/logout` 退出后再重新登录。也可以在 Azure Portal → Static Web App → **Role management** 中直接删除用户。

### 注意

- 登录只保护 Static Web Apps 上的网页和 API。Blob 上的图片和视频仍然是公开地址，拿到链接就能访问。
- 公司租户可能要求管理员批准 “Azure Static Web Apps” 应用才能登录。如果登录时提示 “Need admin approval”，需要联系 IT，或改用个人微软账号测试。

## 验证部署

```powershell
$site = "https://thankful-moss-0f5c50d03.5.azurestaticapps.net"
foreach ($p in "/", "/api/hello", "/unauthorized.html") {
  "{0,-20} {1}" -f $p, (curl.exe -s -o NUL -w "%{http_code} %{redirect_url}" "$site$p")
}
$media = "https://helloworldmediabaiyuyu.blob.core.windows.net/media"
foreach ($u in "$media/hello-world.svg", "$media/videos/hello-world-demo.mp4") {
  "{0}  {1}" -f (Invoke-WebRequest $u -UseBasicParsing -Method Head).StatusCode, $u
}
```

未登录时，`/` 和 `/api/hello` 应返回 `302` 并跳转到 `/.auth/login/aad`，`/unauthorized.html` 返回 `200`，媒体地址返回 `200`。

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

打开 CLI 输出的本地地址即可。SWA CLI 会模拟登录：访问 `/.auth/login/aad` 时出现模拟登录表单，在 Roles 中填 `viewer` 即可访问。图片直接从 Blob 加载，本地也能显示。

## API 响应

`GET /api/hello` 返回：

```json
{
  "message": "Hello World from the Azure Functions API."
}
```

API 只有已受邀的登录用户才能访问（受上面的路由规则保护）；仅用于演示，不要在其中放置密钥或敏感数据。

## 删除资源

```powershell
az group delete --name rg-hello-world-swa --yes     # 同时删除 Static Web App 和存储账号
gh repo delete baiyuyu/hello-world-static-web-app --yes
```
