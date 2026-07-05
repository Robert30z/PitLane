# PitLane — Phase 2: going from prototype to a real shared app

Right now PitLane is a **prototype**: it works fully, but each person's data lives only
on their own device (browser localStorage). Nothing is shared, and the email code is
simulated. This guide turns it into a **real multi-user app** with:

- Real accounts + **real email verification** (Supabase Auth sends the code)
- **Shared data** — everyone sees the same listings, events, clans, ranks, map
- Photo storage in the cloud (car + listing photos)
- The **gold name locked to the founder**, enforced on the server (can't be faked)

All of this runs on **Supabase's free tier** ($0) and stays on your existing GitHub Pages URL.

---

## What Roberto does (about 10 minutes, one time)

1. Go to **supabase.com** → sign in with your Google account (rjohn7148@gmail.com) → **New project**.
   - Name: `pitlane`  ·  pick a strong database password (save it)  ·  region: closest to you.
2. When the project finishes building, open **Project Settings → API** and copy two values:
   - **Project URL** (looks like `https://xxxx.supabase.co`)
   - **anon public** key (a long string — this one is safe to put in the app / share with me)
   - ⚠️ Do **NOT** share the `service_role` key — that one is secret.
3. Open **SQL Editor → New query**, paste the entire contents of **`schema.sql`** (in this repo), and click **Run**. That builds all the tables, the PL-#### numbering, and the gold-name guard.
4. Open **Authentication → Providers → Email** and make sure "Confirm email" is ON (this is what sends the real 6-digit / magic-link verification).
5. Paste the **Project URL** and **anon key** back to me in Claude Code.

## What I do (once you send those two values)

- Wire the app to Supabase (auth + data), replacing the local demo store.
- Move photo uploads to Supabase Storage.
- Seed your founder account (Trippzy, PL-0001, Master, gold).
- Test the whole thing live end-to-end (sign up on one device, see it on another).
- Push it live to `robert30z.github.io/PitLane`.

The prototype keeps working the whole time — if Supabase keys aren't present, the app
falls back to local demo mode, so nothing breaks while we build.

---

## Why Supabase (and not something else)
- Free tier is plenty for launch (50k monthly active users, 500MB DB, 1GB storage).
- Gives us **auth + database + file storage + realtime** in one place — exactly PitLane's needs.
- Works from a static GitHub Pages site (no server to run or pay for).
- If we outgrow it, it's standard Postgres — easy to move.

## Files in this repo
- `index.html` — the whole app (prototype).
- `schema.sql` — the Phase 2 database (run once in Supabase).
- `SETUP.md` — this file.
