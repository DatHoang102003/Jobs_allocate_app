// controllers/join.controller.js
import pb from '../services/pocketbase.js';

export async function sendJoinRequest(req, res) {
  const userId  = req.user.id;
  const groupId = req.params.groupId;

  try {
    const jr = await pb.collection('join_requests').create({
      user:  userId,
      group: groupId,
      status: 'pending',
    });
    res.status(201).json(jr);
  } catch (err) {
    console.error('sendJoinRequest error:', err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

export async function listJoinRequests(req, res) {
  const userId = req.user.id;
  try {
    const myReqs = await pb
      .collection('join_requests')
      .getFullList({
        filter: `user="${userId}"`,
        sort:   '-created',
      });
    res.json(myReqs);
  } catch (err) {
    console.error('listJoinRequests error:', err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

export async function approveJoinRequest(req, res) {
  const userId = req.user.id;
  const jrId   = req.params.jrId;

  try {
    // fetch join request
    const jr = await pb.collection('join_requests').getOne(jrId);
    // ensure current user is the group owner
    const group = await pb.collection('groups').getOne(jr.group);
    if (group.owner !== userId) return res.status(403).json({ error: 'Forbidden' });

    // mark approved
    await pb.collection('join_requests').update(jrId, { status: 'approved' });
    // create membership
    await pb.collection('memberships').create({
      user:  jr.user,
      group: jr.group,
      role:  'member',
    });

    res.json({ ok: true });
  } catch (err) {
    console.error('approveJoinRequest error:', err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}

export async function rejectJoinRequest(req, res) {
  const userId = req.user.id;
  const jrId   = req.params.jrId;

  try {
    const jr = await pb.collection('join_requests').getOne(jrId);
    const group = await pb.collection('groups').getOne(jr.group);
    if (group.owner !== userId) return res.status(403).json({ error: 'Forbidden' });

    await pb.collection('join_requests').update(jrId, { status: 'rejected' });
    res.json({ ok: true });
  } catch (err) {
    console.error('rejectJoinRequest error:', err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}
