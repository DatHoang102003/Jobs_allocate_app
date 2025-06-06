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
      status: "pending",
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
  const { taskId } = req.params;
  const { status } = req.body;
  const userId = req.user.id; // set by requireAuth

  // 1) validate status
  const allowed = ["pending", "in_progress", "completed"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status" });
  }

  try {
    // 2) fetch task with the per-request client
    const task = await req.pb
      .collection("tasks")
      .getOne(taskId, { expand: "group" });

    if (!task) return res.status(404).json({ error: "Task not found" });

    const isAssignee = task.assignee === userId;
    if (!isAssignee) return res.status(403).json({ error: "Forbidden" });

    // 3) update
    const updated = await req.pb.collection("tasks").update(taskId, { status });

    return res.json(updated);
  } catch (err) {
    console.error("updateTaskStatus", err);
    return res.status(err.status || 500).json({ error: err.message });
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
    // Fetch the task first
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (!task) {
      return res.status(404).json({ error: "Task not found" });
    }

    const me = req.user.id;
    const isCreator = task.createdBy === me;

    // Only the creator may delete
    if (!isCreator) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await pbUser.collection("tasks").delete(taskId);
    return res.json({ ok: true });
  } catch (err) {
    console.error("deleteTask error:", err.response?.data || err);
    return res.status(err.status || 500).json({ error: err.message });
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
/**
 * GET /tasks/today
 * Fetch all tasks for the authenticated user for the current day
 */
export async function getTasksForToday(req, res) {
  const pbUser = req.pbUser;
  const { date } = req.query; // Optional: YYYY-MM-DD format, defaults to today

  try {
    // Use the provided date or default to today (June 1, 2025, in this case)
    const targetDate = date ? new Date(date) : new Date("2025-06-01T00:00:00Z");
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0)).toISOString();
    const endOfDay = new Date(
      targetDate.setHours(23, 59, 59, 999)
    ).toISOString();

    // Filter tasks by the authenticated user and the date range
    const filterString = `createdBy="${req.user.id}" && created >= "${startOfDay}" && created <= "${endOfDay}"`;

    const tasks = await pbUser.collection("tasks").getFullList({
      filter: filterString,
      sort: "-created",
    });

    return res.json(tasks);
  } catch (err) {
    console.error("getTasksForToday error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ───────────────────────────────────────────────
   PATCH  /tasks/:taskId          (edit a task)
─────────────────────────────────────────────── */
export async function updateTask(req, res) {
  const { taskId } = req.params;
  const patch = req.body; // {title?, description?, assignee?, deadline?, status?}

  try {
    const record = await req.pbUser.collection("tasks").update(taskId, patch);

    res.json(record);
  } catch (err) {
    console.error("updateTask error:", err);
    res.status(err.status || 500).json({ error: err.message });
  }
}

/* ───────────────────────────────────────────────
   GET  /groups/:groupId/tasks/summary
   → { total, todo, doing, done }
─────────────────────────────────────────────── */
export async function taskSummary(req, res) {
  const { groupId } = req.params;

  const statuses = ["pending", "in_progress", "completed"];
  const counts = {};

  try {
    // count total
    counts.total = await req.pbUser
      .collection("tasks")
      .getFirstListItem(`group="${groupId}"`, { fields: "count(*)" })
      .then((r) => r["count"]);

    // count per status
    for (const s of statuses) {
      counts[s] = await req.pbUser
        .collection("tasks")
        .getFirstListItem(`group="${groupId}" && status="${s}"`, {
          fields: "count(*)",
        })
        .then((r) => r["count"]);
    }

    res.json(counts);
  } catch (err) {
    console.error("taskSummary error:", err);
    res.status(err.status || 500).json({ error: err.message });
  }
}
