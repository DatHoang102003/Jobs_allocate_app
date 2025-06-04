// routes/groups.routes.js
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
 *   description: Group creation and retrieval
 */

/* ──────────────────────── Create a group ─────────────────────── */
/**
 * @swagger
 * /groups:
 *   post:
 *     summary: Create a new group (creator becomes admin)
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name]
 *             properties:
 *               name:        { type: string }
 *               description: { type: string }
 *               isPublic:    { type: boolean }
 *     responses:
 *       201: { description: Group created }
 *       400: { description: Validation error }
 *       401: { description: Unauthorized }
 */
router.post("/", requireAuth, createGroup);

/* ─────────────────────── List my groups ──────────────────────── */
/**
 * @swagger
 * /groups:
 *   get:
 *     summary: List groups the user owns or belongs to
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     responses:
 *       200: { description: Array of groups }
 *       401: { description: Unauthorized }
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
 *       200: { description: Array of public groups }
 */
router.get("/explore", listPublicGroups);

/* ─────────────────────── Search my groups ────────────────────── */
/**
 * @swagger
 * /groups/search:
 *   get:
 *     summary: Search a user's groups by name
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema: { type: string }
 *         description: Keyword to search in group names
 *     responses:
 *       200: { description: Matching groups }
 *       400: { description: Missing query }
 *       401: { description: Unauthorized }
 */
router.get("/search", requireAuth, searchGroups);

/* ─────────────────── NEW: groups where I'm admin ─────────────── */
/**
 * @swagger
 * /groups/admin:
 *   get:
 *     summary: List groups where the user is an admin
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     responses:
 *       200: { description: Groups the user administers }
 *       401: { description: Unauthorized }
 */
router.get("/admin", requireAuth, listAdminGroups);

/* ─────────────────── NEW: groups where I'm member ────────────── */
/**
 * @swagger
 * /groups/member:
 *   get:
 *     summary: List groups where the user is a regular member
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     responses:
 *       200: { description: Groups the user belongs to as member }
 *       401: { description: Unauthorized }
 */
router.get("/member", requireAuth, listMemberGroups);

/* ───────── Details / Update / Delete ───────── */
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
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 group:
 *                   type: object
 *                   description: The group record (including all fields)
 *                 members:
 *                   type: array
 *                   items:
 *                     type: object
 *                     description: Expanded membership objects (role + user info)
 *                 tasks:
 *                   type: array
 *                   items:
 *                     type: object
 *                     description: Task objects belonging to this group
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
 *                 description: New group name
 *               description:
 *                 type: string
 *                 description: New group description
 *               isPublic:
 *                 type: boolean
 *                 description: Toggle group visibility (true = public, false = private)
 *               deleted:
 *                 type: boolean
 *                 description: Set to true to soft-delete; set to false to restore
 *     responses:
 *       200:
 *         description: Updated group object
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 collectionId:
 *                   type: string
 *                 collectionName:
 *                   type: string
 *                 id:
 *                   type: string
 *                 created:
 *                   type: string
 *                   format: date-time
 *                 updated:
 *                   type: string
 *                   format: date-time
 *                 name:
 *                   type: string
 *                 description:
 *                   type: string
 *                 owner:
 *                   type: string
 *                 isPublic:
 *                   type: boolean
 *                 deleted:
 *                   type: boolean
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
/* ─────────────────────── Restore a soft-deleted group ─────────────────────── */
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
 *         description: Group successfully restored
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Group restored
 *       403:
 *         description: Forbidden (only owner or admin can restore)
 *       404:
 *         description: Group not found or not deleted
 */
router.patch("/:groupId/restore", requireAuth, restoreGroup);

router.get("/:groupId", requireAuth, getGroupDetails);
router.patch("/:groupId", requireAuth, updateGroup);
router.delete("/:groupId", requireAuth, deleteGroup);

export default router;
