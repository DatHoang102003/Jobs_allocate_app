// controllers/group.controller.js
import pb from "../services/pocketbase.js";

export async function createGroup(req, res) {
  const { name, description } = req.body;
  try {
    // 1) Create group
    const group = await pb.collection("groups").create({
      name,
      description,
      owner: req.user.id,
    });

    // 2) Auto-add membership (role=admin)
    await pb.collection("memberships").create({
      user: req.user.id,
      group: group.id,
      role: "admin",
      // joinedAt is auto-filled if using Autodate
    });

    res.status(201).json(group);
  } catch (err) {
    // Log everything we’ve got
    console.error("❌ createGroup full error:", err);
    console.error("❌ createGroup error.data:", err.data);
    console.error("❌ createGroup error.message:", err.message);
    return res.status(400).json({ error: err.message || "Unknown error" });
  }
}

export async function listGroups(req, res) {
  try {
    // Fetch all memberships for this user
    const mships = await pb
      .collection("memberships")
      .getFullList({ filter: `user="${req.user.id}"` });

    const groupIds = mships.map((m) => m.group);

    // Also include groups the user owns
    const owned = await pb
      .collection("groups")
      .getFullList({ filter: `owner="${req.user.id}"` });

    const ownedIds = owned.map((g) => g.id);

    const allIds = Array.from(new Set([...groupIds, ...ownedIds]));

    // Finally fetch group records
    const groups = await pb.collection("groups").getFullList({
      filter: `id in (${allIds.map((id) => `"${id}"`).join(",")})`,
    });

    res.json(groups);
  } catch (err) {
    console.error("listGroups error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}
