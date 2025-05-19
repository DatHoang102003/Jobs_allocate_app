// routes/join.routes.js
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  sendJoinRequest,
  listJoinRequests,
  approveJoinRequest,
  rejectJoinRequest,
} from "../controllers/join.controller.js";

const router = express.Router();
/**
 * @swagger
 * tags:
 *   name: Join Requests
 *   description: Request to join groups and manage them
 */

/**
 * @swagger
 * /groups/{groupId}/join:
 *   post:
 *     summary: Send a request to join a group
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       201:
 *         description: Join request created
 *       400:
 *         description: Already requested or invalid group
 */

/**
 * @swagger
 * /join_requests:
 *   get:
 *     summary: List all join requests sent by the user
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of your join requests
 */

/**
 * @swagger
 * /join_requests/{jrId}/approve:
 *   post:
 *     summary: Approve a user's join request (group owner only)
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: jrId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Request approved, user added as member
 *       403:
 *         description: Forbidden
 */

/**
 * @swagger
 * /join_requests/{jrId}/reject:
 *   post:
 *     summary: Reject a join request (group owner only)
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: jrId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Request rejected
 *       403:
 *         description: Forbidden
 */

// 1) user sends a request to join a group
router.post("/groups/:groupId/join", requireAuth, sendJoinRequest);

// 2) user lists their own requests
router.get("/join_requests", requireAuth, listJoinRequests);

// 3) group owner approves a request
router.post("/join_requests/:jrId/approve", requireAuth, approveJoinRequest);

// 4) group owner rejects a request
router.post("/join_requests/:jrId/reject", requireAuth, rejectJoinRequest);

export default router;
