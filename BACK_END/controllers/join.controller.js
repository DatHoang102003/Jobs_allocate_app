// controllers/join.controller.js
import { pbAdmin } from "../services/pocketbase.js"; // super-user client

/* ====================================================
   POST /groups/:groupId/join  ──  Send a join request
==================================================== */
export async function sendJoinRequest(req, res) {
  const pbUser = req.pbUser; // user-scoped PB client (has auth cookie)
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
    return res.status(err?.status || 500).json({ error: err.message });
  }
}
// export async function listJoinRequests(req, res) {
//   const userId = req.user?.id;
//   if (!userId) return res.status(401).json({ error: "Unauthorized" });

//   try {
//     const result = await pbAdmin.collection("join_requests").getList(1, 200);
//     const myReqs = result.items.filter((r) => r.user === userId);
//     return res.json(myReqs);
//   } catch (err) {
//     console.error("listJoinRequests error:", err.response?.data || err);
//     return res.status(err?.status || 500).json({ error: err.message });
//   }
// }
// controllers/join.controller.js
export async function listJoinRequests(req, res) {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  /* optional pagination (?page & perPage) */
  const page = parseInt(req.query.page, 10) || 1;
  const perPage = parseInt(req.query.perPage, 10) || 500;

  const params = {
    filter: `user="${userId}"`, // only my requests
    sort: "-created", // newest first
    expand: "group,user", // include related data
  };

  try {
    /* paginate if the client asked for it, else full list */
    if (req.query.page || req.query.perPage) {
      const result = await req.pbUser
        .collection("join_requests")
        .getList(page, perPage, params);

      return res.json({
        page: result.page,
        perPage: result.perPage,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        items: result.items,
      });
    }

    /* no pagination → just return everything */
    const items = await req.pbUser
      .collection("join_requests")
      .getFullList(params);

    return res.json(items);
  } catch (err) {
    console.error("listJoinRequests error:", err.response?.data || err);
    /* 400 = PB rule / filter error; everything else 500 */
    const status = err.status && err.status !== 0 ? err.status : 500;
    return res.status(status).json({
      error:
        err.response?.data?.message ||
        err.message ||
        "Failed to list your join requests.",
    });
  }
}

/* ====================================================
   POST /join_requests/:jrId/approve  ──  Owner only
==================================================== */
export async function approveJoinRequest(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const jrId = req.params.jrId;

  try {
    // 1) Fetch join-request and its group
    const jr = await pbUser.collection("join_requests").getOne(jrId);
    const group = await pbUser.collection("groups").getOne(jr.group);

    if (group.owner !== userId)
      return res.status(403).json({ error: "Forbidden" });

    // 2) Mark approved (owner passes Update rule)
    await pbUser
      .collection("join_requests")
      .update(jrId, { status: "approved" });

    // 3) Create membership with admin client (ignores create=false rule)
    await pbAdmin.collection("memberships").create({
      user: jr.user,
      group: jr.group,
      role: "member",
    });

    return res.json({ ok: true });
  } catch (err) {
    console.error("approveJoinRequest error:", err.response?.data || err);
    return res.status(err?.status || 500).json({ error: err.message });
  }
}

/* ====================================================
   POST /join_requests/:jrId/reject  ──  Owner only
==================================================== */
export async function rejectJoinRequest(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const jrId = req.params.jrId;

  try {
    const jr = await pbUser.collection("join_requests").getOne(jrId);
    const group = await pbUser.collection("groups").getOne(jr.group);

    if (group.owner !== userId)
      return res.status(403).json({ error: "Forbidden" });

    await pbUser
      .collection("join_requests")
      .update(jrId, { status: "rejected" });

    return res.json({ ok: true });
  } catch (err) {
    console.error("rejectJoinRequest error:", err.response?.data || err);
    return res.status(err?.status || 500).json({ error: err.message });
  }
}

export async function listGroupJoinRequests(req, res) {
  const { groupId } = req.params; // /groups/:groupId/join_requests
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: "Unauthorized" });

  try {
    // Make sure caller is the owner (or admin) of this group
    const group = await req.pbUser.collection("groups").getOne(groupId);
    if (group.owner !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    /* optional pagination */
    const page = parseInt(req.query.page, 10) || 1;
    const perPage = parseInt(req.query.perPage, 10) || 500;

    const result = await req.pbUser
      .collection("join_requests")
      .getList(page, perPage, {
        filter: `group="${groupId}" && status="pending"`,
        sort: "-created",
        expand: "user",
      });

    return res.json(result.items);
  } catch (err) {
    console.error("listGroupJoinRequests error:", err.response?.data || err);
    const status = err.status && err.status !== 0 ? err.status : 500;
    return res.status(status).json({ error: err.message });
  }
}
