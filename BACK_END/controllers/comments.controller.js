/*───────────────────────── Comment Controller ─────────────────────────*/

// Helper to fetch task and verify it exists
async function getTaskOrFail(pbUser, taskId) {
  const task = await pbUser.collection("tasks").getOne(taskId);
  if (!task || task.is_deleted) {
    const error = new Error("Task not found");
    error.status = 404;
    throw error;
  }
  return task;
}

// Helper to check user access to a task
function ensureTaskAccess(task, userId) {
  const isCreator = task.createdBy === userId;
  const isAssignee = Array.isArray(task.assignee) && task.assignee.includes(userId);
  if (!isCreator && !isAssignee) {
    const error = new Error("Forbidden");
    error.status = 403;
    throw error;
  }
}

// Create Comment
export async function createComment(req, res) {
  const { pbUser } = req;
  const { taskId } = req.params;
  const { contents, attachments = [] } = req.body;
  const userId = req.user.id;

  if (!pbUser) {
    return res.status(500).json({ error: "PocketBase user instance is not available" });
  }

  try {
    const task = await getTaskOrFail(pbUser, taskId);
    ensureTaskAccess(task, userId);

    const payload = {
      task: taskId,
      author: userId,
      contents,
      attachments: Array.isArray(attachments) ? attachments : [attachments],
    };

    const comment = await pbUser.collection("comments").create(payload);
    return res.status(201).json(comment);
  } catch (err) {
    console.error("createComment error:", err);
    const status = err.status || 400;
    return res.status(status).json({ error: err.message });
  }
}

// List Comments
export async function listComments(req, res) {
  const { pbUser } = req;
  const { taskId } = req.params;
  const page = parseInt(req.query.page, 10);
  const perPage = parseInt(req.query.perPage, 10);

  try {
    const task = await getTaskOrFail(pbUser, taskId);
    ensureTaskAccess(task, req.user.id);

    // Only fetch non-deleted comments
    const filter = `task="${taskId}" && is_deleted=false`;

    if (!isNaN(page) && !isNaN(perPage)) {
      const result = await pbUser.collection("comments").getList(page, perPage, {
        filter,
        sort: "-created",
        expand: "author",
      });
      return res.json({
        page: result.page,
        perPage: result.perPage,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        items: result.items,
      });
    }

    const items = await pbUser.collection("comments").getFullList(200, {
      filter,
      sort: "-created",
      expand: "author",
    });
    return res.json(items);
  } catch (err) {
    console.error("listComments error:", err);
    const status = err.status || 400;
    return res.status(status).json({ error: err.message });
  }
}

// Update Comment
export async function updateComment(req, res) {
  const { pbUser } = req;
  const { taskId, commentId } = req.params;
  const { contents, attachments } = req.body;
  const userId = req.user.id;

  try {
    const task = await getTaskOrFail(pbUser, taskId);
    ensureTaskAccess(task, userId);

    const comment = await pbUser.collection("comments").getOne(commentId);
    if (!comment || comment.is_deleted || comment.task !== taskId) {
      return res.status(404).json({ error: "Comment not found" });
    }
    if (comment.author !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const payload = {};
    if (contents !== undefined) payload.contents = contents;
    if (attachments !== undefined) {
      payload.attachments = Array.isArray(attachments) ? attachments : [attachments];
    }

    if (Object.keys(payload).length === 0) {
      return res.status(400).json({ error: "No fields to update" });
    }

    const updated = await pbUser.collection("comments").update(commentId, payload);
    return res.json(updated);
  } catch (err) {
    console.error("updateComment error:", err);
    const status = err.status || 400;
    return res.status(status).json({ error: err.message });
  }
}

// Delete Comment
export async function deleteComment(req, res) {
  const { pbUser } = req;
  const { taskId, commentId } = req.params;
  const userId = req.user.id;

  try {
    const task = await getTaskOrFail(pbUser, taskId);
    ensureTaskAccess(task, userId);

    const comment = await pbUser.collection("comments").getOne(commentId);
    if (!comment || comment.is_deleted || comment.task !== taskId) {
      return res.status(404).json({ error: "Comment not found" });
    }

    const isAuthor = comment.author === userId;
    const isCreator = task.createdBy === userId;
    if (!isAuthor && !isCreator) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await pbUser.collection("comments").update(commentId, { is_deleted: true });
    return res.json({ ok: true });
  } catch (err) {
    console.error("deleteComment error:", err);
    const status = err.status || 400;
    return res.status(status).json({ error: err.message });
  }
}
