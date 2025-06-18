import { pbAdmin } from "../services/pocketbase.js";

/* ───────────────────────── Create ───────────────────────── */
export async function createGroup(req, res) {
  const { name, description, members = [] } = req.body;
  const isPublic = req.body.isPublic !== false;
  const pbUser = req.pbUser;
  const creatorId = req.user.id;

  if (!pbUser) {
    return res
      .status(500)
      .json({ error: "PocketBase user instance is not available" });
  }

  try {
    // create group
    const group = await pbUser.collection("groups").create({
      name,
      description,
      owner: creatorId,
      isPublic,
      deleted: false // soft-delete flag
    });

    // creator becomes admin
    await pbUser.collection("memberships").create({
      user: creatorId,
      group: group.id,
      role: "admin"
    });

    // add optional members
    const uniqueIds = [...new Set(members)].filter((id) => id !== creatorId);
    for (const uid of uniqueIds) {
      // validate user exists
      await pbUser.collection("users").getOne(uid);
      await pbUser.collection("memberships").create({
        user: uid,
        group: group.id,
        role: "member"
      });
    }

    // fetch members
    const groupMembers = await pbUser
      .collection("memberships")
      .getFullList(200, {
        filter: `group="${group.id}"`,
        expand: "user"
      });

    return res.status(201).json({
      group,
      members: groupMembers.map((m) => ({
        id: m.id,
        userId: m.user,
        role: m.role,
        user: m.expand?.user || null
      }))
    });
  } catch (err) {
    console.error("createGroup error:", err.response?.data || err);
    return res.status(400).json({
      error: err?.response?.data?.message || err.message || "Unknown error"
    });
  }
}

/* ───────────────────────── List mine ─────────────────────── */
export async function listGroups(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    // get membership and owned group IDs
    const myMemberships = await pbUser
      .collection("memberships")
      .getFullList(200, { filter: `user="${userId}"` });

    const ownedGroups = await pbUser
      .collection("groups")
      .getFullList(200, { filter: `owner="${userId}"` });

    const allIds = new Set([
      ...myMemberships.map((m) => m.group),
      ...ownedGroups.map((g) => g.id)
    ]);

    if (allIds.size === 0) {
      return res.json([]);
    }

    const orFilter = [...allIds].map((id) => `id="${id}"`).join(" || ");
    const groups = await pbUser
      .collection("groups")
      .getFullList(200, {
        filter: `(${orFilter}) && deleted=false`,
        sort: "-created"
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
    const groups = await pbAdmin
      .collection("groups")
      .getFullList(200, {
        filter: "isPublic=true && deleted=false",
        sort: "-created"
      });
    return res.json(groups);
  } catch (err) {
    console.error("listPublicGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ───────────────────────── Details ───────────────────────── */
export async function getGroupDetails(req, res) {
  const pbUser = req.pbUser;
  const groupId = req.params.groupId;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);
    if (group.deleted) {
      return res.status(404).json({ error: "Group deleted" });
    }

    // members
    const members = await pbUser
      .collection("memberships")
      .getFullList(200, {
        filter: `group="${groupId}"`,
        expand: "user",
        sort: "created"
      });

    // tasks (exclude soft-deleted)
    const tasks = await pbUser
      .collection("tasks")
      .getFullList(200, {
        filter: `group="${groupId}" && is_deleted=false`,
        sort: "-created"
      });

    return res.json({ group, members, tasks });
  } catch (err) {
    console.error("getGroupDetails error:", err.response?.data || err);
    return res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ───────────────────────── Search ───────────────────────── */
export async function searchGroups(req, res) {
  const keyword = req.query.q?.trim();
  if (!keyword) {
    return res.status(400).json({ error: "Missing query parameter 'q'" });
  }

  try {
    // ignore read-rules for search, exclude soft-deleted groups
    const groups = await pbAdmin
      .collection("groups")
      .getFullList(200, {
        filter: `name~"${keyword}" && deleted=false`,
        sort: "-created"
      });

    return res.json(groups);
  } catch (err) {
    console.error("searchGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message || "Search failed" });
  }
}

/* ───────────────────────── Admin / Member lists ─────────────────── */
export async function listAdminGroups(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const ms = await pbUser
      .collection("memberships")
      .getFullList(200, {
        filter: `user="${userId}" && role="admin"`,
        expand: "group",
        sort: "-created"
      });

    const groups = ms
      .map((m) => m.expand?.group)
      .filter((g) => g && g.deleted !== true);

    return res.json(groups);
  } catch (err) {
    console.error("listAdminGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

export async function listMemberGroups(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  try {
    const ms = await pbUser
      .collection("memberships")
      .getFullList(200, {
        filter: `user="${userId}" && role="member"`,
        expand: "group",
        sort: "-created"
      });

    const groups = ms
      .map((m) => m.expand?.group)
      .filter((g) => g && g.deleted !== true);

    return res.json(groups);
  } catch (err) {
    console.error("listMemberGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ───────────────────────── Update ───────────────────────── */
export async function updateGroup(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const groupId = req.params.groupId;
  const { name, description, isPublic } = req.body || {};

  try {
    const group = await pbUser.collection("groups").getOne(groupId);

    let isAdminMember = false;
    if (group.owner !== userId) {
      const ms = await pbUser
        .collection("memberships")
        .getFirstListItem(`group="${groupId}" && user="${userId}"`);
      isAdminMember = ms?.role === "admin";
      if (!isAdminMember) {
        return res.status(403).json({ error: "Forbidden" });
      }
    }

    const updated = await pbUser.collection("groups").update(groupId, {
      ...(name != null && { name }),
      ...(description != null && { description }),
      ...(isPublic != null && { isPublic })
    });

    return res.json(updated);
  } catch (err) {
    console.error("updateGroup error:", err.response?.data || err);
    return res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ─────────────────────── Soft-delete ─────────────────────── */
export async function deleteGroup(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const groupId = req.params.groupId;

  try {
    // permission check
    const group = await pbUser.collection("groups").getOne(groupId);
    let isAdminMember = false;
    if (group.owner !== userId) {
      const ms = await pbUser
        .collection("memberships")
        .getFirstListItem(`group="${groupId}" && user="${userId}"`);
      isAdminMember = ms?.role === "admin";
      if (!isAdminMember) {
        return res.status(403).json({ error: "Forbidden" });
      }
    }

    // soft-delete group
    await pbUser.collection("groups").update(groupId, { deleted: true });

    // cascade soft-delete tasks
    const tasks = await pbUser
      .collection("tasks")
      .getFullList(200, { filter: `group="${groupId}"` });

    await Promise.all(
      tasks.map((task) =>
        pbUser.collection("tasks").update(task.id, { is_deleted: true })
      )
    );

    return res.json({ ok: true });
  } catch (err) {
    console.error("deleteGroup error:", err.response?.data || err);
    return res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ─────────────────────── Restore soft-deleted group ─────────────────────── */
export async function restoreGroup(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const groupId = req.params.groupId;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);
    if (!group.deleted) {
      return res.status(400).json({ error: "Group is not deleted" });
    }

    // permission: owner or admin
    let isAdminMember = false;
    if (group.owner !== userId) {
      const ms = await pbUser
        .collection("memberships")
        .getFirstListItem(`group="${groupId}" && user="${userId}"`);
      isAdminMember = ms?.role === "admin";
      if (!isAdminMember) {
        return res.status(403).json({ error: "Forbidden" });
      }
    }

    const restored = await pbUser
      .collection("groups")
      .update(groupId, { deleted: false });

    return res.json({ message: "Group restored successfully", group: restored });
  } catch (err) {
    console.error("restoreGroup error:", err.response?.data || err);
    return res.status(err?.status || 400).json({ error: err.message });
  }
}