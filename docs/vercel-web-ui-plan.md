# Vercel Web UI Plan

## Goal

Expose the MonoLisa Nerd Fonts patcher through a web UI while keeping commercial
font uploads private, processing isolated, and generated artifacts short-lived.

The target product flow:

1. User uploads licensed MonoLisa Code font files.
2. User selects patcher options.
3. Backend runs the pinned Nerd Fonts patcher.
4. User downloads a generated zip.
5. Uploaded sources and generated outputs expire automatically.

## Recommended Architecture

Use Vercel for the product surface, storage, and orchestration, but keep the
FontForge patch job out of a normal Vercel Function.

- Next.js app on Vercel for the UI.
- Vercel Blob for temporary private uploads and generated zip files.
- Vercel Function for upload registration, validation, job creation, and status.
- Vercel Sandbox for isolated patch execution.
- A small job table for state, either Vercel Postgres, Neon, Supabase, or Upstash.

Regular Vercel Functions are a poor fit for the patcher itself because the job
uses native tooling, temporary files, potentially large uploads, and binary
outputs. Vercel Sandbox is the better Vercel-native execution target because it
is designed for isolated command execution with filesystem access.

If Sandbox is too constrained in practice, keep the Vercel UI and move only the
worker to Fly.io, Render, AWS ECS, or another container runtime.

## User Flow

1. The app shows a single upload workflow.
2. The user uploads `.ttf` or `.otf` files directly to private Blob storage.
3. The app creates a patch job with selected options.
4. The job runner downloads the uploaded fonts into an isolated workspace.
5. The runner executes the existing patch script or equivalent container command.
6. The runner zips generated fonts and uploads the zip to private Blob storage.
7. The UI polls or streams job status.
8. The user downloads the zip through a short-lived URL.
9. A cleanup task deletes uploaded sources, logs, and generated outputs.

## UI Scope

Build the first version as a focused utility, not a landing page.

Required controls:

- File picker for `.ttf` and `.otf`.
- File list with size and removal controls.
- Toggle for `PATCH_CLEAN` behavior if multiple runs per job are supported.
- Patcher options:
  - default full patch mode,
  - optional `--adjust-line-height`,
  - optional `--mono`,
  - optional `--single-width-glyphs`,
  - optional `--variable-width-glyphs`,
  - optional `--extension ttf|otf`.
- Submit button.
- Job status view: queued, running, complete, failed, expired.
- Download button for completed jobs.
- Collapsible log viewer for failures and advanced diagnosis.

Avoid exposing every upstream patcher flag initially. Keep advanced flags behind
a text field only if there is a clear need and strong validation.

## Backend API Shape

Suggested endpoints:

- `POST /api/uploads`: create signed/private upload targets.
- `POST /api/jobs`: validate uploaded blob references and create a patch job.
- `GET /api/jobs/:id`: return status, selected options, and download readiness.
- `GET /api/jobs/:id/log`: return sanitized logs for the authenticated job owner.
- `POST /api/jobs/:id/cancel`: cancel queued or running jobs if supported.
- `GET /api/jobs/:id/download`: issue a short-lived download URL.

For a minimal first version, `POST /api/jobs` can start the worker immediately
and `GET /api/jobs/:id` can be simple polling.

## Job Model

Store enough state to support retries, cleanup, and diagnosis:

- `id`
- `owner_id` or anonymous session token hash
- `status`
- `input_blob_keys`
- `output_blob_key`
- `log_blob_key`
- `selected_options`
- `created_at`
- `started_at`
- `finished_at`
- `expires_at`
- `error_summary`

Anonymous use is possible, but production should still use a session token so
users cannot access other users' jobs.

## Worker Design

The worker should treat uploaded fonts as untrusted binary input.

Execution steps:

1. Create a fresh isolated workspace.
2. Download input blobs into `input/`.
3. Validate file extensions, file count, and total size again.
4. Run the pinned patcher image or an equivalent prebuilt worker image.
5. Capture full logs.
6. Verify expected output files exist.
7. Zip generated fonts.
8. Upload zip and log to private Blob storage.
9. Delete the workspace.

The existing `scripts/patch.sh` is a good local baseline, but the hosted worker
may need a dedicated wrapper that does not assume Docker is available. If Docker
is not available in Sandbox, build a worker image or install FontForge and the
pinned Nerd Fonts patcher directly in the execution environment.

## Security And Privacy

This app handles commercial font files. Treat that as the central constraint.

- Require users to confirm they have a valid MonoLisa license.
- Never ship or bundle MonoLisa source files with the app.
- Store uploaded fonts in private storage only.
- Use short retention windows, for example 1 hour for sources and 24 hours for
  generated outputs.
- Run patching in an isolated environment per job.
- Enforce upload count, file type, and total byte limits.
- Do not log font file contents or user-identifying metadata.
- Make logs available only to the job owner.
- Add rate limits and abuse protection before public launch.

## Operational Limits

Initial limits should be conservative:

- Maximum files per job: 32.
- Maximum total upload size: 100 MB.
- Maximum job runtime: 10 minutes.
- Maximum retained log size: 2 MB, with truncation.
- Maximum concurrent jobs per user: 1.

Adjust after measuring real patch runs.

## Open Questions

- Can Vercel Sandbox run the pinned Nerd Fonts patcher image directly, or do we
  need a non-Docker worker wrapper?
- Should the hosted version support all MonoLisa variants or only MonoLisa Code?
- Should anonymous use be allowed, or should the app require login?
- What retention policy is acceptable for uploaded commercial font files?
- Should successful logs be downloadable, or only retained for failed jobs?

## Milestones

### 1. Prototype

- Create a Next.js app shell.
- Implement local-only upload and job status UI.
- Run the current patch script against local fixture fonts.
- Confirm generated output can be zipped and downloaded.

### 2. Vercel Storage

- Add private Blob upload and download flow.
- Store job metadata in a small database.
- Implement TTL cleanup for source and output blobs.

### 3. Isolated Worker

- Test Vercel Sandbox with the pinned patcher.
- If needed, create a dedicated worker runtime.
- Capture logs and failure summaries.
- Verify output zip creation.

### 4. Production Hardening

- Add auth or anonymous signed sessions.
- Add rate limits and upload limits.
- Add license confirmation copy.
- Add failure log UI.
- Add monitoring for job duration, failures, and storage cleanup.

### 5. Launch

- Deploy the UI on Vercel.
- Run end-to-end tests with real licensed input files.
- Document the privacy model and retention policy.
- Keep the CLI workflow as the fallback for users who prefer local processing.
