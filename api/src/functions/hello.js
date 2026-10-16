const { app } = require("@azure/functions");

app.http("hello", {
  methods: ["GET"],
  authLevel: "anonymous",
  handler: async () => ({
    jsonBody: {
      message: "Hello World from the Azure Functions API."
    }
  })
});
