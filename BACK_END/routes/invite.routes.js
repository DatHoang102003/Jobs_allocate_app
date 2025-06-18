import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";

import {
  inviteUserToGroup,
  listGroupInvites,
  acceptGroupInvite,
  rejectGroupInvite,
} from "../controllers/invite.controller.js";
const router = express.Router();
/**
 * @swagger
 * /groups/{groupId}/invite:
 *   post:
 *     summary: Group owner invites a user to join the group
 *     tags: [Group Invites]
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
 *             properties:
 *               userId:
 *                 type: string
 *     responses:
 *       201:
 *         description: Invite sent
 *       403:
 *         description: Only group owner can send invites
 */
router.post("/groups/:groupId/invite", requireAuth, inviteUserToGroup);
/**
 * @swagger
 * /group_invites:
 *   get:
 *     summary: List all group invites for the logged-in user
 *     tags: [Group Invites]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of group invites
 */
router.get("/group_invites", requireAuth, listGroupInvites);
/**
 * @swagger
 * /group_invites/{inviteId}/accept:
 *   post:
 *     summary: Accept an invitation to join a group
 *     tags: [Group Invites]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: inviteId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Successfully joined group
 */
router.post("/group_invites/:inviteId/accept", requireAuth, acceptGroupInvite);
/**
 * @swagger
 * /group_invites/{inviteId}/reject:
 *   post:
 *     summary: Reject an invitation to join a group
 *     tags: [Group Invites]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: inviteId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Invite rejected
 */
router.post("/group_invites/:inviteId/reject", requireAuth, rejectGroupInvite);
export default router;
