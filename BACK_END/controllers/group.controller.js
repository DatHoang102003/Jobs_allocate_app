// controllers/group.controller.js
import { pbAdmin } from "../services/pocketbase.js";

/* ───────────────────────── Create ───────────────────────── */
export async function createGroup(req, res) {
  const { name, description, members = [] } = req.body;
  const isPublic  = req.body.isPublic === false ? false : true;
  const pbUser    = req.pbUser;
  const creatorId = req.user.id;

  if (!pbUser) {
    return res
      .status(500)
      .json({ error: "PocketBase user instance is not available" });
  }

  try {
    const group = await pbUser.collection("groups").create({
      name,
      description,
      owner: creatorId,
      isPublic,
      deleted: false, // ← soft-delete flag (default false)
    });

    // creator becomes admin
    await pbUser.collection("memberships").create({
      user:  creatorId,
      group: group.id,
      role:  "admin",
    });

    // add optional members
    const uniqueIds = [...new Set(members)].filter((id) => id !== creatorId);
    for (const uid of uniqueIds) {
      await pbUser.collection("users").getOne(uid);   // throws if bad
      await pbUser.collection("memberships").create({
        user:  uid,
        group: group.id,
        role:  "member",
      });
    }

    // fetch members (expanded)
    const groupMembers = await pbUser.collection("memberships").getFullList({
      filter: `group="${group.id}"`,
      expand: "user",
    });

    return res.status(201).json({
      group,
      members: groupMembers.map((m) => ({
        id:     m.id,
        userId: m.user,
        role:   m.role,
        user:   m.expand?.user ?? null,
      })),
    });
  } catch (err) {
    console.error("createGroup error:", err.response?.data || err);
    return res.status(400).json({
      error: err?.response?.data?.message || err.message || "Unknown error",
    });
  }
}

/* ───────────────────────── List mine ─────────────────────── */
export async function listGroups(req, res) {
  const pbUser = req.pbUser;

  try {
    const myMemberships = await pbUser.collection("memberships").getFullList({
      filter: `user="${req.user.id}"`,
    });
    const ownedGroups   = await pbUser.collection("groups").getFullList({
      filter: `owner="${req.user.id}"`,
    });

    const allIds = new Set([
      ...myMemberships.map((m) => m.group),
      ...ownedGroups.map((g) => g.id),
    ]);

    if (allIds.size === 0) return res.json([]);

    const orFilter = [...allIds].map((id) => `id="${id}"`).join(" || ");

    const groups = await pbUser.collection("groups").getFullList({
      filter: `(${orFilter}) && deleted=false`,
      sort:   "-created",
    });

    return res.json(groups);
  } catch (err) {
    console.error("listGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message || "Fetch failed" });
  }
}

/* ─────────────────────── Public browse ───────────────────── */
export async function listPublicGroups(_req, res) {
  try {
    const groups = await pbAdmin.collection("groups").getFullList({
      filter: "isPublic=true && deleted=false",
      sort:   "-created",
    });
    res.json(groups);
  } catch (err) {
    console.error("listPublicGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

/* ───────────────────────── Details ───────────────────────── */
export async function getGroupDetails(req, res) {
  const pbUser  = req.pbUser;
  const groupId = req.params.groupId;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);
    if (group.deleted) return res.status(404).json({ error: "Group deleted" });

    const members = await pbUser.collection("memberships").getFullList({
      filter: `group="${groupId}"`,
      expand: "user",
      sort:   "created",
    });

    const tasks = await pbUser.collection("tasks").getFullList({
      filter: `group="${groupId}"`,
      sort:   "-created",
    });

    res.json({ group, members, tasks });
  } catch (err) {
    console.error("getGroupDetails error:", err.response?.data || err);
    res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ───────────────────────── Search ───────────────────────── */
export async function searchGroups(req, res) {
  const pbUser  = req.pbUser;
  const keyword = req.query.q?.trim();
  if (!keyword) {
    return res.status(400).json({ error: "Missing query parameter 'q'" });
  }

  try {
    const groups = await pbUser.collection("groups").getFullList({
      filter: `name~"${keyword}" && deleted=false`,
      sort:   "-created",
    });
    res.json(groups);
  } catch (err) {
    console.error("searchGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message || "Search failed" });
  }
}

/* ───────────────── Admin / Member lists ─────────────────── */
export async function listAdminGroups(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const ms = await pbUser.collection("memberships").getFullList({
      filter: `user="${userId}" && role="admin"`,
      expand: "group",
      sort:   "-created",
    });
    res.json(ms.map((m) => m.expand?.group).filter(Boolean));
  } catch (err) {
    console.error("listAdminGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

export async function listMemberGroups(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const ms = await pbUser.collection("memberships").getFullList({
      filter: `user="${userId}" && role="member"`,
      expand: "group",
      sort:   "-created",
    });
    res.json(ms.map((m) => m.expand?.group).filter(Boolean));
  } catch (err) {
    console.error("listMemberGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

/* ───────────────────────── Update ───────────────────────── */
export async function updateGroup(req, res) {
  const pbUser  = req.pbUser;
  const userId  = req.user.id;
  const groupId = req.params.groupId;
  const { name, description, isPublic, deleted } = req.body || {};

  try {
    const group = await pbUser.collection("groups").getOne(groupId);

    let isAdminMember = false;
    if (group.owner !== userId) {
      const ms = await pbUser
        .collection("memberships")
        .getFirstListItem(`group="${groupId}" && user="${userId}"`);
      isAdminMember = ms?.role === "admin";
      if (!isAdminMember) return res.status(403).json({ error: "Forbidden" });
    }

    const updated = await pbUser.collection("groups").update(groupId, {
      ...(name        != null && { name }),
      ...(description != null && { description }),
      ...(isPublic    != null && { isPublic }),
      ...(deleted     != null && { deleted }),
    });

    res.json(updated);
  } catch (err) {
    console.error("updateGroup error:", err.response?.data || err);
    res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ─────────────────────── Soft-delete ─────────────────────── */
export async function deleteGroup(req, res) {
  const pbUser  = req.pbUser;
  const userId  = req.user.id;
  const groupId = req.params.groupId;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);

    let isAdminMember = false;
    if (group.owner !== userId) {
      const ms = await pbUser
        .collection("memberships")
        .getFirstListItem(`group="${groupId}" && user="${userId}"`);
      isAdminMember = ms?.role === "admin";
      if (!isAdminMember) return res.status(403).json({ error: "Forbidden" });
    }

    await pbUser.collection("groups").update(groupId, { deleted: true });
    res.json({ ok: true });
  } catch (err) {
    console.error("deleteGroup error:", err.response?.data || err);
    res.status(err?.status || 400).json({ error: err.message });
  }
}
