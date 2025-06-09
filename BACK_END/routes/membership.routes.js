import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  listMyGroupMembers,
  listMembersOfGroup,
  leaveGroup, // existing: leave by membershipId
  leaveGroupByGroup, // new: leave by groupId
  removeMember,
  updateMemberRole,
  searchMembersInGroup,
} from "../controllers/membership.controller.js";

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Memberships
 *   description: Manage group memberships
 */

/**
 * @swagger
 * /memberships:
 *   get:
 *     summary: List all members in the groups you belong to
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of group members
 */

/**
 * @swagger
 * /groups/{groupId}/members:
 *   get:
 *     summary: List all members of a specific group
 *     tags: [Memberships]
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
 *         description: Group members
 */

/**
 * @swagger
 * /groups/{groupId}/leave:
 *   delete:
 *     summary: Leave a group (remove your own membership by groupId)
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the group to leave
 *     responses:
 *       200:
 *         description: Successfully left the group
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *       404:
 *         description: Not a member of the group
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "You are not a member of this group"
 *       400:
 *         description: Bad request
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 */

/**
 * @swagger
 * /memberships/{membershipId}:
 *   delete:
 *     summary: Leave a group (remove your own membership by membershipId)
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: membershipId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Left group
 */

/**
 * @swagger
 * /groups/{groupId}/members/search:
 *   get:
 *     summary: Search members in a group by name or email
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: query
 *         required: true
 *         schema:
 *           type: string
 *         description: Name or email to search
 *     responses:
 *       200:
 *         description: Matching group members
 *       400:
 *         description: Missing or invalid query
 *       403:
 *         description: Forbidden
 */

/**
 * @swagger
 * /groups/{groupId}/members/{membershipId}:
 *   delete:
 *     summary: Remove a member from a group (owner only)
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: membershipId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Member removed
 *       403:
 *         description: Forbidden
 */

/**
 * @swagger
 * /memberships/{membershipId}/role:
 *   patch:
 *     summary: Update a member's role (admin ↔ member)
 *     tags: [Memberships]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: membershipId
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
 *               role:
 *                 type: string
 *                 enum: [admin, member]
 *     responses:
 *       200:
 *         description: Role updated
 *       400:
 *         description: Invalid role or error
 */

// 1) List all memberships you belong to
router.get("/memberships", requireAuth, listMyGroupMembers);

// 2) List members of a specific group
router.get("/groups/:groupId/members", requireAuth, listMembersOfGroup);

// 3) Leave a group by groupId
router.delete("/groups/:groupId/leave", requireAuth, leaveGroupByGroup);

// 4) Leave a group by membershipId (legacy)
router.delete("/memberships/:membershipId", requireAuth, leaveGroup);

// 5) Search members in a group
router.get(
  "/groups/:groupId/members/search",
  requireAuth,
  searchMembersInGroup
);

// 6) Owner removes a member
router.delete(
  "/groups/:groupId/members/:membershipId",
  requireAuth,
  removeMember
);

// 7) Owner changes a member’s role
router.patch("/memberships/:membershipId/role", requireAuth, updateMemberRole);

export default router;
