// routes/task.routes.js
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  createTask,
  listTasksByGroup,
  updateTaskStatus,
  deleteTask,
  countTasksByGroup,
} from "../controllers/task.controller.js";

const router = express.Router();
/**
 * @swagger
 * tags:
 *   name: Tasks
 *   description: Manage tasks in groups
 */

/**
 * @swagger
 * /groups/{groupId}/tasks:
 *   post:
 *     summary: Create a task in a group
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [title]
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               assignee:
 *                 type: string
 *               deadline:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       201:
 *         description: Task created
 */

/**
 * @swagger
 * /groups/{groupId}/tasks:
 *   get:
 *     summary: List tasks in a group with optional filters
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *       - in: query
 *         name: assignee
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: perPage
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of tasks
 */

/**
 * @swagger
 * /tasks/{taskId}/status:
 *   patch:
 *     summary: Update the status of a task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [todo, doing, done]
 *     responses:
 *       200:
 *         description: Task updated
 */

/**
 * @swagger
 * /tasks/{taskId}:
 *   delete:
 *     summary: Delete a task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Task deleted
 */

/**
 * @swagger
 * /groups/{groupId}/tasks/count:
 *   get:
 *     summary: Count tasks in a group
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Task count
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 count:
 *                   type: integer
 */


// Create a task in a group
router.post("/groups/:groupId/tasks", requireAuth, createTask);

// List all tasks in a group
router.get("/groups/:groupId/tasks", requireAuth, listTasksByGroup);

// Update only the status of a task
router.patch("/tasks/:taskId/status", requireAuth, updateTaskStatus);

// Delete a task
router.delete("/tasks/:taskId", requireAuth, deleteTask);

// Count number of tasks in a group
router.get("/groups/:groupId/tasks/count", requireAuth, countTasksByGroup);

export default router;
