import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import authRoutes from "./routes/auth.routes.js";
import groupRoutes from "./routes/group.routes.js";
import { requireAuth } from "./middleware/auth.middleware.js";
import joinRoutes from "./routes/join.routes.js";
import taskRoutes from "./routes/task.routes.js";
import membershipRoutes from "./routes/membership.routes.js";
import userRoutes from "./routes/user.routes.js";
import { setupSwagger } from "./swagger.js";
dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
setupSwagger(app);
// Register routes
app.use("/auth", authRoutes);
app.use("/groups", groupRoutes);
app.use("/", joinRoutes);
app.use("/", taskRoutes);
app.use("/", membershipRoutes);
app.use("/", userRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log("API listening on http://localhost:3000");
  console.log("Swagger docs at http://localhost:3000/docs");
});
