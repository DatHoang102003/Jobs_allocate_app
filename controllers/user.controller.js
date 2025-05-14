import PocketBase from "pocketbase";
import multer from "multer";

// Optional: if you're handling file upload middleware
export const upload = multer({ storage: multer.memoryStorage() });

export async function getMyProfile(req, res) {
  try {
    const user = req.user;
    res.json(user); // Already sanitized from PB authStore
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

export async function updateMyProfile(req, res) {
  const pbUser = req.pbUser;
  const userId = req.user.id;
  const { name, email, password, passwordConfirm } = req.body;
  const avatarFile = req.file; // if using multer

  try {
    const formData = new FormData();

    if (name) formData.append("name", name);
    if (email) formData.append("email", email);
    if (password && passwordConfirm) {
      formData.append("password", password);
      formData.append("passwordConfirm", passwordConfirm);
    }

    // Only if image is sent
    if (avatarFile) {
      formData.append("avatar", avatarFile.buffer, avatarFile.originalname);
    }

    const updated = await pbUser.collection("users").update(userId, formData);
    res.json(updated);
  } catch (err) {
    console.error("updateMyProfile error:", err.response?.data || err);
    res.status(400).json({ error: err.message });
  }
}
