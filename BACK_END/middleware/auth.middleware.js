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
    const pbUser = new PocketBase(PB_URL);
    pbUser.authStore.save(token, ""); // save token to PB client
    await pbUser.collection("users").authRefresh(); // fetch valid user

    req.pbUser = pbUser;
    req.user = pbUser.authStore.model;

    req.pb = pbUser;

    return next();
  } catch (err) {
    return res.status(401).json({ error: "Unauthorized: " + err.message });
  }
}
