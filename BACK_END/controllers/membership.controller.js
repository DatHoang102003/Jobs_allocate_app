// src/controllers/membership.controller.js
import { pbAdmin } from "../services/pocketbase.js";

/* ── helper: first-or-null ─────────────────────────────────────────────── */
async function safeFirst(pbUser, filter) {
  try {
    return await pbUser.collection("memberships").getFirstListItem(filter);
  } catch (err) {
    if (err?.status === 404) return null; // simply “not found”
    throw err; // real error
  }
}

/* helper: expand group on a membership record */
async function getMembership(pbUser, membershipId) {
  return await pbUser.collection("memberships").getOne(membershipId, {
    expand: "group",
  });
}

/* ── 1. List ALL memberships across MY groups ──────────────────────────── */
export async function listMyGroupMembers(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const myMships = await pbUser.collection("memberships").getFullList({
      filter: `user="${userId}"`,
    });

    const groupIds = myMships.map((m) => m.group);
    if (groupIds.length === 0) return res.json([]);

    const filter = groupIds.map((id) => `group="${id}"`).join(" || ");
    const members = await pbUser.collection("memberships").getFullList({
      filter,
      expand: "user,group",
      sort: "group",
    });
    res.json(members);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ── 2. List members of ONE group ──────────────────────────────────────── */
export async function listMembersOfGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;

  try {
    const inGroup = await safeFirst(
      pbUser,
      `group="${groupId}" && user="${req.user.id}"`
    );

    // ❤️  NEW behaviour:
    //     not a member → don’t expose the list, but DON’T raise 403 either
    if (!inGroup) return res.json([]);

    const list = await pbUser.collection("memberships").getFullList({
      filter: `group="${groupId}"`,
      expand: "user",
    });
    res.json(list);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ── 3. Leave a group (delete my OWN membership) ───────────────────────── */
export async function leaveGroup(req, res) {
  const pbUser = req.pbUser;
  const { membershipId } = req.params;

  try {
    const ms = await getMembership(pbUser, membershipId);
    if (ms.user !== req.user.id)
      return res.status(403).json({ error: "Forbidden" });

    await pbUser.collection("memberships").delete(membershipId);
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ── 4. Owner / admin removes SOMEONE ELSE ─────────────────────────────── */
export async function removeMember(req, res) {
  const pbUser = req.pbUser;
  const { groupId, membershipId } = req.params;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);
    const callerMs = await safeFirst(
      pbUser,
      `group="${groupId}" && user="${req.user.id}"`
    );

    const isOwner = group.owner === req.user.id;
    const isAdmin = callerMs?.role === "admin";
    if (!isOwner && !isAdmin)
      return res
        .status(403)
        .json({ error: "Only owner or admins can remove members" });

    const targetMs = await pbUser
      .collection("memberships")
      .getOne(membershipId);

    if (targetMs.user === group.owner)
      return res.status(403).json({ error: "Cannot remove the group owner" });

    if (targetMs.role === "admin" && !isOwner)
      return res
        .status(403)
        .json({ error: "Only the owner can remove another admin" });

    await pbAdmin.collection("memberships").delete(membershipId);
    res.json({ ok: true });
  } catch (err) {
    console.error("removeMember error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

/* ── 5. Owner updates a member's role ───────────────────────────────────── */
export async function updateMemberRole(req, res) {
  const pbUser = req.pbUser;
  const { membershipId } = req.params;
  const { role } = req.body; // "member" | "admin"

  if (!["member", "admin"].includes(role))
    return res.status(400).json({ error: "Invalid role value" });

  try {
    const ms = await getMembership(pbUser, membershipId);
    const group = await pbUser.collection("groups").getOne(ms.group);

    if (group.owner !== req.user.id)
      return res.status(403).json({ error: "Only owner can change roles" });

    const updated = await pbAdmin
      .collection("memberships")
      .update(membershipId, { role });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ── 6. Search members INSIDE a group ───────────────────────────────────── */
export async function searchMembersInGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { query } = req.query;

  if (!query) return res.status(400).json({ error: "Missing search query" });

  try {
    const isMember = await safeFirst(
      pbUser,
      `group="${groupId}" && user="${req.user.id}"`
    );
    if (!isMember) return res.json([]); // NEW → empty instead of 403

    const members = await pbUser.collection("memberships").getFullList({
      filter: `group="${groupId}"`,
      expand: "user",
    });

    const q = query.toLowerCase();
    const filtered = members.filter((m) => {
      const user = m.expand?.user;
      return (
        user?.username?.toLowerCase().includes(q) ||
        user?.email?.toLowerCase().includes(q)
      );
    });

    res.json(filtered);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ── 7. “Leave by groupId” convenience route ───────────────────────────── */
export async function leaveGroupByGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;

  try {
    const ms = await safeFirst(
      pbUser,
      `group="${groupId}" && user="${req.user.id}"`
    );
    if (!ms)
      return res
        .status(404)
        .json({ error: "You are not a member of this group" });

    await pbUser.collection("memberships").delete(ms.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}
