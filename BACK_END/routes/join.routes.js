// routes/join.routes.js
import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  sendJoinRequest,
  listJoinRequests, // current-user’s own requests
  listGroupJoinRequests, // owner/admin view for one group
  approveJoinRequest,
  rejectJoinRequest,
} from "../controllers/join.controller.js";

const router = express.Router();

/* ──────────────────────────────────────────────────────────
   Swagger – shared metadata
────────────────────────────────────────────────────────── */
/**
 * @swagger
 * tags:
 *   - name: Join Requests
 *     description: Send, list, and manage group-join requests
 */

/* -----------------------------------------------------------
   1) POST /groups/{groupId}/join  – member sends a request
----------------------------------------------------------- */
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
router.post("/groups/:groupId/join", requireAuth, sendJoinRequest);

/* -----------------------------------------------------------
   2) GET /join_requests  – current user lists *their* requests
----------------------------------------------------------- */
/**
 * @swagger
 * /join_requests:
 *   get:
 *     summary: List all join requests sent by the authenticated user
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of the user’s join-request records
 */
router.get("/join_requests", requireAuth, listJoinRequests);

/* -----------------------------------------------------------
   3) GET /groups/{groupId}/join_requests  – owner/admin view
----------------------------------------------------------- */
/**
 * @swagger
 * /groups/{groupId}/join_requests:
 *   get:
 *     summary: List pending join requests for a specific group
 *     description: >
 *       Returns **all pending** requests belonging to the specified group.
 *       Caller must be the **owner** (or an admin, if your controller
 *       extends the check). Requires a Bearer token.
 *     tags: [Join Requests]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: perPage
 *         schema:
 *           type: integer
 *           default: 500
 *     responses:
 *       200:
 *         description: Array of pending join-request records
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Forbidden (caller isn’t owner/admin)
 */
router.get(
  "/groups/:groupId/join_requests",
  requireAuth,
  listGroupJoinRequests
);

/* -----------------------------------------------------------
   4) POST /join_requests/{jrId}/approve  – owner action
----------------------------------------------------------- */
/**
 * @swagger
 * /join_requests/{jrId}/approve:
 *   post:
 *     summary: Approve a join request (group owner/admin only)
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
 *         description: Request approved; user added to the group
 *       403:
 *         description: Forbidden
 */
router.post("/join_requests/:jrId/approve", requireAuth, approveJoinRequest);

/* -----------------------------------------------------------
   5) POST /join_requests/{jrId}/reject  – owner action
----------------------------------------------------------- */
/**
 * @swagger
 * /join_requests/{jrId}/reject:
 *   post:
 *     summary: Reject a join request (group owner/admin only)
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
router.post("/join_requests/:jrId/reject", requireAuth, rejectJoinRequest);

export default router;
