// middleware/auth.middleware.js
import PocketBase from "pocketbase";
const PB_URL = process.env.PB_URL || "http://127.0.0.1:8090";

export async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) {
    return res
      .status(401)
      .json({ error: "Missing or malformed Authorization header" });
  }

  const token = header.split(" ")[1];

  try {
    // fresh client per request
    const pbUser = new PocketBase(PB_URL);

    // 1️⃣ store the token in the auth-store
    pbUser.authStore.save(token, ""); // second arg = empty model JSON

    // 2️⃣ validate & fetch the user model
    await pbUser.collection("users").authRefresh(); // uses token in authStore

    // 3️⃣ attach to request
    req.pbUser = pbUser;
    req.user = pbUser.authStore.model; // non-null now

    return next();
  } catch (err) {
    return res.status(401).json({ error: "Unauthorized: " + err.message });
  }
}
