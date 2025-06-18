import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";

import { 
  createComment, 
  listComments, 
  updateComment, 
  deleteComment 
} from "../controllers/comments.controller.js";

const router = express.Router({ mergeParams: true });

/**
 * @swagger
 * tags:
 *   name: Comments
 *   description: Comment management for tasks
 */

/**
 * @swagger
 * /tasks/{taskId}/comments:
 *   post:
 *     summary: Create a new comment for a task
 *     tags: [Comments]
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
 *               - contents
 *             properties:
 *               contents:
 *                 type: string
 *                 description: Content of the comment
 *               attachments:
 *                 type: array
 *                 items:
 *                   type: string
 *                 description: Array of attachment filenames or URLs
 *     responses:
 *       201:
 *         description: Comment created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Comment'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Task not found
 */
router.post('/', requireAuth, createComment);

/**
 * @swagger
 * /tasks/{taskId}/comments:
 *   get:
 *     summary: List comments for a task
 *     tags: [Comments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the task
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *         description: Page number for pagination
 *       - in: query
 *         name: perPage
 *         schema:
 *           type: integer
 *         description: Number of items per page
 *     responses:
 *       200:
 *         description: List of comments (excludes soft-deleted comments)
 *         content:
 *           application/json:
 *             schema:
 *               oneOf:
 *                 - type: array
 *                   items:
 *                     $ref: '#/components/schemas/Comment'
 *                 - type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     perPage:
 *                       type: integer
 *                     totalItems:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 *                     items:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/Comment'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Task not found
 */
router.get('/', requireAuth, listComments);

/**
 * @swagger
 * /tasks/{taskId}/comments/{commentId}:
 *   patch:
 *     summary: Update a comment
 *     tags: [Comments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the task
 *       - in: path
 *         name: commentId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the comment
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               contents:
 *                 type: string
 *                 description: Updated content of the comment
 *               attachments:
 *                 type: array
 *                 items:
 *                   type: string
 *                 description: Updated array of attachment filenames or URLs
 *     responses:
 *       200:
 *         description: Comment updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Comment'
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Task or comment not found
 */
router.patch('/:commentId', requireAuth, updateComment);

/**
 * @swagger
 * /tasks/{taskId}/comments/{commentId}:
 *   delete:
 *     summary: Soft delete a comment
 *     tags: [Comments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: taskId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the task
 *       - in: path
 *         name: commentId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the comment
 *     responses:
 *       200:
 *         description: Comment soft-deleted successfully (is_deleted set to true)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *       400:
 *         description: Bad request
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden
 *       404:
 *         description: Task or comment not found
 */
router.delete('/:commentId', requireAuth, deleteComment);

/**
 * @swagger
 * components:
 *   schemas:
 *     Comment:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           description: The comment ID
 *         task:
 *           type: string
 *           description: The task ID
 *         author:
 *           type: string
 *           description: The author ID
 *         contents:
 *           type: string
 *           description: Content of the comment
 *         attachments:
 *           type: array
 *           items:
 *             type: string
 *           description: Array of attachment filenames or URLs
 *         created:
 *           type: string
 *           format: date-time
 *           description: Creation timestamp
 *         updated:
 *           type: string
 *           format: date-time
 *           description: Last update timestamp
 *         is_deleted:
 *           type: boolean
 *           description: Indicates if the comment is soft-deleted
 *         expand:
 *           type: object
 *           properties:
 *             author:
 *               type: object
 *               description: Expanded author information
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 */

export default router;