NEXUS HUB — TRENDING + CONTACT UPDATE

This update starts from the last user-confirmed working NEXUS_ARCADE_REPAIRED_INTRO.html.

CHANGES
- Visible Games directory: ALL and TRENDING only.
- TRENDING: Chess Arena, Alien Neon Escape, Sky Obby, Global Chat (in that order).
- Don't Touch Sand appears immediately after Chess in ALL, and opens the original game file.
- Home: small Contact NEXUS HUB button. Back button, username, title, message, send, delete draft.
- Private Supabase owner inbox: owner login, reply, delete, visitor receipt-based reply checking.

SETUP — REQUIRED FOR CONTACT TO WORK
1. Open your EXISTING Supabase project (same one used for Global Chat).
2. SQL Editor: run NEXUS_CONTACT_SUPABASE_SETUP.sql.
3. Authentication > Users > Add user: create your owner email/password.
4. Copy that user's UID, and run in SQL Editor:
   insert into public.nexus_contact_owners(user_id) values ('PASTE-REAL-USER-UUID-HERE');
5. Deploy the whole project. Test a visitor message and owner login.

The owner account cannot be created securely by clicking a public website button: create it in the Supabase dashboard.
Public visitors cannot read the inbox; RLS protects it. They can view their own reply using the unguessable receipt stored in their browser.
The delete button clears an unsent draft. Owners can permanently delete received messages.
Do not put any service_role key or owner password into GitHub.

DEPLOY
Upload all ZIP contents to the GitHub repository root, preserving public/ and netlify/.
Netlify publish directory = public, functions directory = netlify/functions.
