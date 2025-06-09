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
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                   title:
 *                     type: string
 *                   description:
 *                     type: string
 *                   status:
 *                     type: string
 *                     enum: [todo, doing, done]
 *                   deadline:
 *                     type: string
 *                     format: date-time
 *                   assignee:
 *                     type: string
 *       401:
 *         description: Unauthorized
 */

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
 *         description: 'Lọc theo trạng thái (todo, doing, done)'
 *       - in: query
 *         name: groupId
 *         schema:
 *           type: string
 *         description: 'Lọc theo group ID'
 *       - in: query
 *         name: deadline
 *         schema:
 *           type: string
 *           format: date-time
 *         description: 'Lọc theo deadline (ví dụ: "2025-06-10")'
 *       - in: query
 *         name: create
 *         schema:
 *           type: string
 *           format: date-time
 *         description: 'Lọc theo ngày tạo (ví dụ: "2025-06-01")'
 *     responses:
 *       200:
 *         description: 'Danh sách task được giao'
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 *       400:
 *         description: 'Yêu cầu không hợp lệ'
 *       401:
 *         description: 'Unauthorized'
 */

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
 *               type: object
 *               properties:
 *                 id:
 *                   type: string
 *                 group:
 *                   type: string
 *                 title:
 *                   type: string
 *                 description:
 *                   type: string
 *                 assignee:
 *                   type: string
 *                   nullable: true
 *                 status:
 *                   type: string
 *                   enum: [pending, todo, doing, done]
 *                 deadline:
 *                   type: string
 *                   format: date-time
 *                 createdBy:
 *                   type: string
 *                 created:
 *                   type: string
 *                   format: date-time
 *                 updated:
 *                   type: string
 *                   format: date-time
 *                 assigneeInfo:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Yêu cầu không hợp lệ
 *       404:
 *         description: Task không tồn tại
 */
router.get("/tasks/:taskId", requireAuth, getTaskDetail);
router.get("/tasks/assigned", requireAuth, getAssignedTasks);

router.get("/tasks/:taskId/assignee", requireAuth,getAssigneeInfo);
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
// Fetch tasks for the current day
router.get("/tasks/today", requireAuth, getTasksForToday);

export default router;
