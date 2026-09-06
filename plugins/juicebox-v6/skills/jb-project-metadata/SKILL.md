---
name: jb-project-metadata
description: |
  Prepare and publish standard Juicebox V6 project metadata JSON to IPFS and obtain
  the real project URI. Use when: (1) a project or revnet launch needs name,
  description, logoUri, or infoUri, (2) an agent needs an actionable IPFS pinning
  path, (3) building a metadata upload flow. Covers JSON publishing and the
  separate image upload prerequisite; wallet signing remains external.
metadata:
  version: 6.0.0
---

# Juicebox V6 Project Metadata

Use the hosted MCP at `https://juicebox.center/mcp` to prepare and pin a standard
metadata document. Pinning JSON is a separate operation from uploading an image
or launching/updating a project. No wallet is needed to pin metadata.

## Prepare the complete document

Call `jb_prepare_project_metadata` with this shape. This example intentionally
omits an image until the user has a real image URI:

```json
{
  "version": 6,
  "metadata": {
    "name": "Fruitful",
    "description": "A community project."
  }
}
```

| Field | Requirement |
|-------|-------------|
| `version` | Required literal `6` at the tool-input level; not written into the JSON document |
| `metadata.name` | Required nonblank string, at most 256 characters |
| `metadata.description` | Required string; may be empty if that is the intended document |
| `metadata.logoUri` | Optional existing `ipfs://` URI with a real canonical CID and safe path, or absolute HTTPS URL without credentials |
| `metadata.infoUri` | Optional URI with the same supported forms; normally the project's HTTPS website |

The complete canonical JSON must fit 64 KiB in UTF-8. These four metadata fields
are the entire supported document; other fields are rejected. Do not silently
drop existing fields or promise a merge. A request to edit existing metadata with
additional fields needs a workflow that preserves them, or a deliberate user
choice to replace the complete document.

Preparation returns `review.metadata`, exact `review.jsonText`,
`review.contentSha256`, `review.utf8Bytes`, a `token`, and `expiresAt`.
Canonical serialization sorts object keys, adds no trailing newline, and does not
normalize Unicode. Review `jsonText` for the exact bytes to be published; the
original JSON formatting is not preserved.
`publication.uploaded` is `false`. `publication.configured` reports whether this
server has a pinning backend. A local server without one can still prepare a
review; connect to the hosted service and prepare again there to publish. Tokens
are bound to their issuing server and purpose, so do not assume they transfer.

## Publish the reviewed JSON

Show the complete reviewed document and explain that this uploads it publicly to
IPFS, where removal cannot be guaranteed. The review token is a commitment to
content, not user approval. If the user's existing instruction already authorizes
this exact public upload, continue; otherwise obtain that authorization before
calling `jb_pin_project_metadata` with the actual returned token and
`confirmPublicUpload: true`. Do not use a fabricated token or modify the JSON
after review. Any content change requires a new preparation.

The successful response contains:

- `metadataUri`: the real `ipfs://` URI to use in the project configuration.
- `cid`, `contentSha256`, and `utf8Bytes`: the provider receipt and reviewed
  document identity.
- `publication.primaryUploadAcknowledged: true` and
  `publication.redundancyStatus: "queued"`: primary upload acknowledgment;
  replica pinning is queued. This does not prove gateway retrieval or permanent
  availability.

An optional retrieval link is `https://juicebox.center/ipfs/` followed by the
returned CID. Report successful retrieval only if it has actually been checked.
The service does not fetch the linked `logoUri` or `infoUri`, verify their
availability, launch a project, or submit any chain transaction.

If the token expires, prepare the same intended document again and review it;
prior authorization for the identical public content still applies. If pinning
returns `METADATA_PUBLICATION_UNVERIFIED`, some upload may already have occurred.
Inspect provider/service status before a deliberate retry; do not loop and spend
the provider quota repeatedly. An unavailable backend or spent quota is a real
failure: return the reviewed JSON and exact missing prerequisite, not a fake CID.

## Obtain the logo URI separately

The MCP metadata tools accept references to already hosted images; they do not
accept local image paths, binary/base64 payloads, or upload an image when given a
URL. `ipfs://<IMAGE_CID>`, `ipfs://...`, and made-up CIDs are not usable metadata.

If the user supplies an existing image URI, retain it exactly. If they supply a
local image, use an available, authorized image upload integration first, then
insert its returned URI into the metadata and prepare the complete JSON. If no
such integration is available, leave publication pending when the logo is
required; continue drafting the document and other launch configuration. Do not
silently omit the requested logo. A user who wants to launch without one can omit
`logoUri` altogether.

For webclient development, the real SDK methods are:

```typescript
import { createJBCenterClient } from '@bananapus/nana-sdk-core/jbcenter'

// Use within an actual approved webclient or a properly configured integration.
// selectedFile is the real user-selected File, and its public upload is authorized.
const center = createJBCenterClient({ baseUrl: 'https://juicebox.center' })
const imagePin = await center.pinImage(selectedFile, { filename: selectedFile.name })
const logoUri = imagePin.uri
// Put logoUri in the complete metadata document before MCP preparation/publication.
```

`pinImage` uses Center's multipart `POST /v1/pins/file` (`file` field); `pinJson`
uses `POST /v1/pins/json`. The browser pin routes require an actually approved
origin. Do not spoof a first-party `Origin` from a script, assume the public RPC
gateway grants upload access, expose provider credentials, or claim these SDK
methods make arbitrary CLI uploads authorized. Hosted MCP JSON publication uses
Center's integrated backend and its quota checks.

Verified first-party image workflows: Juicebox Money
`src/components/create/CreateForm.tsx` → `src/lib/jbcenter-ipfs.ts`; Revnet Money
`src/app/create/form/ProjectDetails.tsx` →
`src/app/create/helpers/pinProjectMetaData.ts` → `src/lib/jbcenter-ipfs.ts`.

## Use the returned URI in V6

Resolve existing projects with `/jb-project-identity`; new launches have no
project ID until their chain receipts establish one. Pass the returned
`metadataUri` as `projectUri` in `jb_prepare_launch` or `jb_prepare_721_launch`, or
as `config.description.uri` in `jb_prepare_revnet_deploy`. Review and simulate
the resulting unsigned plan before external wallet signing; verify its receipt
afterward. Metadata publication itself does not require a chain or project ID.

For an existing standard project, the URI lives on the current
`JBController.uriOf(projectId)` and is updated with `setUriOf(projectId, uri)` by
the owner or an operator with `SET_PROJECT_URI`. It is separate from the
protocol-rendered `JBProjects.tokenURI(projectId)`. The MCP does not currently
provide a dedicated `setUriOf` preparation tool; use a separately reviewed V6
SDK/ABI call if that operation is requested. A successful pin is not an on-chain
metadata update. Revnet configuration/ownership constraints still apply.

Source: MCP `src/services/metadata.ts` and `src/mcp/metadata-tools.ts`; SDK
`packages/core/src/jbcenter.ts`; Center `src/app.ts` and `src/ipfs.ts`; V6
`nana-core-v6/src/JBController.sol`.

## Common mistakes

- Stopping after writing JSON without obtaining a real pin receipt and URI.
- Treating a generated review token as authorization to publish.
- Pinning the JSON and claiming the referenced image was uploaded too.
- Treating queued replication as completed, permanent storage.
- Passing `logoUri` as the project's metadata URI instead of the JSON URI.
- Replacing existing metadata while silently dropping unsupported fields.
