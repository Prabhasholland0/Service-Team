# Service Team

A responsive web application for desktop and mobile browsers. Members choose services; admins assign Producer, CCU, and a configurable number of cameras (0–16, default 8).

## Current delivery

The public Supabase project URL and publishable key are configured for project `bwsdlzeqwjozxlkpkdhy`. The connection was verified; application tables still need to be created. Until then the website shows a setup-pending message. No secret key is included. If the public configuration is cleared, the website opens in a clearly labeled **sample workspace**. Sample edits last for the current visit and are never presented as database saves. No real users or contact information are seeded. This is a mobile-friendly website, not an App Store or Play Store native package.

## Activate the real application

1. Create or select a Supabase project. Run `supabase/001_schema.sql`, `supabase/002_storage.sql`, and `supabase/camera-count.sql` in its SQL editor. These migrations target a new project; do not apply blindly over an existing schema.
2. Put the project URL and **public publishable/anon key** in `dist/config.js`. Never use a service-role or secret key in browser code. Redeploy the static `dist/` folder.
3. In Supabase Auth, enable email/password authentication, set the Site URL to the deployed app origin, and allow that origin as an email-confirmation redirect URL.
4. Register your own account and confirm its email. Profiles are created automatically for every registered account.
5. In the trusted Supabase SQL editor, promote the first administrator using that account's actual UUID:

   ```sql
   update public.profiles
   set is_admin = true
   where id = 'REPLACE-WITH-YOUR-ACCOUNT-UUID';
   ```

6. Sign in again. In Team members, assign each member's Camera, Producer, and/or CCU capabilities. Users cannot grant themselves skills or admin access. Members complete their name, phone and optional profile photo, then submit availability.
7. Confirm access with one admin and one member account before inviting the whole team. Supabase login and database authorization remain required independently of the hosting audience.

## Workflow and rules

- A date identifies the service day, with the next Sunday selected initially. Any date can be selected; availability is not a recurring weekly template.
- Submission atomically writes all four service responses in Supabase. Unchecked services become Not Available. A missing row means Not Submitted.
- Admins see the registered team automatically, filter by role, service and status, and receive refreshed data every 15 seconds while the availability or schedule view is open and no unsaved edits are present.
- Profiles include the actual Supabase user UUID, name, email, phone, private photo path, skills, active flag and admin flag.
- Admins can assign only active members with both availability and the required capability. A member holds at most one duty per service, including Producer and CCU. The same person can serve in different services.
- Auto Assign preserves existing manual choices and uses maximum matching to fill remaining positions. It proposes a draft; it does not publish automatically or guarantee rotation/fairness.
- Drafts may be incomplete. Publishing requires Producer, CCU, and every selected camera position. Admins choose the camera count per service from 0 through 16; reducing it prompts before clearing removed camera assignments. Assignments reference UUIDs, never only names. Database constraints prevent duplicate positions and duplicate people within a service.
- Authorized RPCs validate all writes inside transactions. A transaction lock serializes schedule/availability/eligibility mutations to prevent races; revision checks reject stale admin saves.
- Withdrawing availability, removing a required skill or deactivating an assigned member removes affected duties and returns the schedule to draft. The admin must review and republish. Previously copied WhatsApp text cannot be recalled.
- Members can read their own profile and availability and the published roster. Admins can read team contact details and drafts. Anonymous callers cannot read team data. Users cannot directly mutate tables.
- Profile photos use a private Supabase Storage bucket with owner/admin access and signed URLs; maximum 2 MB, JPEG/PNG/WebP.
- WhatsApp generation prepares copyable text only. No message is sent automatically.

## Run and test

Serve `dist/` with any static HTTP server. No build is needed for the checked-in browser assets. To reproduce the vendored Supabase SDK after installing pinned dependencies:

```text
npm ci
node build-vendor.mjs
npm test
```

Tests cover eligibility, scarce-role matching, preserved manual choices, duplicate duties, missing availability, partial drafts, and a PostgreSQL-compatible PGlite integration test for the database migration, row-level security, admin authorization, persisted schedules, stale revisions, withdrawal and skill-change invalidation.

Database tests use local mock Supabase authentication tables/functions. Real Supabase email delivery, deployed Auth, storage upload policies and multi-device operation still require a configured project for end-to-end verification. PGlite tests do not simulate concurrent database sessions.

Source reference: [Supabase JavaScript initialization](https://supabase.com/docs/reference/javascript/initializing), [email sign-up](https://supabase.com/docs/reference/javascript/auth-signup), and [user profiles](https://supabase.com/docs/guides/auth/managing-user-data).

