import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import authRoutes from "./routes/auth.routes.js";
import groupRoutes from "./routes/group.routes.js";
import joinRoutes from "./routes/join.routes.js";
import inviteRoutes from "./routes/invite.routes.js";
import taskRoutes from "./routes/task.routes.js";
import membershipRoutes from "./routes/membership.routes.js";
import userRoutes from "./routes/user.routes.js";
import commentsRoutes from "./routes/comments.routes.js";

import { setupSwagger } from "./swagger.js";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
setupSwagger(app);

// Auth và User
app.use("/auth", authRoutes);
app.use("/", userRoutes);

// Groups, join/invite, membership
app.use("/groups", groupRoutes);
app.use("/", joinRoutes);       // nếu joinRoutes định nghĩa /:groupId/join
app.use("/", inviteRoutes);     // nếu inviteRoutes định nghĩa /:groupId/invite
app.use("/", membershipRoutes); // nếu membershipRoutes định nghĩa /:groupId/membership

// Tasks (cả các route /groups/:groupId/tasks, /tasks/:taskId, /tasks/filter, ...)
app.use("/", taskRoutes);

// Comments cho từng task
// → mount tại đúng đường dẫn /tasks/:taskId/comments
app.use("/tasks/:taskId/comments", commentsRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`);
  console.log(`Swagger docs at http://localhost:${PORT}/docs`);
});
