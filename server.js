import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import authRoutes from "./routes/auth.routes.js";
import groupRoutes from "./routes/group.routes.js";
import { requireAuth } from "./middleware/auth.middleware.js";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// Register routes
app.use("/auth", authRoutes);
app.use("/groups", groupRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`API listening on http://localhost:${PORT}`)
);
