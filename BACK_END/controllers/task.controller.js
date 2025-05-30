
export async function createTask(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { title, description, assignee, deadline } = req.body;

  try {
    const task = await pbUser.collection("tasks").create({
      group: groupId,
      title,
      description,
      assignee, // may be undefined
      status: "todo",
      deadline, // ISO or omit
      createdBy: req.user.id,
    });
    return res.status(201).json(task);
  } catch (err) {
    console.error("createTask error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   List (with filters / pagination)
   GET /groups/:groupId/tasks
========================= */
export async function listTasksByGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { status, assignee, page, perPage } = req.query;

  try {
    const filters = [`group="${groupId}"`];
    if (status) filters.push(`status="${status}"`);
    if (assignee) filters.push(`assignee="${assignee}"`);

    const filterString = filters.join(" && ");

    if (page && perPage) {
      const p = parseInt(page, 10) || 1;
      const pp = parseInt(perPage, 10) || 10;

      const result = await pbUser.collection("tasks").getList(p, pp, {
        filter: filterString,
        sort: "-created",
      });

      return res.json({
        page: result.page,
        perPage: result.perPage,
        totalItems: result.totalItems,
        totalPages: result.totalPages,
        items: result.items,
      });
    }

    // No pagination
    const items = await pbUser.collection("tasks").getFullList({
      filter: filterString,
      sort: "-created",
    });
    return res.json(items);
  } catch (err) {
    console.error("listTasksByGroup error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   Update task status
   PATCH /tasks/:taskId/status
========================= */
export async function updateTaskStatus(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;
  const { status } = req.body; // "todo" | "doing" | "done"

  try {
    const updated = await pbUser.collection("tasks").update(taskId, { status });
    return res.json(updated);
  } catch (err) {
    console.error("updateTaskStatus error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* =========================
   Delete a task
   DELETE /tasks/:taskId
========================= */
export async function deleteTask(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;

  try {
    await pbUser.collection("tasks").delete(taskId);
    return res.json({ ok: true });
  } catch (err) {
    console.error("deleteTask error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}
/**
 * GET /groups/:groupId/tasks/count
 * Count number of tasks in a group (optionally filtered by status)
 */
export async function countTasksByGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { status } = req.query;

  try {
    const filters = [`group="${groupId}"`];
    if (status) filters.push(`status="${status}"`);

    const filterString = filters.join(" && ");

    const tasks = await pbUser.collection("tasks").getFullList({
      filter: filterString,
      fields: "id", // only fetch IDs for better performance
    });

    return res.json({ count: tasks.length });
  } catch (err) {
    console.error("countTasksByGroup error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

