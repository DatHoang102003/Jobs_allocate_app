import express from 'express';
import { requireAuth } from '../middleware/auth.middleware.js';
import {
  createGroup,
  listGroups,
} from '../controllers/group.controller.js';

const router = express.Router();

// Create a new group (and auto-add creator as admin)
router.post('/', requireAuth, createGroup);

// List all groups the user owns or belongs to
router.get('/', requireAuth, listGroups);

export default router;
