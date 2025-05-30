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
  searchGroups,
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

/* ───────────────────── Get group details ─────────────────────── */
/**
 * @swagger
 * /groups/{groupId}:
 *   get:
 *     summary: Get full details of a specific group
 *     tags: [Groups]
 *     security: [ { bearerAuth: [] } ]
 *     parameters:
 *       - in: path
 *         name: groupId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Group object with members & tasks }
 *       400: { description: Invalid ID }
 *       401: { description: Unauthorized }
 */
router.get("/:groupId", requireAuth, getGroupDetails);

export default router;
