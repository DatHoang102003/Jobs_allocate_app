import express from "express";
import { requireAuth } from "../middleware/auth.middleware.js";
import {
  getMyProfile,
  updateMyProfile,
} from "../controllers/user.controller.js";

const router = express.Router();
/**
 * @swagger
 * tags:
 *   name: User
 *   description: User profile actions
 */

/**
 * @swagger
 * /me:
 *   get:
 *     summary: Get current authenticated user's profile
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Returns current user's data
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /me:
 *   patch:
 *     summary: Update current user's profile (name, email, password, avatar)
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: false
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *               passwordConfirm:
 *                 type: string
 *               avatar:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: User updated successfully
 *       400:
 *         description: Validation or upload error
 *       401:
 *         description: Unauthorized
 */

router.get("/me", requireAuth, getMyProfile);
router.patch("/me", requireAuth, updateMyProfile);

export default router;
