import pb from '../services/pocketbase.js';

export async function requireAuth(req, res, next) {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) throw new Error('No token');
    await pb.collection('users').authRefresh(token);
    req.user = pb.authStore.model;
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
}
