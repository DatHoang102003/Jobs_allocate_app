// routes/task.routes.js
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  createTask,
  listTasksByGroup,
  updateTaskStatus,
  deleteTask,
  countTasksByGroup,
  getTasksForToday,
  updateTask,
  taskSummary,
} from "../controllers/task.controller.js";

const router = express.Router();

/* ─────────────────────────────────────────────
   Swagger tag
───────────────────────────────────────────── */
/**
 * @swagger
 * tags:
 *   - name: Tasks
 *     description: Manage tasks in groups
 */

/* ─────────────────────────────────────────────
   POST  /groups/{groupId}/tasks   (create)
───────────────────────────────────────────── */
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
 *       required: true
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
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed]
 *     responses:
 *       201:
 *         description: Task created
 */
router.post("/groups/:groupId/tasks", requireAuth, createTask);

/* ─────────────────────────────────────────────
   GET   /groups/{groupId}/tasks   (list + filters)
───────────────────────────────────────────── */
/**
 * @swagger
 * /groups/{groupId}/tasks:
 *   get:
 *     summary: List tasks in a group
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
router.get("/groups/:groupId/tasks", requireAuth, listTasksByGroup);

/* ─────────────────────────────────────────────
   PATCH /tasks/{taskId}/status   (assignee-only)
───────────────────────────────────────────── */
/**
 * @swagger
 * /tasks/{taskId}/status:
 *   patch:
 *     summary: Update task status (assignee only)
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
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed]
 *     responses:
 *       200:
 *         description: Task updated
 *       403:
 *         description: Forbidden
 */
router.patch("/tasks/:taskId/status", requireAuth, updateTaskStatus);

/* ─────────────────────────────────────────────
   PATCH /tasks/{taskId}   (full edit)
───────────────────────────────────────────── */
/**
 * @swagger
 * /tasks/{taskId}:
 *   patch:
 *     summary: Edit a task
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
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               assignee:
 *                 type: string
 *               deadline:
 *                 type: string
 *                 format: date-time
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed]
 *     responses:
 *       200:
 *         description: Updated task
 *       404:
 *         description: Task not found
 */
router.patch("/tasks/:taskId", requireAuth, updateTask);

/* ─────────────────────────────────────────────
   DELETE /tasks/{taskId}
───────────────────────────────────────────── */
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
router.delete("/tasks/:taskId", requireAuth, deleteTask);

/* ─────────────────────────────────────────────
   GET /groups/{groupId}/tasks/count
───────────────────────────────────────────── */
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
router.get("/groups/:groupId/tasks/count", requireAuth, countTasksByGroup);

/* ─────────────────────────────────────────────
   GET /tasks/today
───────────────────────────────────────────── */
/**
 * @swagger
 * /tasks/today:
 *   get:
 *     summary: Tasks assigned for today
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Today's tasks
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items: { type: object }
 */
router.get("/tasks/today", requireAuth, getTasksForToday);

/* ─────────────────────────────────────────────
   GET /groups/{groupId}/tasks/summary
───────────────────────────────────────────── */
/**
 * @swagger
 * /groups/{groupId}/tasks/summary:
 *   get:
 *     summary: Task counts by status for a group
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Counts per status
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 total:       { type: integer }
 *                 pending:     { type: integer }
 *                 in_progress: { type: integer }
 *                 completed:   { type: integer }
 */
router.get("/groups/:groupId/tasks/summary", requireAuth, taskSummary);

export default router;
