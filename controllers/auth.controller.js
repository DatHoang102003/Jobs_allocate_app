import pb from '../services/pocketbase.js';

export async function registerUser(req, res) {
  const { email, password, name } = req.body;
  try {
    const user = await pb.collection('users').create({
      email,
      password,
      passwordConfirm: password,
      name,
    });
    res.status(201).json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

export async function loginUser(req, res) {
  const { email, password } = req.body;
  try {
    const authData = await pb.collection('users').authWithPassword(email, password);
    res.json({ token: authData.token, user: authData.record });
  } catch (err) {
    res.status(401).json({ error: err.message });
  }
}
