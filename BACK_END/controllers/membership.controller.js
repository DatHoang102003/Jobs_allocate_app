import { pbAdmin } from "../services/pocketbase.js";

/* Helper: fetch membership & group in one go */
async function getMembership(pbUser, membershipId) {
  const ms = await pbUser.collection("memberships").getOne(membershipId, {
    expand: "group",
  });
  return ms;
}

/* 1. List ALL memberships across my groups */
export async function listMyGroupMembers(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  try {
    // all groups I belong to
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

/* 2. List members of a specific group */
export async function listMembersOfGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  try {
    // ensure requester is in the group
    const inGroup = await pbUser
      .collection("memberships")
      .getFirstListItem(`group="${groupId}" && user="${req.user.id}"`);
    if (!inGroup) return res.status(403).json({ error: "Forbidden" });

    const list = await pbUser.collection("memberships").getFullList({
      filter: `group="${groupId}"`,
      expand: "user",
    });
    res.json(list);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* 3. Leave a group (delete my own membership) */
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

/* 4. Owner removes a member */
export async function removeMember(req, res) {
  const pbUser = req.pbUser;
  const { groupId, membershipId } = req.params;
  try {
    const group = await pbUser.collection("groups").getOne(groupId);
    if (group.owner !== req.user.id)
      return res.status(403).json({ error: "Only owner can remove members" });

    await pbAdmin.collection("memberships").delete(membershipId);
    res.json({ ok: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* 5. Owner updates a member's role */
export async function updateMemberRole(req, res) {
  const pbUser = req.pbUser;
  const { membershipId } = req.params;
  const { role } = req.body; // "member" or "admin"

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
