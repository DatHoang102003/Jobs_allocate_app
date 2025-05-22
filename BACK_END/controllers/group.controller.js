import { pbAdmin } from "../services/pocketbase.js";

export async function createGroup(req, res) {
  const { name, description } = req.body;

  const isPublic = req.body.isPublic === false ? false : true;

  const pbUser = req.pbUser;

  try {
    const group = await pbUser.collection("groups").create({
      name,
      description,
      owner: req.user.id,
      isPublic,
    });

    await pbAdmin.collection("memberships").create({
      user: req.user.id,
      group: group.id,
      role: "admin",
    });

    return res.status(201).json(group);
  } catch (err) {
    console.error("createGroup error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

export async function listGroups(req, res) {
  const pbUser = req.pbUser;

  try {
    const mships = await pbUser
      .collection("memberships")
      .getFullList({ filter: `user="${req.user.id}"` });
    const owned = await pbUser
      .collection("groups")
      .getFullList({ filter: `owner="${req.user.id}"` });

    const allIds = Array.from(
      new Set([...mships.map((m) => m.group), ...owned.map((g) => g.id)])
    );

    if (allIds.length === 0) return res.json([]);

    const orFilter = allIds.map((id) => `id="${id}"`).join(" || ");

    const groups = await pbUser
      .collection("groups")
      .getFullList({ filter: `(${orFilter})`, sort: "-created" });

    return res.json(groups);
  } catch (err) {
    console.error("listGroups error:", err.response?.data || err);
    return res.status(400).json({ error: err.message || "Fetch failed" });
  }
}
export async function listPublicGroups(req, res) {
  try {
    const groups = await pbAdmin.collection("groups").getFullList({
      filter: "isPublic=true",
      sort: "-created",
    });
    res.json(groups);
  } catch (err) {
    console.error("listPublicGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

export async function getGroupDetails(req, res) {
  const pbUser = req.pbUser;
  const groupId = req.params.groupId;

  try {
    const group = await pbUser.collection("groups").getOne(groupId);

    const members = await pbUser.collection("memberships").getFullList({
      filter: `group="${groupId}"`,
      expand: "user",
      sort: "created",
    });

    const tasks = await pbUser.collection("tasks").getFullList({
      filter: `group="${groupId}"`,
      sort: "-created",
    });

    res.json({ group, members, tasks });
  } catch (err) {
    console.error("getGroupDetails error:", err.response?.data || err);
    res.status(err?.status || 400).json({ error: err.message });
  }
}
