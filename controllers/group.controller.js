// controllers/group.controller.js
import { pbAdmin } from "../services/pocketbase.js";

export async function createGroup(req, res) {
  const { name, description } = req.body;
  const pbUser = req.pbUser;

  try {
    // 1) Create group as the logged-in user
    const group = await pbUser.collection("groups").create({
      name,
      description,
      owner: req.user.id,
    });

    // 2) Auto-add membership (role=admin) using the admin client
    await pbAdmin.collection("memberships").create({
      user: req.user.id,
      group: group.id,
      role: "admin",
    });

    return res.status(201).json(group);
  } catch (err) {
    console.error("❌ createGroup full error:", err);
    console.error("❌ createGroup error.data:", err.response?.data);
    console.error("❌ createGroup error.message:", err.message);
    return res.status(400).json({ error: err.message || "Unknown error" });
  }
}

export async function listGroups(req, res) {
  const pbUser = req.pbUser;

  try {
    /* 1) memberships + owned groups */
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

    /* 2) Build OR filter instead of ?= */
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
