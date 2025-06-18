// routes/task.routes.js
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import commentsRouter from "../routes/comments.routes.js";    

import {
  createTask,
  listTasksByGroup,
  updateTaskStatus,
  deleteTask,
  countTasksByGroup,
  getAssigneeInfo,
  getTaskDetail,
  updateTask,
  getTasksByFilter,
} from "../controllers/task.controller.js";

const router = express.Router({ mergeParams: true });

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
 *             required:
 *               - title
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               assignee:
 *                 type: array
 *                 description: Array of user IDs to assign
 *                 items:
 *                   type: string
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
 * /tasks/filter:
 *   get:
 *     summary: Lấy danh sách task theo bộ lọc (created, deadline, hoặc status)
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: filterBy
 *         required: true
 *         schema:
 *           type: string
 *           enum: [created, deadline, status]
 *         description: Tiêu chí lọc (created, deadline, hoặc status)
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *           format: date
 *         description: Ngày lọc (YYYY-MM-DD, mặc định là hôm nay)
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, in_progress, completed]
 *         description: Trạng thái task (bắt buộc nếu filterBy là status)
 *     responses:
 *       200:
 *         description: Danh sách task phù hợp với bộ lọc
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                   group:
 *                     type: string
 *                   title:
 *                     type: string
 *                   description:
 *                     type: string
 *                   assignee:
 *                     type: array
 *                     items:
 *                       type: string
 *                   status:
 *                     type: string
 *                     enum: [pending, in_progress, completed]
 *                   createdBy:
 *                     type: string
 *                   deadline:
 *                     type: string
 *                     format: date-time
 *       400:
 *         description: Yêu cầu không hợp lệ
 */
router.get(
  "/tasks/filter",
  requireAuth,
  getTasksByFilter
);


/**
 * @swagger
 * /tasks/{taskId}:
 *   get:
 *     summary: Lấy chi tiết một task theo ID
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
 *         description: Chi tiết task kèm thông tin assignees
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
 *                   type: array
 *                   items:
 *                     type: string
 *                 status:
 *                   type: string
 *                   enum: [pending, in_progress, completed]
 *                 createdBy:
 *                   type: string
 *                 deadline:
 *                   type: string
 *                   format: date-time
 *                 assigneeInfo:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *       400:
 *         description: Yêu cầu không hợp lệ
 *       404:
 *         description: Task không tìm thấy
 */
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
 * /tasks/{taskId}/status:
 *   patch:
 *     summary: Update task status by assignee
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the task
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [pending, in_progress, completed]
 *                 description: New status of the task
 *     responses:
 *       200:
 *         description: Updated task object
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Task'
 *       400:
 *         description: Invalid status value or bad request
 *       403:
 *         description: Unauthorized, user not an assignee
 *       404:
 *         description: Task not found
 */
router.patch(
  "/tasks/:taskId/status",
  requireAuth,
  updateTaskStatus
);


/**
 * @swagger
 * /tasks/{taskId}:
 *   delete:
 *     summary: Soft-delete a task
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
 *         description: Task soft-deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *       400:
 *         description: Bad request (e.g. parent group not found)
 *       403:
 *         description: Forbidden (no permission to delete)
 *       404:
 *         description: Task not found
 */
router.delete(
  "/tasks/:taskId",
  requireAuth,
  deleteTask
);

/**
 * @swagger
 * /tasks/{taskId}:
 *   patch:
 *     summary: Cập nhật thông tin task
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
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *                 description: Tiêu đề mới của task
 *               description:
 *                 type: string
 *                 description: Mô tả mới của task
 *               deadline:
 *                 type: string
 *                 format: date-time
 *                 description: Ngày hết hạn mới của task
 *               assignee:
 *                 type: array
 *                 description: Mảng ID của người được giao
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Task đã được cập nhật
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
 *                   type: array
 *                   items:
 *                     type: string
 *                 status:
 *                   type: string
 *                   enum: [pending, in_progress, completed]
 *                 createdBy:
 *                   type: string
 *                 deadline:
 *                   type: string
 *                   format: date-time
 *                 assigneeInfo:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *       400:
 *         description: Yêu cầu không hợp lệ
 *       403:
 *         description: Không có quyền cập nhật task
 *       404:
 *         description: Task không tìm thấy
 */
router.patch(
  "/tasks/:taskId",
  requireAuth,
  updateTask
);
router.use(
  "/tasks/:taskId/comments",
  requireAuth,            // áp dụng auth nếu muốn bảo vệ toàn bộ comments
  commentsRouter         // router xử lý create/list/update/delete comment
);

export default router;
