// controllers/auth.controller.js
import { pbAdmin, createUserClient } from "../services/pocketbase.js";
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const weakPass = /^[^\s]{6,}$/;

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
  const { email, password, name } = req.body || {};

  // basic field presence
  if (!email || !password || !name) {
    return res
      .status(400)
      .json({ error: "Email, name, and password required." });
  }
  // email format
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: "Invalid email." });
  }
  // password strength
  if (!weakPass.test(password)) {
    return res.status(400).json({
      error:
        "Password must be at least 6 characters long and contain no spaces.",
    });
  }

  try {
    const user = await pbAdmin.collection("users").create({
      email,
      password,
      passwordConfirm: password,
      name,
      emailVisibility: true,
    });
    return res.status(201).json(user);
  } catch (err) {
    let msg;
    if (err?.response?.data?.data) {
      msg = Object.values(err.response.data.data)
        .map((v) => v.message)
        .join(" ");
    } else {
      msg = err?.response?.data?.message || err.message || "";
      if (msg.startsWith("Failed to create record")) {
        msg = "Registration failed: email may already exist or data invalid.";
      }
      if (!msg) msg = "Registration failed. Please try again.";
    }
    console.error("Register error:", err.response?.data || err);
    return res.status(400).json({ error: msg });
  }
}

export async function loginUser(req, res) {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required." });
  }

  if (!emailRegex.test(email) || password.includes(" ")) {
    return res.status(400).json({ error: "Invalid email or password format." });
  }

  try {
    const pbUser = await createUserClient(null);
    const auth = await pbUser
      .collection("users")
      .authWithPassword(email, password);

    return res.json({ token: auth.token, user: auth.record });
  } catch (err) {
    let msg = err?.response?.data?.message || err.message || "";

    if (msg.startsWith("Failed to authenticate")) {
      msg = "Incorrect email or password.";
    }
    if (!msg) {
      msg = "Login failed. Please try again.";
    }

    console.error("Login error:", err.response?.data || err);
    return res.status(401).json({ error: msg });
  }
}
