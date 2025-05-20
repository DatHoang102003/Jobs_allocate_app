import PocketBase from "pocketbase";
import multer from "multer";

export const upload = multer({ storage: multer.memoryStorage() });

/* ───────────────── GET /me ───────────────── */
export async function getMyProfile(req, res) {
  try {
    res.json(req.user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/* ─────────────── PATCH /me (update + avatar) ─────────────── */
export async function updateMyProfile(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;

  // Multer makes sure req.body is at least an object
  const { name, email, password, passwordConfirm } = req.body || {};
  const avatarFile = req.file; // set if upload.single('avatar') matched

  try {
    const formData = new FormData(); // global in Node 18+

    if (name) formData.append("name", name);
    if (email) formData.append("email", email);

    if (password && passwordConfirm) {
      formData.append("password", password);
      formData.append("passwordConfirm", passwordConfirm);
    }

    /* ---- wrap Buffer in Blob so FormData accepts it ---- */
    if (avatarFile) {
      const blob = new Blob([avatarFile.buffer], { type: avatarFile.mimetype });
      formData.append("avatar", blob, avatarFile.originalname);
    }

    const updated = await pbUser.collection("users").update(userId, formData);
    res.json(updated);
  } catch (err) {
    console.error("updateMyProfile error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}
