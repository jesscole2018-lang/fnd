# Floor & Decor Merch Review

Reviewer site prepared by CIC. Hosted on GitHub Pages; sign-in and saved decisions run on Supabase.

- **No pricing, inventory or decision data is stored in this repository.** It loads from Supabase only after an approved person signs in.
- Page code: `index.html` (layout + sign-in), `boot.js` (sign-in, data loading, storage), `app.js` (the review site).
- Database setup: `supabase/setup.sql` (run once in the Supabase SQL Editor).

## Add or remove a reviewer
1. Supabase → Authentication → Users → **Add user → Create new user**: enter their email and a temporary password, tick **Auto Confirm User**.
2. Supabase → SQL Editor → run:
   ```sql
   insert into public.allowed_users (email, name, role) values ('first.last@example.com','First Last','reviewer')
   on conflict (email) do update set name = excluded.name, role = excluded.role;
   ```
3. Send them the site link, their email and the temporary password.

Remove: `delete from public.allowed_users where email = 'first.last@example.com';` (and delete the user under Authentication → Users).

## Update the items / prices / inventory
Sign in as an admin and open the site with `?import` at the end of the address, then load the new INTERNAL ONLY site-data file from CIC. Saved decisions are kept.
