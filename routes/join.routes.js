// routes/join.routes.js
import express from 'express';
import { requireAuth } from '../middleware/auth.middleware.js';
import {
  sendJoinRequest,
  listJoinRequests,
  approveJoinRequest,
  rejectJoinRequest,
} from '../controllers/join.controller.js';

const router = express.Router();

// 1) user sends a request to join a group
router.post('/groups/:groupId/join', requireAuth, sendJoinRequest);

// 2) user lists their own requests
router.get('/join_requests', requireAuth, listJoinRequests);

// 3) group owner approves a request
router.post('/join_requests/:jrId/approve', requireAuth, approveJoinRequest);

// 4) group owner rejects a request
router.post('/join_requests/:jrId/reject', requireAuth, rejectJoinRequest);

export default router;
