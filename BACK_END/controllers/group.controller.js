import { pbAdmin } from "../services/pocketbase.js";

export async function createGroup(req, res) {
  const { name, description, members = [] } = req.body;
  const isPublic = req.body.isPublic === false ? false : true;

  const pbUser = req.pbUser;
  const creatorId = req.user.id;

  if (!pbUser) {
    return res.status(500).json({ error: "PocketBase user instance is not available" });
  }

  try {
    // Tạo nhóm
    const group = await pbUser.collection("groups").create({
      name,
      description,
      owner: creatorId,
      isPublic,
    });

    // Thêm creator vào memberships với vai trò admin
    await pbUser.collection("memberships").create({
      user: creatorId,
      group: group.id,
      role: "admin",
    });

    // Thêm các thành viên khác (nếu có)
    const uniqueMemberIds = [...new Set(members)].filter((id) => id !== creatorId);

    for (const userId of uniqueMemberIds) {
      // Kiểm tra người dùng tồn tại
      await pbUser.collection("users").getOne(userId); // sẽ throw nếu không hợp lệ
      await pbUser.collection("memberships").create({
        user: userId,
        group: group.id,
        role: "member",
      });
    }

    // Lấy danh sách thành viên (gồm cả thông tin mở rộng của user)
    const groupMembers = await pbUser.collection("memberships").getFullList({
      filter: `group="${group.id}"`,
      expand: "user",
    });

    // Trả về group cùng với danh sách thành viên
    return res.status(201).json({
      group,
      members: groupMembers.map(member => ({
        id: member.id,
        userId: member.user,
        role: member.role,
        user: member.expand?.user || null
      }))
    });

  } catch (err) {
    console.error("createGroup error:", err.response?.data || err);
    return res.status(400).json({
      error: err?.response?.data?.message || err.message || "Unknown error"
    });
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
