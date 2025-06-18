
/* ───────────────────────── Create ───────────────────────── */
export async function createTask(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { title, description, assignee = [], deadline } = req.body;
  const assigneeIds = Array.isArray(assignee) ? assignee : [assignee];
  const creatorId = req.user.id;

  if (!pbUser) {
    return res.status(500).json({ error: "PocketBase user instance is not available" });
  }

  try {
    const payload = {
      group: groupId,
      title,
      description,
      assignee: assigneeIds,
      status: "pending",
      createdBy: creatorId,
      is_deleted: false
    };
    if (deadline) payload.deadline = deadline;

    const task = await pbUser.collection("tasks").create(payload);
    return res.status(201).json(task);
  } catch (err) {
    console.error("createTask error:", err.response?.data || err);
    return res.status(400).json({ error: err.message || "Create task failed" });
  }
}

/* ─────────────────────── List by Group ─────────────────────── */
export async function listTasksByGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { status, assignee, page, perPage } = req.query;

  try {
    const filters = [`group="${groupId}"`, `is_deleted=false`];
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

    const items = await pbUser.collection("tasks").getFullList(200, {
      filter: filterString,
      sort: "-created",
    });
    return res.json(items);
  } catch (err) {
    console.error("listTasksByGroup error:", err.response?.data || err);
    return res.status(400).json({ error: err.message || "List tasks failed" });
  }
}

/* ─────────────────────── Update Status ─────────────────────── */
export async function updateTaskStatus(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;
  const { status } = req.body;
  const allowed = ["pending", "in_progress", "completed"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "Invalid status value" });
  }

  try {
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (task.is_deleted) {
      return res.status(404).json({ error: "Task not found" });
    }
    const assigneeIds = Array.isArray(task.assignee) ? task.assignee : [];
    if (!assigneeIds.includes(req.user.id)) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const updated = await pbUser.collection("tasks").update(taskId, { status });
    return res.json(updated);
  } catch (err) {
    console.error("updateTaskStatus error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ─────────────────────── Update Task ─────────────────────── */
export async function updateTask(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;
  const { title, description, deadline, assignee = [] } = req.body;
  const assigneeIds = Array.isArray(assignee) ? assignee : [assignee];

  try {
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (task.is_deleted) {
      return res.status(404).json({ error: "Task not found" });
    }
    if (task.createdBy !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const payload = {};
    if (title !== undefined) payload.title = title;
    if (description !== undefined) payload.description = description;
    if (deadline !== undefined) payload.deadline = deadline;
    if (assigneeIds.length) payload.assignee = assigneeIds;

    const updated = await pbUser.collection("tasks").update(taskId, payload);
    return res.json(updated);
  } catch (err) {
    console.error("updateTask error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ─────────────────────── Soft-delete Task ─────────────────────── */
export async function deleteTask(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const { taskId } = req.params;

  try {
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (!task || task.is_deleted) {
      return res.status(404).json({ error: "Task not found" });
    }
    const group = await pbUser.collection("groups").getOne(task.group);
    if (!group || group.deleted) {
      return res.status(400).json({ error: "Parent group not found" });
    }

    let canDelete = task.createdBy === userId || group.owner === userId;
    if (!canDelete) {
      const ms = await pbUser.collection("memberships").getFirstListItem(
        `group="${group.id}" && user="${userId}"`
      );
      canDelete = ms?.role === "admin";
    }
    if (!canDelete) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await pbUser.collection("tasks").update(taskId, { is_deleted: true });
    return res.json({ ok: true });
  } catch (err) {
    console.error("deleteTask error:", err.response?.data || err);
    return res.status(err?.status || 400).json({ error: err.message });
  }
}

/* ─────────────────────── Count Tasks ─────────────────────── */
export async function countTasksByGroup(req, res) {
  const pbUser = req.pbUser;
  const { groupId } = req.params;
  const { status } = req.query;

  try {
    const filters = [`group="${groupId}"`, `is_deleted=false`];
    if (status) filters.push(`status="${status}"`);
    const filterString = filters.join(" && ");

    const tasks = await pbUser.collection("tasks").getFullList(200, {
      filter: filterString,
      fields: "id"
    });
    return res.json({ count: tasks.length });
  } catch (err) {
    console.error("countTasksByGroup error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ─────────────────────── Filtered Fetch ─────────────────────── */
export async function getTasksByFilter(req, res) {
  const pbUser = req.pbUser;
  const { filterBy, date, status } = req.query;
  const userId = req.user.id;

  try {
    if (!["created", "deadline", "status"].includes(filterBy)) {
      return res.status(400).json({ error: 'Invalid filterBy value' });
    }
    if (filterBy === "status" && !status) {
      return res.status(400).json({ error: 'Status parameter is required' });
    }

    const target = date ? new Date(date) : new Date();
    const start = new Date(target.setHours(0, 0, 0, 0)).toISOString();
    const end = new Date(target.setHours(23, 59, 59, 999)).toISOString();

    let filters = [`(createdBy="${userId}" || assignee~"${userId}")`, `is_deleted=false`];
    let sort = '-created';

    if (filterBy === 'created') {
      filters.push(`created >= "${start}" && created <= "${end}"`);
    } else if (filterBy === 'deadline') {
      filters.push(`deadline >= "${start}" && deadline <= "${end}"`);
      sort = '-deadline';
    } else if (filterBy === 'status') {
      filters.push(`status="${status}"`);
    }
    const filterString = filters.join(" && ");

    const tasks = await pbUser.collection("tasks").getFullList(200, {
      filter: filterString,
      sort
    });
    return res.json(tasks);
  } catch (err) {
    console.error("getTasksByFilter error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ─────────────────────── Assignee Info ─────────────────────── */
export async function getAssigneeInfo(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;

  try {
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (!Array.isArray(task.assignee) || task.assignee.length === 0) {
      return res.status(404).json({ error: "No assignees found" });
    }
    const assignees = await Promise.all(
      task.assignee.map(id => pbUser.collection("users").getOne(id))
    );
    return res.json(assignees);
  } catch (err) {
    console.error("getAssigneeInfo error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}

/* ─────────────────────── Task Details ─────────────────────── */
export async function getTaskDetail(req, res) {
  const pbUser = req.pbUser;
  const { taskId } = req.params;

  try {
    const task = await pbUser.collection("tasks").getOne(taskId);
    if (task.is_deleted) {
      return res.status(404).json({ error: "Task not found" });
    }
    if (!Array.isArray(task.assignee) || task.assignee.length === 0) {
      return res.json(task);
    }
    const assigneeInfo = await Promise.all(
      task.assignee.map(id => pbUser.collection("users").getOne(id))
    );
    return res.json({ ...task, assigneeInfo });
  } catch (err) {
    console.error("getTaskDetail error:", err.response?.data || err);
    return res.status(400).json({ error: err.message });
  }
}