import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import { createGroup, listGroups } from "../controllers/group.controller.js";

const router = express.Router();
/**
 * @swagger
 * tags:
 *   name: Groups
 *   description: Group creation and retrieval
 */

/**
 * @swagger
 * /groups:
 *   post:
 *     summary: Create a new group and auto-assign creator as admin
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Group created and membership assigned
 *       400:
 *         description: Validation or creation error
 *       401:
 *         description: Unauthorized
 */
// Create a new group (and auto-add creator as admin)
router.post("/", requireAuth, createGroup);

/**
 * @swagger
 * /groups:
 *   get:
 *     summary: List all groups the authenticated user owns or is a member of
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of groups
 *       401:
 *         description: Unauthorized
 */
router.get("/", requireAuth, listGroups);

export default router;
