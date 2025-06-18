import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  createGroup,
  listGroups,
  listPublicGroups,
  listAdminGroups,
  listMemberGroups,
  getGroupDetails,
  updateGroup,
  deleteGroup,
  searchGroups,
  restoreGroup,
} from "../controllers/group.controller.js";

const router = express.Router();

/* ───────────────────────── Swagger Tag ───────────────────────── */
/**
 * @swagger
 * tags:
 *   name: Groups
 *   description: Group creation and management
 */

/* ──────────────────────── Create a group ─────────────────────── */
/**
 * @swagger
 * /groups:
 *   post:
 *     summary: Create a new group (creator becomes admin)
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
 *               isPublic:
 *                 type: boolean
 *                 description: Visibility flag (default true)
 *     responses:
 *       201:
 *         description: Group created successfully
 *       400:
 *         description: Validation error
 *       401:
 *         description: Unauthorized
 */
router.post("/", requireAuth, createGroup);

/* ─────────────────────── List my groups ──────────────────────── */
/**
 * @swagger
 * /groups:
 *   get:
 *     summary: List groups the user owns or belongs to
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of groups (excluding soft-deleted)
 *       401:
 *         description: Unauthorized
 */
router.get("/", requireAuth, listGroups);

/* ─────────────────────── Public groups (/explore) ────────────── */
/**
 * @swagger
 * /groups/explore:
 *   get:
 *     summary: Browse public groups
 *     tags: [Groups]
 *     responses:
 *       200:
 *         description: Array of public groups (excluding soft-deleted)
 */
router.get("/explore", listPublicGroups);

/* ─────────────────────── Search my groups ────────────────────── */
/**
 * @swagger
 * /groups/search:
 *   get:
 *     summary: Search the user's groups by name
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: Keyword to search in group names
 *     responses:
 *       200:
 *         description: Matching groups
 *       400:
 *         description: Missing or invalid query parameter
 *       401:
 *         description: Unauthorized
 */
router.get("/search", requireAuth, searchGroups);

/* ─────────── Groups where I'm admin/member ───────────── */
/**
 * @swagger
 * /groups/admin:
 *   get:
 *     summary: List groups where the user is an admin
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Groups administered by the user
 *       401:
 *         description: Unauthorized
 */
router.get("/admin", requireAuth, listAdminGroups);

/**
 * @swagger
 * /groups/member:
 *   get:
 *     summary: List groups where the user is a member
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Groups the user belongs to as member
 *       401:
 *         description: Unauthorized
 */
router.get("/member", requireAuth, listMemberGroups);

/* ───────── Details / Update / Soft-delete / Restore ───────── */
/**
 * @swagger
 * /groups/{groupId}:
 *   get:
 *     summary: Get full details of a group
 *     tags: [Groups]
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
 *         description: Group object with members & tasks
 *       404:
 *         description: Group deleted or not found
 *
 *   patch:
 *     summary: Update a group (owner or admin)
 *     tags: [Groups]
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
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               isPublic:
 *                 type: boolean
 *               deleted:
 *                 type: boolean
 *                 description: Set to true to soft-delete; false to restore
 *     responses:
 *       200:
 *         description: Updated group object
 *       400:
 *         description: Validation error or malformed request
 *       403:
 *         description: Forbidden (only owner or admin)
 *
 *   delete:
 *     summary: Soft-delete a group (sets deleted=true)
 *     tags: [Groups]
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
 *         description: Group marked as deleted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *       403:
 *         description: Forbidden (only owner or admin)
 *       404:
 *         description: Group not found or already deleted
 */
router.get("/:groupId", requireAuth, getGroupDetails);
router.patch("/:groupId", requireAuth, updateGroup);
router.delete("/:groupId", requireAuth, deleteGroup);

/**
 * @swagger
 * /groups/{groupId}/restore:
 *   patch:
 *     summary: Restore a previously soft-deleted group
 *     tags: [Groups]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID of the group to restore
 *     responses:
 *       200:
 *         description: Group restored successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Group restored successfully
 *                 group:
 *                   type: object
 *       403:
 *         description: Forbidden (only owner or admin)
 *       404:
 *         description: Group not found or not deleted
 */
router.patch("/:groupId/restore", requireAuth, restoreGroup);

export default router;
