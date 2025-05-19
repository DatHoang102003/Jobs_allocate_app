import PocketBase from "pocketbase";
import dotenv from "dotenv";
dotenv.config();

export const pbAdmin = new PocketBase(process.env.PB_URL);
await pbAdmin.admins.authWithPassword(
  process.env.PB_ADMIN_EMAIL,
  process.env.PB_ADMIN_PASS
);

export function createUserClient(token) {
  const pbUser = new PocketBase(process.env.PB_URL);
  if (token) pbUser.authStore.save(token, "");
  return pbUser;
}
