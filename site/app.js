const apiMessage = document.querySelector("#api-message");
const userName = document.querySelector("#user-name");

async function loadUser() {
  try {
    const response = await fetch("/.auth/me");
    const { clientPrincipal } = await response.json();
    userName.textContent = clientPrincipal
      ? `已登录：${clientPrincipal.userDetails}`
      : "未登录";
  } catch (error) {
    console.error("Unable to load the signed-in user.", error);
    userName.textContent = "";
  }
}

async function loadGreeting() {
  try {
    const response = await fetch("/api/hello");
    if (!response.ok) {
      throw new Error(`API returned HTTP ${response.status}`);
    }

    const result = await response.json();
    if (typeof result.message !== "string") {
      throw new Error("API response did not contain a message.");
    }

    apiMessage.textContent = result.message;
  } catch (error) {
    console.error("Unable to load the greeting from the API.", error);
    apiMessage.textContent = "暂时无法连接后端 API，请检查部署状态后重试。";
  }
}

loadUser();
loadGreeting();
