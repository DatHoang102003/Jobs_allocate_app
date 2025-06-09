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
  getAssigneeInfo,
  getAssignedTasks,
  getTaskDetail,
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

// Create a task in a group
router.post(
  "/groups/:groupId/tasks",
  requireAuth,
  createTask
);

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
// List all tasks in a group
router.get(
  "/groups/:groupId/tasks",
  requireAuth,
  listTasksByGroup
);

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
// Count number of tasks in a group
router.get(
  "/groups/:groupId/tasks/count",
  requireAuth,
  countTasksByGroup
);

/**
 * @swagger
 * /tasks/today:
 *   get:
 *     summary: Get tasks assigned for today
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of today's tasks
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 *       401:
 *         description: Unauthorized
 */
// Fetch tasks for the current day
router.get(
  "/tasks/today",
  requireAuth,
  getTasksForToday
);

/**
 * @swagger
 * /tasks/assigned:
 *   get:
 *     summary: Lấy công việc được giao cho người dùng hiện tại
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *       - in: query
 *         name: groupId
 *         schema:
 *           type: string
 *       - in: query
 *         name: deadline
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: create
 *         schema:
 *           type: string
 *           format: date-time
 *     responses:
 *       200:
 *         description: Danh sách task được giao
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 *       400:
 *         description: Yêu cầu không hợp lệ
 *       401:
 *         description: Unauthorized
 */
// Lấy công việc được giao cho người dùng hiện tại
router.get(
  "/tasks/assigned",
  requireAuth,
  getAssignedTasks
);

/**
 * @swagger
 * /tasks/{taskId}:
 *   get:
 *     summary: Lấy chi tiết task theo ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID của task
 *     responses:
 *       200:
 *         description: Chi tiết task, bao gồm thông tin assignee nếu có
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/TaskDetail'
 *       400:
 *         description: Yêu cầu không hợp lệ
 *       404:
 *         description: Task không tồn tại
 */
// Lấy chi tiết một task theo ID
router.get(
  "/tasks/:taskId",
  requireAuth,
  getTaskDetail
);

/**
 * @swagger
 * /tasks/{taskId}/assignee:
 *   get:
 *     summary: Lấy thông tin người được giao (assignee) của một task
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID của task
 *     responses:
 *       200:
 *         description: Thông tin user được giao
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         description: Task không có assignee hoặc không tìm thấy
 *       400:
 *         description: Yêu cầu không hợp lệ
 */
// Lấy thông tin assignee của task
router.get(
  "/tasks/:taskId/assignee",
  requireAuth,
  getAssigneeInfo
);

/**
 * @swagger
 * /tasks/{taskId}:
 *   patch:
 *     summary: Update full task (if you expose edit screen)
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
 *             $ref: '#/components/schemas/TaskUpdate'
 *     responses:
 *       200:
 *         description: Task updated
 */
// (optional) full edit
router.patch(
  "/tasks/:taskId",
  requireAuth,
  updateTaskStatus // or your full update handler
);

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
// Delete a task
router.delete(
  "/tasks/:taskId",
  requireAuth,
  deleteTask
);

export default router;
