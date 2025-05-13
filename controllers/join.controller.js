// controllers/join.controller.js
import { pbAdmin } from "../services/pocketbase.js"; // super-user client

/* =========================
   Send a join request
   POST /groups/:groupId/join
========================= */
export async function sendJoinRequest(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const groupId = req.params.groupId;

  try {
    const jr = await pbUser.collection("join_requests").create({
      user: userId,
      group: groupId,
      status: "pending",
    });
    return res.status(201).json(jr);
  } catch (err) {
    console.error("sendJoinRequest error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   List my join requests
   GET /join_requests
========================= */
export async function listJoinRequests(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const myReqs = await pbUser.collection("join_requests").getFullList({
      filter: `user="${userId}"`,
      sort: "-created",
    });
    return res.json(myReqs);
  } catch (err) {
    console.error("listJoinRequests error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   Approve a join request
   POST /join_requests/:jrId/approve
========================= */
export async function approveJoinRequest(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const jrId = req.params.jrId;

  try {
    // 1) fetch the join request
    const jr = await pbUser.collection("join_requests").getOne(jrId);
    const group = await pbUser.collection("groups").getOne(jr.group);

    if (group.owner !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    // 2) mark approved (owner is allowed by API rule)
    await pbUser
      .collection("join_requests")
      .update(jrId, { status: "approved" });

    // 3) create membership with admin client (bypasses create=false rule)
    await pbAdmin.collection("memberships").create({
      user: jr.user,
      group: jr.group,
      role: "member",
    });

    return res.json({ ok: true });
  } catch (err) {
    console.error("approveJoinRequest error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   Reject a join request
   POST /join_requests/:jrId/reject
========================= */
export async function rejectJoinRequest(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const jrId = req.params.jrId;

  try {
    const jr = await pbUser.collection("join_requests").getOne(jrId);
    const group = await pbUser.collection("groups").getOne(jr.group);

    if (group.owner !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await pbUser
      .collection("join_requests")
      .update(jrId, { status: "rejected" });
    return res.json({ ok: true });
  } catch (err) {
    console.error("rejectJoinRequest error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}
