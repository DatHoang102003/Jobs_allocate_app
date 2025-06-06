// controllers/auth.controller.js
import { pbAdmin, createUserClient } from "../services/pocketbase.js";

export async function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

    if (!token) {
      return res.status(401).json({ error: "Missing Bearer token" });
    }

    // create a brand-new PB client authenticated with this token
    const pbUser = await createUserClient(token);

    // make sure the token is still valid (will throw if not)
    await pbUser.collection("users").authRefresh();

    // expose to downstream controllers
    req.user = pbUser.authStore.model; // { id, email, name, … }
    req.pb = pbUser;

    return next();
  } catch (err) {
    console.error("Auth error:", err.response?.data || err);
    return res.status(401).json({ error: "Unauthorized" });
  }
}

export async function registerUser(req, res) {
  const { email, password, name } = req.body;
  try {
    // Use the admin client to bypass any create rules
    const user = await pbAdmin.collection("users").create({
      email,
      password,
      passwordConfirm: password,
      name,
      emailVisibility: true,
    });
    return res.status(201).json(user);
  } catch (err) {
    console.error("Register error:", err.response?.data || err);
    return res.status(400).json({ error: "Failed to create record." });
  }
}

export async function loginUser(req, res) {
  const { email, password } = req.body;
  try {
    // Use a temporary PocketBase client to authenticate the user
    const pbUser = await createUserClient(null); // we'll auth momentarily
    const authData = await pbUser
      .collection("users")
      .authWithPassword(email, password);

    // pbUser.authStore now holds the valid token and user model
    const token = authData.token;
    const user = authData.record;

    return res.json({ token, user });
  } catch (err) {
    console.error("Login error:", err.response?.data || err);
    return res.status(401).json({ error: err.message });
  }
}
