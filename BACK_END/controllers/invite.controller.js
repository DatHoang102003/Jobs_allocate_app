// controllers/invite.controller.js
import { pbAdmin } from "../services/pocketbase.js"; // super-user client

/* =========================================================
   POST /groups/:groupId/invite  ── Admin invites a user
========================================================= */
export async function inviteUserToGroup(req, res) {
  const pbUser = req.pbUser;
  const inviterId = req.user.id;
  const groupId = req.params.groupId;
  const { userId } = req.body;

  if (!userId) return res.status(400).json({ error: "Missing userId in body" });

  try {
    const group = await pbUser.collection("groups").getOne(groupId);

    if (group.owner !== inviterId)
      return res.status(403).json({ error: "Only group owner can invite" });

    const invite = await pbUser.collection("invite_requests").create({
      inviter: inviterId,
      invitee: userId,
      group: groupId,
      status: "pending",
    });

    return res.status(201).json(invite);
  } catch (err) {
    console.error("sendInviteRequest error:", err.response?.data || err);
    return res.status(err?.status || 500).json({ error: err.message });
  }
}

/* ============================================================
   GET /invite_requests ── List all invites sent to the user
============================================================ */
export async function listGroupInvites(req, res) {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  const page = parseInt(req.query.page, 10) || 1;
  const perPage = parseInt(req.query.perPage, 10) || 500;

  const params = {
    filter: `invitee="${userId}"`,
    sort: "-created",
    expand: "group,inviter",
  };

  try {
    if (req.query.page || req.query.perPage) {
      const result = await req.pbUser
        .collection("invite_requests")
        .getList(page, perPage, params);

      return res.json({
        page: result.page,
        perPage: result.perPage,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        items: result.items,
      });
    }

    const items = await req.pbUser
      .collection("invite_requests")
      .getFullList(params);

    return res.json(items);
  } catch (err) {
    console.error("listMyInvites error:", err.response?.data || err);
    const status = err.status && err.status !== 0 ? err.status : 500;
    return res.status(status).json({
      error: err.response?.data?.message || err.message || "Failed to list invites.",
    });
  }
}

/* ============================================================
   POST /invite_requests/:inviteId/accept ── Accept invitation
============================================================ */
export async function acceptGroupInvite(req, res) {
  const pbUser = req.pbUser;
  const inviteeId = req.user.id;
  const inviteId = req.params.inviteId;

  try {
    const invite = await pbUser.collection("invite_requests").getOne(inviteId);

    if (invite.invitee !== inviteeId)
      return res.status(403).json({ error: "Forbidden" });

    await pbUser.collection("invite_requests").update(inviteId, {
      status: "accepted",
    });

    await pbAdmin.collection("memberships").create({
      user: inviteeId,
      group: invite.group,
      role: "member",
    });

    return res.json({ ok: true });
  } catch (err) {
    console.error("acceptInvite error:", err.response?.data || err);
    return res.status(err?.status || 500).json({ error: err.message });
  }
}

/* ============================================================
   POST /invite_requests/:inviteId/reject ── Reject invitation
============================================================ */
export async function rejectGroupInvite(req, res) {
  const pbUser = req.pbUser;
  const inviteeId = req.user.id;
  const inviteId = req.params.inviteId;

  try {
    const invite = await pbUser.collection("invite_requests").getOne(inviteId);

    if (invite.invitee !== inviteeId)
      return res.status(403).json({ error: "Forbidden" });

    await pbUser.collection("invite_requests").update(inviteId, {
      status: "rejected",
    });

    return res.json({ ok: true });
  } catch (err) {
    console.error("rejectInvite error:", err.response?.data || err);
    return res.status(err?.status || 500).json({ error: err.message });
  }
}
