# Runbook: Enable mTLS on a Global External Application Load Balancer with gcloud

| | |
|---|---|
| **Applies to** | Any Lucidworks managed customer whose Fusion ingress sits behind a Global External Application Load Balancer (`EXTERNAL_MANAGED`) that is **not** managed by Terraform |
| **First customer** | st-micro (`mf-stmicroelectronics`), non-prod (dev, stg) then prod |
| **Method** | `gcloud` only (no Terraform). Equivalent Terraform: [MTLS_IMPLEMENTATION_GUIDE.md](MTLS_IMPLEMENTATION_GUIDE.md) |
| **Rollout model** | Observe first (`ALLOW_INVALID_OR_MISSING_CLIENT_CERT`), enforce later (`REJECT_INVALID`), dev then stg then prod |
| **Customer values** | [Appendix A](#appendix-a-customer-parameter-sheet) |

---

## 1. Purpose of mTLS and what enabling it means

### 1.1 What it is

With ordinary TLS, only the server proves its identity: the client checks the server certificate. With **mutual TLS (mTLS)** the client must also present a certificate during the TLS handshake, and the load balancer checks it against a CA the customer trusts (the *trust config*). A client without a certificate signed by that CA either cannot connect at all (`REJECT_INVALID`) or can connect but is flagged as unauthenticated (`ALLOW_INVALID_OR_MISSING_CLIENT_CERT`).

### 1.2 Why we enable it

- **Only known systems can reach the endpoint.** Unknown or anonymous internet clients are refused at the edge of the load balancer, before Cloud Armor or Fusion see the request. This removes the endpoint from drive-by scanning and credential-guessing.
- **Defense in depth for APIs.** A second factor (possession of a CA-issued certificate) sits in front of the existing Fusion credentials (users, API keys, OAuth/JWT).
- **Customer security and compliance requirements** for API-to-API and zero-trust access (e.g. PCI-DSS, HIPAA, internal policy).

### 1.3 What it does not do

- **It is not user login.** Fusion authentication and authorization are still required behind it.
- **It is not end-to-end.** TLS and the client certificate end at the load balancer. The hop from the load balancer to the backend is whatever the backend service protocol is (HTTP on port 80 for st-micro). The client's identity only reaches the backend if we forward it as headers (step 6).
- **It does not check revocation.** The load balancer does no CRL/OCSP checks. A compromised client certificate stays valid until it expires or its CA is removed from the trust config.
- **It covers only the proxy it is attached to.** Other listeners and proxies (for example a plain-HTTP port 80 listener sharing the same URL map, or a direct path to the cluster ingress) are not protected.
- **It does not hide the endpoint.** DNS and the IP remain public; unauthorized clients can still open a connection, they just fail the handshake.

### 1.4 Implications of enabling it

| Area | Implication |
|---|---|
| **Every caller needs a certificate** | In `REJECT_INVALID` mode, any client that cannot present a valid certificate is cut off. This includes server-side apps, scheduled jobs, monitoring and synthetic tests, third-party integrations **and browsers** (people using the Fusion UI). |
| **Whole hostname, no exceptions** | The policy applies to every host and path served by the proxy. There is no way to exempt a path (for example a health endpoint or the UI) while protecting another. |
| **Failures look like network errors** | A rejected client sees a TLS handshake failure, not an HTTP 401/403. There is no HTTP response, and rejected handshakes may not appear in load balancer logs, the backend, or Fusion. Troubleshooting is harder; a drop in request volume is often the first symptom. |
| **Certificate lifecycle becomes an operational duty** | Client certs and the CA expire. An expired CA or client cert is an outage for those clients. Someone must own issuance, renewal, rotation and alerting. |
| **Intermediaries can break it** | A corporate TLS-inspecting proxy, CDN or WAF in front of the load balancer terminates TLS itself, so the client certificate never reaches us. |
| **Dependency on the customer's PKI** | Trust is whatever the CA(s) in the trust config sign. Changing or rotating the CA is a coordinated change with the customer. |
| **Weaker, not stronger, if left in observe mode** | `ALLOW_INVALID_OR_MISSING_CLIENT_CERT` enforces nothing. It exists to gather evidence safely and must be a time-boxed step. |
| **Managed outside Terraform** | These resources are created by gcloud, so they are not in any state file and will not be reconciled. Track them in the customer config repo and the change ticket. |
| **Reversible quickly** | Switching back to observe mode or detaching the policy takes minutes (section 7). The cost of a mistake is minutes of client outage, not data loss. |

---

## 2. What this changes

mTLS on a Google load balancer is three resources plus one attachment. None of them replaces or modifies the existing certificate map, URL map or backend service. (Step 8, variant A, does edit the customer's consolidated load balancer when that is reused for the admin hostname; it is backed up first.)

```
 Client ──TLS + client cert──▶ Target HTTPS proxy ──▶ URL map ──▶ Backend service ──▶ NEG ──▶ api-gateway pods
                                  │  ├─ certificateMap  (existing, server cert, unchanged)
                                  │  ├─ sslPolicy       (existing, unchanged)
                                  │  └─ serverTlsPolicy (NEW) ──▶ Trust config (NEW) ──▶ client CA PEM files
                                  
 Backend service (optional NEW): custom request headers carrying client-cert details to the backend
```

| # | Resource | gcloud group | Purpose |
|---|---|---|---|
| 1 | Trust config | `gcloud certificate-manager trust-configs` | Holds the client CA chain (root = trust anchor, plus intermediates) the LB validates client certs against |
| 2 | Server TLS policy | `gcloud network-security server-tls-policies` | Says "validate clients against trust config X in mode Y" |
| 3 | Attachment | `gcloud compute target-https-proxies update --server-tls-policy` | Turns it on for one HTTPS proxy |
| 4 | (Optional) request headers | `gcloud compute backend-services update --custom-request-header` | Passes `client_cert_present`, `client_cert_chain_verified`, etc. to the backend |

**The policy applies to the whole HTTPS proxy, i.e. every hostname served by that proxy.** There is no per-path or per-host mTLS.

---

## 3. Pre-work (complete before step 1)

Most of this is customer-side and has long lead times (client inventory, CA, change approval). Start it first. Plan on one to two weeks before the first change in dev. Outputs go in the change ticket.

### 3.1 Pre-work checklist

| # | Item | Owner | Output |
|---|---|---|---|
| 1 | Customer sponsor and security contact named; purpose agreed ([section 1](#1-purpose-of-mtls-and-what-enabling-it-means)) | Lucidworks CSM + customer | Names, agreed goal |
| 2 | **Identify every caller of each hostname** ([3.2](#32-identify-the-callers-of-each-hostname)) | Lucidworks Cloud Ops | Caller inventory per hostname |
| 3 | **Classify callers and decide how browsers are handled** ([3.3](#33-classify-the-callers-and-decide-on-browsers)) | Lucidworks + customer | Decision per hostname; if option (a): admin hostname name and the allowed CIDR ranges (customer egress/VPN, Lucidworks support) |
| 4 | **Client CA decision and CA material** ([section 5](#5-determining-the-client-ca)) | Customer | Root/intermediate PEMs, test client cert |
| 5 | **Client technical readiness**, including intermediaries ([3.4](#34-confirm-client-technical-readiness)) | Customer | Per-client readiness and owner |
| 6 | **Baseline metrics captured** ([3.5](#35-capture-baseline-metrics)) | Lucidworks Cloud Ops | Request volume baseline per hostname |
| 7 | **Logging and retention fit the bake time** ([3.6](#36-check-observability)) | Lucidworks Cloud Ops | Retention and sampling recorded |
| 8 | **Bypass paths checked** ([3.7](#37-check-for-bypass-paths)) | Lucidworks Cloud Ops | List of other listeners / direct paths |
| 9 | **Access and permissions confirmed** ([3.8](#38-confirm-access)) | Lucidworks Cloud Ops | Read-only step 1 commands succeed |
| 10 | **Change management and customer communication** ([3.9](#39-change-management-and-communication)) | Lucidworks + customer | Approved change ticket, windows, comms sent |

### 3.2 Identify the callers of each hostname

Enforcement blocks anything that is not on the list, so the list must come from evidence, not from the customer's memory. Use all four methods; each finds callers the others miss. Run this per hostname (each proxy gets its own inventory).

**Method 1: load balancer request logs (primary evidence).** Aggregate by user-agent class, first two path segments and status. Run it **one day at a time**: `gcloud logging read --limit=N` returns only the *newest* N entries, which can be only a couple of hours of a busy hostname. A quick check on st-micro found that 3000 entries covered roughly 1 day on dev and 2 hours on prod.

```bash
# Requires jq. FWD_RULE is the HTTPS forwarding rule (step 1a). Uses the LB logs for the window given.
callers() {   # usage: callers <start-iso> <end-iso>
  gcloud logging read \
    "resource.type=\"http_load_balancer\" AND resource.labels.forwarding_rule_name=\"${FWD_RULE}\" AND timestamp>=\"$1\" AND timestamp<\"$2\"" \
    --project="$PROJECT_ID" --limit=50000 --format=json \
  | jq -r '.[] | try ([((.httpRequest.userAgent // "-") | if test("Mozilla") then "browser" elif test("^[A-Za-z0-9._-]+(/|$)") then (split("/")[0]) else "other" end), ((.httpRequest.requestUrl // "") | sub("https?://[^/]+";"") | split("?")[0] | split("/")[1:3] | join("/")), ((.httpRequest.status // 0) | tostring)] | @tsv) catch "UNPARSEABLE"' \
  | sort | uniq -c | sort -rn | head -40
}

callers 2026-11-10T00:00:00Z 2026-11-11T00:00:00Z     # repeat for each day in the last 14 days, weekdays and weekend
```

Columns: count, user-agent class, path prefix, HTTP status. Then list which source networks each non-browser client comes from:

```bash
gcloud logging read \
  "resource.type=\"http_load_balancer\" AND resource.labels.forwarding_rule_name=\"${FWD_RULE}\" AND timestamp>=\"<start>\" AND timestamp<\"<end>\"" \
  --project="$PROJECT_ID" --limit=50000 --format="value(httpRequest.userAgent,httpRequest.remoteIp)" \
  | cut -c1-80 | sort | uniq -c | sort -rn | head -40
```

How to read it:
- **Browser user agents** on `/`, `/auth`, `/admin`, `/apps` are people using the Fusion UI.
- **Named non-browser agents** (`node-fetch`, `Python`, `Java`, `Go-http-client`, `Datadog`, ...) on `/api/...` are applications, jobs and monitors. These are the clients that must get certificates.
- **Scanners** show up as browser-like user agents on odd paths (`/.env`, `actuator`, `swagger-ui`, `remote/login`) with 401/404 responses, or as named scanners (Censys, Palo Alto). Do not put them on the client list. Blocking them is part of the goal.
- A browser user agent proves nothing on its own (scanners spoof it); judge by path and status.
- If the log bucket's retention (3.6) is shorter than the window you need, query the exported copy instead (3.6).
- Source IPs are often a customer NAT or proxy and cannot identify one system. Use them to confirm the network, not the application.

**Method 2: what Fusion knows.** Fusion's own configuration names the intended API callers: the list of users and service accounts, API keys and OAuth/JWT clients. For each, ask the owning team how it calls Fusion. Compare against Method 1: any credential that never appears in the logs is either dormant or calls from somewhere you have not looked.

**Method 3: cluster-side logs.** The api-gateway access logs add the forwarded client address and the authenticated principal. Use these to tie an anonymous `node-fetch` in the LB logs to a named service account. (For st-micro the backend services are NEGs that point straight at api-gateway pods, so requests through the global LB do not pass through ingress-nginx; ingress-nginx logs only show traffic that arrives by the direct ingress path described in [3.7](#37-check-for-bypass-paths).)

**Method 4: ask, with a checklist.** Send the customer security contact and the application owners this list:
- Applications and back-ends that call the API (search front-ends, e-commerce or portal back-ends, ETL and indexing jobs, signal/event collectors).
- Scheduled jobs and scripts (cron, Airflow, Jenkins, GitHub Actions).
- Monitoring and synthetic tests (Datadog Synthetics, Pingdom, uptime checks) and the customer's own load/performance test tools. (Lucidworks load tests are handled in [section 9](#9-load-testing-after-mtls).)
- Third-party and partner integrations, webhooks and callbacks into the hostname.
- Server-to-server legs of SSO/OIDC/SAML flows (browser redirects are not an issue; back-channel calls are).
- Lucidworks-side tooling that calls the public hostname (monitoring, support access, data-load jobs).

Note: Google load balancer **health checks** reach the backends directly, not through the HTTPS proxy, so mTLS does not affect them.

**Record the result** as an inventory per hostname:

| Client | Type | Evidence (agent / path / source network) | Volume | Owner | Can present a cert? | Plan |
|---|---|---|---|---|---|---|
| e.g. search front-end | server-side app | `node-fetch`, `/api/.../query-pipelines`, `/api/signals` | high | customer app team | to confirm | cert via customer PKI |

### 3.3 Classify the callers and decide on browsers

Put every row of the inventory into one of these groups:

| Group | Treatment |
|---|---|
| **Server-side application / job / automation** | Gets a client certificate. These are the clients mTLS is for. |
| **Monitoring and synthetic checks** (e.g. Datadog Synthetics) | Must be configured to send a client certificate in each test, or they will alarm once enforcement starts. Confirm the tool supports client certificates and who administers it. |
| **Lucidworks internal tooling** | Load tests use the admin hostname or a load-test client cert ([section 9](#9-load-testing-after-mtls)). Other tooling gets a client cert (from the customer's CA) or is moved off the public hostname. |
| **Browser (people using the UI)** | **Cannot be silently included.** See below. |
| **Scanners / unknown** | Expected to be blocked. Confirm none is a legitimate system. |

**If a hostname has browser users, you must pick one of these before enforcing on it:**

| Option | Result | Cost |
|---|---|---|
| (a) **Split traffic**: API clients keep the existing hostname (mTLS), people get a new admin hostname with no mTLS and an IP allow-list ([step 8](#step-8-create-the-admin-hostname-only-where-people-or-other-non-certificate-clients-must-keep-access)). It is added to the customer's consolidated load balancer where one exists, otherwise to a dedicated proxy | Clean separation; strongest | A host rule and DNS CNAME on the consolidated load balancer (or a new IP, proxy, URL map and forwarding rule); allowed CIDR ranges from the customer; administrators change their URL |
| (b) **Stay in observe mode** (`ALLOW_INVALID_OR_MISSING_CLIENT_CERT`) permanently and enforce in the application from the forwarded headers | UI keeps working; no handshake-level blocking | Not true enforcement; anything the app does not check is open |
| (c) **Issue client certs to users' browsers** | Whole hostname enforced | Operational burden; only realistic for a small known user group |
| (d) **Do not enforce on that hostname** | No change for the UI | No protection on that hostname |

An environment with **no** browser traffic (API only) needs no accommodation for people, but still needs the admin hostname for Lucidworks load testing ([section 9](#9-load-testing-after-mtls)).

### 3.4 Confirm client technical readiness

For each client in the inventory, the customer confirms:

- It can send a client certificate and key. Typical hooks: Node `new https.Agent({ cert, key })` (passed as `agent` to `node-fetch`), Python `requests.get(url, cert=("client.pem", "client.key"))`, Java `javax.net.ssl.keyStore` or an `SSLContext`, curl `--cert/--key`.
- It negotiates TLS 1.2 or higher with ciphers allowed by the proxy's SSL policy (st-micro: `modern-policy`, RESTRICTED profile).
- **There is no TLS-terminating device between the client and the load balancer** (corporate TLS-inspecting proxy, CDN, WAF, API gateway, another reverse proxy). If there is, the certificate never reaches us; the device must pass TLS through or present a certificate itself.
- The private key has a secure home (secret store) and there is a plan for renewal and rotation before the certificate expires.
- It has a way to be tested: the customer's test client certificate works from the client's real network egress (`curl --cert/--key` from there), not just from a laptop.

### 3.5 Capture baseline metrics

Needed for step 11: with `REJECT_INVALID` rejected handshakes may not be logged, so a fall in request volume is the main signal of blocked clients.

```bash
# Per day, per status. Repeat for the last 14 days and keep the numbers in the ticket.
gcloud logging read \
  "resource.type=\"http_load_balancer\" AND resource.labels.forwarding_rule_name=\"${FWD_RULE}\" AND timestamp>=\"<day-start>\" AND timestamp<\"<day-end>\"" \
  --project="$PROJECT_ID" --limit=50000 --format="value(httpRequest.status)" | sort | uniq -c | sort -rn
```

Also record the peak hour and the typical request count for the hours of the planned change window.

### 3.6 Check observability

```bash
# Log retention (days) and whether Log Analytics is on, for the bucket holding LB logs
gcloud logging buckets describe _Default --location=global --project="$PROJECT_ID" --format="value(retentionDays,analyticsEnabled)"

# Export sinks that already copy LB logs elsewhere (e.g. BigQuery) for a longer history
gcloud logging sinks list --project="$PROJECT_ID" --format="table(name,destination)"

# Backend request logging must be on, ideally sample rate 1.0
gcloud compute backend-services describe "$BACKEND" --global --project="$PROJECT_ID" --format="yaml(logConfig)"
```

- The retention must cover the planned bake time. If not, add a sink to a bucket or BigQuery dataset **before** starting.
- At sample rate below 1.0 the inventory is incomplete; low-volume clients (a nightly job) may be missing.
- If the sinks list shows exports of LB logs to a central BigQuery dataset, that is the better place to run multi-week caller queries.
- **A nightly or monthly job will not show up in a 7-day window.** Extend the window to cover the longest known job cycle and ask the customer about anything periodic.

### 3.7 Check for bypass paths

mTLS only protects the proxy it is attached to. Before relying on it, confirm there is no other way in:

- **HTTP port 80 listener on the same URL map** (step 1b). If one exists, either redirect HTTP to HTTPS or remove it.
- **Other proxies or load balancers pointing at the same backend service or the same cluster.** The admin hostname added in step 8 is an intentional one and is restricted by its allow-list; any other is a bypass.
- **Direct access to the cluster ingress (high priority).** Each Fusion cluster normally also has its own public network load balancer in front of ingress-nginx, separate from the global LB. If it is open to the internet and ingress-nginx routes the Fusion hostname to api-gateway, anyone can skip the global LB, and mTLS, by connecting to that IP with the right Host header. Check:
  ```bash
  # Public network LBs fronting ingress-nginx, and whether the firewall limits who can reach them
  gcloud compute forwarding-rules list --project="$PROJECT_ID" \
    --filter="description~ingress-nginx" --format="table(name,IPAddress,portRange,region.basename())"
  gcloud compute firewall-rules list --project="$PROJECT_ID" --filter="name~^k8s-fw- AND direction=INGRESS" \
    --format="table(name,sourceRanges.list(),allowed[].map().firewall_rule().list())"

  # Does it serve Fusion without mTLS? A real response (not a 404/default backend) means yes.
  curl -sk -o /dev/null -w "%{http_code}\n" --resolve "${HOSTNAME_FQDN}:443:<ingress-ip>" "https://${HOSTNAME_FQDN}/"
  ```
  **st-micro:** the firewall rules for these network LBs allow `0.0.0.0/0` on 80 and 443 (prod `34.76.106.90`, DNS `stmicro-prod-ingress.b.lucidworks.cloud`; non-prod `34.79.197.217`, `stmicro-non-prod-ingress...`; prod-a `34.47.135.183`). Whether they route to Fusion has not been tested. Do this before relying on mTLS. If they do, restrict them (firewall source ranges, or `loadBalancerSourceRanges` on the ingress service in the customer config) as part of the rollout, taking care not to break cert-manager HTTP-01 validation or anything else that legitimately uses them.
- **Other hostnames** for the same Fusion (DNS records pointing at the same IP).

### 3.8 Confirm access

- Roles and APIs in [4.2](#42-tooling-and-access) are in place for the engineers doing the change (the same people who run rollback).
- The read-only commands in step 1 run successfully from the engineer's own machine with `--project` set.
- Check for organization policies that restrict enabling APIs or creating security resources. They would fail at step 2 or 5 and are better found now.

### 3.9 Change management and communication

- Change ticket per environment with the plan from [section 8](#8-rollout-order), rollback plan ([section 7](#7-rollback)), and the evidence from 3.2 to 3.7 attached.
- **Customer notification before each phase** covering: what is changing and why, the date and window, what clients will see if something is wrong, how a client obtains and tests a certificate, who to contact, and the rollback criteria. Send the enforcement notice well before the change (the customer's clients must be ready), not on the day.
- Windows chosen for low traffic using the 3.5 baseline, and outside the customer's business hours in the region (st-micro runs in europe-west1).
- Rollback owner named and on the call; rollback commands open in a second terminal (step 7).
- Anyone who can be paged by a monitoring alert on the hostname (Datadog Synthetics, uptime checks) is told in advance.

---

## 4. Before you start

### 4.1 Decision gates (do not proceed until each is answered and recorded in the change ticket)

1. **Who are the clients, and can all of them present a client certificate?** The answer comes from the pre-work inventory ([3.2](#32-identify-the-callers-of-each-hostname)–[3.4](#34-confirm-client-technical-readiness)). `REJECT_INVALID` drops every connection without a valid client cert at the TLS handshake, before any HTTP happens. This **includes browsers**. If humans reach the Fusion UI through the same hostname (the Fusion api-gateway serves both UI and API on one host), enforcement will lock them out. If the hostname serves both browsers and API clients, stop and apply one of the options in [3.3](#33-classify-the-callers-and-decide-on-browsers).
2. **Who issues client certificates?** See [section 5](#5-determining-the-client-ca).
3. **Are there other listeners that reach the same backend without TLS?** An HTTP (port 80) forwarding rule that shares the URL map bypasses mTLS entirely. Check in step 1.
4. **Change window, rollback owner and customer contact** are named for each environment.

### 4.2 Tooling and access

- `gcloud` recent enough to have `gcloud network-security server-tls-policies` and `--server-tls-policy` on `target-https-proxies update` (tested with SDK 587.0.0), `openssl`, `curl`.
- **Always pass `--project`.** Engineers' default gcloud project is usually another customer.
- IAM on the customer project (from Google's setup guide): `roles/compute.loadBalancerAdmin`, `roles/certificatemanager.owner`, `roles/compute.networkAdmin`, `roles/compute.securityAdmin`, plus permission to enable APIs (`roles/serviceusage.serviceUsageAdmin`) the first time.
- APIs required: Compute Engine, Certificate Manager, **Network Security**, **Network Services**. Compute and Certificate Manager are normally already on. Network Security is not (step 2).
- Secret Manager is **not** required. The CA certificate is public, and the trust config is the source of truth in GCP. Keep the PEM files in the customer config repo or the team vault instead. (The Terraform guide uses Secret Manager only to feed Terraform.)

### 4.3 Set variables

Set these once per environment and reuse them in every step. Values for st-micro are in [Appendix A](#appendix-a-customer-parameter-sheet).

```bash
export PROJECT_ID="<customer-gcp-project>"          # e.g. mf-stmicroelectronics
export CUSTOMER="<short-customer-name>"             # e.g. stmicro
export ENV_NAME="<dev|stg|prd>"                     # one LB / proxy at a time
export PROXY="<target-https-proxy-name>"            # discovered in step 1
export URL_MAP="<url-map-name>"
export BACKEND="<backend-service-name>"
export FWD_RULE="<https-forwarding-rule-name>"
export HOSTNAME_FQDN="<public-hostname>"            # e.g. stmicro-dev.b.lucidworks.cloud

export TRUST_CONFIG="${CUSTOMER}-<non-prod|prod>-mtls-trust-config"
export POLICY="${CUSTOMER}-${ENV_NAME}-mtls-policy"
export WORKDIR="$HOME/mtls-${CUSTOMER}-${ENV_NAME}"; mkdir -p "$WORKDIR/backup" && cd "$WORKDIR"
```

Naming: one **trust config per environment group** (non-prod, prod) so CA changes can be rolled out independently of prod; one **server TLS policy per proxy** so each proxy's mode (ALLOW vs REJECT) can be changed independently.

---

## 5. Determining the client CA

The load balancer only needs the **public** certificates of the CA(s) that sign client certs. It never needs a private key. The real question is who owns client-cert issuance.

| Option | When | What we need | Notes |
|---|---|---|---|
| **A. Customer's own PKI (recommended)** | Customer already has an enterprise CA or can issue certs to their systems | Root CA cert (PEM) and any intermediate CA certs (PEM); a list of the systems that will present certs; the cert profile they will issue | Customer controls issuance, rotation and revocation. We only hold public certs. Default choice. |
| **B. Lucidworks-operated CA** | Customer has no PKI and wants us to provide one | We run a private CA (e.g. Google CA Service) and issue/rotate client certs | Makes us the custodian of CA keys and of issuance and rotation. Needs a security review before use in prod. Avoid unless the customer insists. |
| **C. Throwaway test CA** | Proving the mechanics in dev before real certs exist | Nothing from the customer | [Appendix B](#appendix-b-throwaway-test-ca-for-dev-validation). Never use in prod. |

**What to ask the customer for (Option A):**

1. Root CA certificate and every intermediate in the issuing chain, PEM, public parts only.
2. A test client certificate and key signed by that chain, for us to validate each phase (REJECT mode cannot be tested without one).
3. Inventory of systems that call the API and how each will present a cert (library, proxy, secrets handling).
4. Cert profile: must meet the LB's limits: RSA 2048 to 4096 or ECDSA P-256/P-384; `clientAuth` extended key usage; chain depth at most 10; leaf under 16 KB. A missing `clientAuth` EKU fails validation unless the policy is relaxed with `ALLOW_VALIDATION_RELAXATIONS`.
5. Client cert lifetime and rotation schedule (drives the follow-up alerting).
6. Confirmation that browser/UI users either do not use this hostname or are handled per gate 1 above.

**Limits to keep in mind:** the LB does **not** do revocation checks (no CRL/OCSP). Revocation means removing the CA, or issuing short-lived client certs. The trust config holds at most 200 anchors + intermediates.

**The trust anchor must be a root.** If the customer only hands over an intermediate, ask for its root. Put roots in `trust-anchors` and intermediates in `intermediate-cas`.

---

## 6. Procedure (repeat for each environment / proxy)

Run each step to completion and check its verification before moving on. Record command output in the change ticket.

### Step 1: Discover and baseline (read-only)

```bash
# 1a. Find the HTTPS proxy that uses the URL map, and the forwarding rule that uses the proxy
gcloud compute target-https-proxies list --project="$PROJECT_ID" \
  --filter="urlMap~/${URL_MAP}\$" \
  --format="table(name,urlMap.basename(),certificateMap.basename(),sslPolicy.basename(),serverTlsPolicy.basename(),quicOverride)"

gcloud compute forwarding-rules list --global --project="$PROJECT_ID" \
  --filter="target~/${PROXY}\$" \
  --format="table(name,IPAddress,portRange,target.basename(),loadBalancingScheme)"

# 1b. Bypass check: any HTTP (port 80) proxy / forwarding rule on the SAME url map?
gcloud compute target-http-proxies list --project="$PROJECT_ID" \
  --filter="urlMap~/${URL_MAP}\$" --format="table(name,urlMap.basename())"
```

- `SERVER_TLS_POLICY` must be empty. If not, stop: something already attached a policy.
- If 1b returns an HTTP proxy, port 80 reaches the same backend with no TLS, so mTLS can be bypassed. Record it and see [follow-ups](#10-follow-up-steps).

```bash
# 1c. Backend: existing custom headers (step 6 REPLACES this list), logging, Cloud Armor
gcloud compute backend-services describe "$BACKEND" --global --project="$PROJECT_ID" \
  --format="yaml(name,protocol,port,customRequestHeaders,logConfig,securityPolicy)"

# 1d. Certificate map and SSL policy the proxy uses (unchanged by this runbook)
gcloud compute target-https-proxies describe "$PROXY" --global --project="$PROJECT_ID" \
  --format="yaml(certificateMap,sslPolicy,quicOverride)"

# 1e. Back up current config (needed for full rollback)
gcloud compute target-https-proxies export "$PROXY" --global --project="$PROJECT_ID" \
  --destination="backup/${PROXY}.pre-mtls.yaml"
gcloud compute backend-services export "$BACKEND" --global --project="$PROJECT_ID" \
  --destination="backup/${BACKEND}.pre-mtls.yaml"

# 1f. Functional baseline
curl -sS -o /dev/null -w "baseline https status: %{http_code}\n" "https://${HOSTNAME_FQDN}/"
```

**Verify:** `serverTlsPolicy` empty, backups written, baseline status recorded.

### Step 2: Enable APIs (once per project)

```bash
gcloud services list --enabled --project="$PROJECT_ID" \
  --format="value(config.name)" | grep -E "certificatemanager|compute|networksecurity|networkservices"

gcloud services enable networksecurity.googleapis.com networkservices.googleapis.com \
  --project="$PROJECT_ID"
```

No traffic impact. **Verify:** all four services are listed on re-run.

### Step 3: Validate the CA material locally

Place `root.pem` and (if any) `intermediate.pem` in `$WORKDIR/ca/`. Multiple certs may be in one file.

```bash
cd "$WORKDIR/ca"
for f in root.pem intermediate.pem; do [ -f $f ] || continue
  echo "== $f"; openssl x509 -in $f -noout -subject -issuer -dates -fingerprint -sha256
  openssl x509 -in $f -noout -ext basicConstraints        # expect CA:TRUE
  openssl x509 -in $f -noout -text | grep -E "Public Key Algorithm|Public-Key|Signature Algorithm" | sort -u
done
```

With the customer's test client cert (`client.pem`):

```bash
openssl verify -CAfile root.pem -untrusted intermediate.pem -purpose sslclient client.pem   # expect: OK
```

**Verify:** roots are `CA:TRUE`, none expired, key sizes within LB limits, test client cert verifies with `-purpose sslclient`. Do not continue otherwise.

### Step 4: Create the trust config

```bash
gcloud certificate-manager trust-configs create "$TRUST_CONFIG" \
  --project="$PROJECT_ID" --location=global \
  --description="Client CA for mTLS (${CUSTOMER})" \
  --labels="customer=${CUSTOMER},purpose=mtls,created-by=gcloud-runbook" \
  --trust-store="trust-anchors=$WORKDIR/ca/root.pem,intermediate-cas=$WORKDIR/ca/intermediate.pem"
  # no intermediates:  --trust-store="trust-anchors=$WORKDIR/ca/root.pem"
  # several intermediates: intermediate-cas="a.pem;b.pem"  (quoted, semicolon-separated)
```

Note: `--trust-store` takes **file paths**, not PEM contents. The Terraform guide's gcloud snippet that passes `"$CA_CERT"` will not work.

```bash
gcloud certificate-manager trust-configs describe "$TRUST_CONFIG" \
  --project="$PROJECT_ID" --location=global
```

**Verify:** `trustStores[0].trustAnchors` contains the root; `intermediateCas` as expected.

### Step 5: Create the server TLS policy in observe mode

```bash
cat > "$WORKDIR/${POLICY}.yaml" <<EOF
name: ${POLICY}
description: mTLS for ${PROXY}
mtlsPolicy:
  clientValidationMode: ALLOW_INVALID_OR_MISSING_CLIENT_CERT
  clientValidationTrustConfig: projects/${PROJECT_ID}/locations/global/trustConfigs/${TRUST_CONFIG}
EOF

gcloud network-security server-tls-policies import "$POLICY" \
  --source="$WORKDIR/${POLICY}.yaml" --location=global --project="$PROJECT_ID"

gcloud network-security server-tls-policies describe "$POLICY" \
  --location=global --project="$PROJECT_ID"
```

The policy does nothing until attached. **Verify:** `clientValidationMode` is `ALLOW_INVALID_OR_MISSING_CLIENT_CERT` and the trust config path is correct.

### Step 6: (Recommended) forward client-cert details to the backend

This lets the backend see whether a request came with a valid cert. It is the only per-request signal available in observe mode.

> `--custom-request-header` **replaces** the backend's whole custom-header list. Merge in anything found in step 1c.

```bash
gcloud compute backend-services update "$BACKEND" --global --project="$PROJECT_ID" \
  --custom-request-header='X-Client-Cert-Present:{client_cert_present}' \
  --custom-request-header='X-Client-Cert-Chain-Verified:{client_cert_chain_verified}' \
  --custom-request-header='X-Client-Cert-Error:{client_cert_error}' \
  --custom-request-header='X-Client-Cert-Subject-Dn:{client_cert_subject_dn}' \
  --custom-request-header='X-Client-Cert-Serial-Number:{client_cert_serial_number}' \
  --custom-request-header='X-Client-Cert-Hash:{client_cert_sha256_fingerprint}'

gcloud compute backend-services describe "$BACKEND" --global --project="$PROJECT_ID" \
  --format="yaml(customRequestHeaders)"
```

Headers are inert until the proxy has a policy. To record them per request, add them to the api-gateway access log (see follow-ups).

### Step 7: Attach the policy to the proxy (observe mode)

Have the rollback commands from [section 7](#7-rollback) open in a second terminal.

```bash
gcloud compute target-https-proxies update "$PROXY" --global --project="$PROJECT_ID" \
  --server-tls-policy="projects/${PROJECT_ID}/locations/global/serverTlsPolicies/${POLICY}"

gcloud compute target-https-proxies describe "$PROXY" --global --project="$PROJECT_ID" \
  --format="yaml(name,serverTlsPolicy,certificateMap,sslPolicy)"
```

If `--server-tls-policy` is rejected by your gcloud version, use Google's documented export/import path instead:

```bash
gcloud compute target-https-proxies export "$PROXY" --global --project="$PROJECT_ID" --destination="$WORKDIR/${PROXY}.yaml"
echo "serverTlsPolicy: //networksecurity.googleapis.com/projects/${PROJECT_ID}/locations/global/serverTlsPolicies/${POLICY}" >> "$WORKDIR/${PROXY}.yaml"
gcloud compute target-https-proxies import "$PROXY" --global --project="$PROJECT_ID" --source="$WORKDIR/${PROXY}.yaml"
```

Wait a few minutes for global propagation, then test:

```bash
# No client cert: must behave exactly as the step 1f baseline
curl -sS -o /dev/null -w "no cert:        %{http_code}\n" "https://${HOSTNAME_FQDN}/"

# Valid client cert (customer-supplied test cert)
curl -sS -o /dev/null -w "valid cert:     %{http_code}\n" --cert client.pem --key client.key "https://${HOSTNAME_FQDN}/"

# Handshake detail
openssl s_client -connect "${HOSTNAME_FQDN}:443" -servername "${HOSTNAME_FQDN}" -cert client.pem -key client.key </dev/null 2>&1 | grep -E "Verify return|Protocol|Cipher"
```

**Verify (all must hold before leaving this step):**
- No-cert request returns the baseline status; valid-cert request succeeds.
- The server certificate presented is still the expected wildcard cert (the certificate map still works with a server TLS policy attached). **Dev is the proof point for this combination**: Google's mTLS docs do not explicitly address certificate maps. If this fails in dev, roll back and stop; do not proceed to stg or prod.
- Existing `modern-policy` (TLS 1.2, RESTRICTED profile) does not break the test client.

### Step 8: Create the admin hostname (only where people or other non-certificate clients must keep access)

Do this step for **every hostname that will enforce mTLS**. Two groups need a way in that does not require a client certificate: people (for example Fusion administrators; option (a) in [3.3](#33-classify-the-callers-and-decide-on-browsers)) and Lucidworks load tests ([section 9](#9-load-testing-after-mtls)). When no people need it, the admin hostname's allow-list contains only the Lucidworks load-test egress range.

The admin hostname must be served by a proxy that has **no server TLS policy**, and it must only serve the admin hostname (never answer for the main Fusion hostname). There are two ways to get that. Choose one per customer:

| Variant | Use when | What it changes |
|---|---|---|
| **A. Add to the existing consolidated load balancer** (st-micro) | The customer has a consolidated `*-clb` load balancer (ArgoCD, Grafana) that will **not** enforce mTLS | Adds one host rule and one DNS CNAME. Edits the consolidated URL map and the consolidated HTTP proxy's URL map (backed up first). Also closes the plain-HTTP exposure on that load balancer. |
| **B. Dedicated proxy** | No consolidated load balancer exists, or it will later enforce mTLS | Creates only new resources: IP, URL map, HTTPS proxy, forwarding rule, DNS records. Nothing existing is touched. |

**Constraint for variant A:** the consolidated HTTPS proxy must never get a server TLS policy while it carries admin hostnames. If mTLS is later wanted on the consolidated load balancer, move the admin hostnames to a dedicated proxy (variant B) first.

Both variants finish with the same two sub-steps: **8h** (restrict who can reach the admin hostname) and **8i** (Fusion and people checks).

Set the admin hostname (it must be **one label** under the wildcard, e.g. `customer-admin.b.lucidworks.cloud`; `admin.customer.b.lucidworks.cloud` would not be covered):

```bash
export ADMIN_HOSTNAME="<name>.b.lucidworks.cloud"          # st-micro values: Appendix A
```

#### Variant A: add the admin hostname to the existing consolidated load balancer

How it works: the consolidated URL map is already host-scoped (a host rule per application, and unknown hosts fall through to the ArgoCD backend). We add a host rule for the admin hostname that points at the Fusion backend. The main Fusion hostname has no rule on this URL map, so sending it to the consolidated IP lands on the default service (ArgoCD), never on Fusion. That is what prevents anyone reaching Fusion without a certificate by sending the main hostname to the admin IP.

Order of work for one consolidated load balancer:

1. **8A-1** discover, **8A-2** back up, **8A-3** fix the port-80 exposure: **once per consolidated load balancer**.
2. **8A-4** add the admin host rule, **8A-5** DNS, **8A-6** verify: **once per environment** (for st-micro non-prod, once for dev and once for stg, on the same consolidated URL map). Take a fresh backup (8A-2) before each environment's change.

```bash
export CLB_PREFIX="lw-${CUSTOMER}-<non-prod|prod>-clb"            # st-micro: lw-stmicro-non-prod-clb, lw-stmicro-prod-clb
export CLB_URL_MAP="${CLB_PREFIX}-url-map"
export CLB_HTTPS_PROXY="${CLB_PREFIX}-https-proxy"
export CLB_HTTP_PROXY="${CLB_PREFIX}-http-proxy"
export CLB_HTTP_FWD_RULE="${CLB_PREFIX}"                          # port 80
export CLB_HTTPS_FWD_RULE="${CLB_PREFIX}-https"                   # port 443
export CLB_DNS="${CUSTOMER}-<non-prod|prod>-consolidated.b.lucidworks.cloud."   # existing A record, used as the CNAME target
export CLB_REDIRECT_URL_MAP="${CLB_PREFIX}-http-redirect-url-map"
export ADMIN_MATCHER="admin-${ENV_NAME}"                          # path matcher name, one per environment
export CLB_BACKUP="$WORKDIR/backup-clb/$(date -u +%Y%m%dT%H%M%SZ)"; mkdir -p "$CLB_BACKUP"
```

**8A-1. Discover (read-only)**

```bash
gcloud compute url-maps describe "$CLB_URL_MAP" --global --project="$PROJECT_ID" \
  --format="yaml(defaultService,hostRules,pathMatchers[].name)"

# HTTPS proxy: serverTlsPolicy must be empty and must stay empty
gcloud compute target-https-proxies describe "$CLB_HTTPS_PROXY" --global --project="$PROJECT_ID" \
  --format="yaml(urlMap,certificateMap,sslPolicy,serverTlsPolicy)"

# HTTP proxy: if its urlMap is the same as $CLB_URL_MAP, port 80 serves the applications over plain HTTP
gcloud compute target-http-proxies describe "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" --format="yaml(urlMap)"

gcloud compute forwarding-rules list --global --project="$PROJECT_ID" --filter="name~^${CLB_PREFIX}" \
  --format="table(name,IPAddress,portRange,target.basename())"

# DNS: the existing A record that the admin CNAME will point at
gcloud dns record-sets list --zone=lucidworks-cloud --project=managed-fusion --filter="name=${CLB_DNS}" \
  --format="table(name,type,rrdatas)"

# Certificate coverage for the admin hostname
export CERT_MAP=$(gcloud compute target-https-proxies describe "$CLB_HTTPS_PROXY" --global --project="$PROJECT_ID" --format="value(certificateMap.basename())")
gcloud certificate-manager maps entries list --map="$CERT_MAP" --project="$PROJECT_ID" --format="table(name,hostname,matcher,certificates.basename())"
gcloud certificate-manager certificates describe <certificate-name-from-above> --location=global --project="$PROJECT_ID" --format="yaml(sanDnsnames,expireTime)"
```

**Verify:** `serverTlsPolicy` is empty on the consolidated HTTPS proxy; the A record exists; `ADMIN_HOSTNAME` matches a certificate SAN. Note whether the HTTP proxy shares the URL map (st-micro: it does, on both consolidated load balancers).

**8A-2. Back up the consolidated load balancer (before any change)**

```bash
# Everything this variant edits or depends on
gcloud compute url-maps export "$CLB_URL_MAP" --global --project="$PROJECT_ID" --destination="$CLB_BACKUP/${CLB_URL_MAP}.yaml"
gcloud compute target-https-proxies export "$CLB_HTTPS_PROXY" --global --project="$PROJECT_ID" --destination="$CLB_BACKUP/${CLB_HTTPS_PROXY}.yaml"
gcloud compute target-http-proxies export "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" --destination="$CLB_BACKUP/${CLB_HTTP_PROXY}.yaml"
for r in "$CLB_HTTP_FWD_RULE" "$CLB_HTTPS_FWD_RULE"; do
  gcloud compute forwarding-rules describe "$r" --global --project="$PROJECT_ID" --format=yaml > "$CLB_BACKUP/forwarding-rule-$r.yaml"
done
gcloud compute backend-services list --project="$PROJECT_ID" --filter="name~${CLB_PREFIX}-backend" --format=yaml > "$CLB_BACKUP/backend-services.yaml"
gcloud dns record-sets list --zone=lucidworks-cloud --project=managed-fusion --filter="name~^${CUSTOMER}" --format=yaml > "$CLB_BACKUP/dns-${CUSTOMER}.yaml"

# Dry run: prove the URL map backup is a valid, restorable file (validates only, changes nothing)
gcloud compute url-maps validate --source="$CLB_BACKUP/${CLB_URL_MAP}.yaml" --global --project="$PROJECT_ID"

# Baseline of what the load balancer serves today. List the existing hostnames from the URL map host rules (8A-1).
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do
  curl -sS -o /dev/null -w "$h https %{http_code}\n" "https://$h/"
done | tee "$CLB_BACKUP/baseline-https.txt"
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do
  curl -sS -o /dev/null -w "$h http %{http_code} %{redirect_url}\n" "http://$h/"
done | tee "$CLB_BACKUP/baseline-http.txt"

ls -l "$CLB_BACKUP"
```

Keep the backup directory with the change ticket (and in the customer config repo if that is the practice). The files contain resource names and IP addresses only, no secrets.

**Verify:** all files exist and are non-empty, and `url-maps validate` reports `loadSucceeded: true` and `testPassed: true`.

Before 8A-3, find out who actually uses port 80 today, so the redirect does not surprise anyone:

```bash
gcloud logging read \
  "resource.type=\"http_load_balancer\" AND resource.labels.forwarding_rule_name=\"${CLB_HTTP_FWD_RULE}\"" \
  --project="$PROJECT_ID" --freshness=7d --limit=20000 --format=json \
| jq -r '.[] | try ([((.httpRequest.requestUrl // "") | sub("^(?<s>https?)://(?<h>[^/]+).*"; "\(.s) \(.h)")), ((.httpRequest.userAgent // "-") | .[0:40]), ((.httpRequest.status // 0) | tostring)] | @tsv) catch "UNPARSEABLE"' \
| sort | uniq -c | sort -rn | head -20
```

Look for legitimate non-browser callers (webhooks, CLIs, scripts) that use `http://` and do not follow redirects; they must be moved to `https://` before or with this change. **st-micro, sampled 2026-11-18 (7 days, newest 20,000 requests):** prod is dominated by about 16k cert-manager HTTP-01 challenge requests for `stmicro-argocd.b.lucidworks.cloud`, all answered 404 today (a redirect does not change that outcome; if those challenges are supposed to succeed it is a separate misconfiguration). The rest is internet scanners and crawlers, plus some real browsers reaching ArgoCD over `http://` (200). Non-prod is almost all scanners and crawlers, with some browser traffic to ArgoCD.

**8A-3. Close the plain-HTTP exposure (once per consolidated load balancer)**

Today the HTTP proxy shares the application URL map, so ArgoCD and Grafana (and, after 8A-4, the admin hostname with the Fusion login) are served over port 80 without TLS. Give the HTTP proxy its own redirect-only URL map. This changes existing behaviour: anything using `http://` on this load balancer now receives a `302` to `https://`.

```bash
cat > "$WORKDIR/${CLB_REDIRECT_URL_MAP}.yaml" <<YAML
name: ${CLB_REDIRECT_URL_MAP}
defaultUrlRedirect:
  httpsRedirect: true
  redirectResponseCode: FOUND
YAML

gcloud compute url-maps import "$CLB_REDIRECT_URL_MAP" --global --project="$PROJECT_ID" \
  --source="$WORKDIR/${CLB_REDIRECT_URL_MAP}.yaml"

# Switch the HTTP proxy (port 80 only) to the redirect map. The HTTPS proxy is not touched.
gcloud compute target-http-proxies update "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" \
  --url-map="$CLB_REDIRECT_URL_MAP" --global-url-map
```

A `302` is used so browsers do not cache the redirect while it is being proven. Once stable it can be changed to `MOVED_PERMANENTLY_DEFAULT` by editing the YAML and importing again.

Wait a few minutes, then verify:

```bash
# Port 80 now redirects for every existing hostname; HTTPS is unchanged from the baseline
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do
  curl -sS -o /dev/null -w "$h http %{http_code} %{redirect_url}\n" "http://$h/"
done
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do
  curl -sS -o /dev/null -w "$h https %{http_code}\n" "https://$h/"
done | diff - "$CLB_BACKUP/baseline-https.txt" && echo "HTTPS identical to baseline"

gcloud compute target-http-proxies describe "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" --format="value(urlMap.basename())"   # = $CLB_REDIRECT_URL_MAP
gcloud compute target-https-proxies describe "$CLB_HTTPS_PROXY" --global --project="$PROJECT_ID" --format="value(urlMap.basename())" # = $CLB_URL_MAP
```

**Verify:** every `http://` request returns `302` to the matching `https://` URL, HTTPS statuses match the baseline, and each proxy points at the expected URL map. Tell the customer's ArgoCD and Grafana users before this change. If anything depends on plain HTTP, roll back with R2 below.

**8A-4. Add the admin host rule to the consolidated URL map (once per environment)**

Optional dry run first: export the map, add the host rule and path matcher to the file, and validate it. Nothing is changed:

```bash
gcloud compute url-maps export "$CLB_URL_MAP" --global --project="$PROJECT_ID" --destination="$WORKDIR/${CLB_URL_MAP}.proposed.yaml"
# edit the file: add under hostRules  - hosts: [ADMIN_HOSTNAME]  pathMatcher: ADMIN_MATCHER
#                 add under pathMatchers  - name: ADMIN_MATCHER  defaultService: <Fusion backend URL>
gcloud compute url-maps validate --source="$WORKDIR/${CLB_URL_MAP}.proposed.yaml" --global --project="$PROJECT_ID"
```

Apply with the additive command (one atomic change that adds a path matcher and its host rule; existing rules are untouched):

```bash
gcloud compute url-maps add-path-matcher "$CLB_URL_MAP" --global --project="$PROJECT_ID" \
  --path-matcher-name="$ADMIN_MATCHER" \
  --default-service="https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/backendServices/${BACKEND}" \
  --new-hosts="$ADMIN_HOSTNAME"

gcloud compute url-maps describe "$CLB_URL_MAP" --global --project="$PROJECT_ID" \
  --format="yaml(defaultService,hostRules,pathMatchers[].name)"
```

`BACKEND` is the Fusion backend service for this environment (Appendix A), which is in the same project as the consolidated load balancer.

**Verify:** the new host rule and matcher are listed and all previous host rules and matchers are unchanged (compare with `$CLB_BACKUP/${CLB_URL_MAP}.yaml`).

**8A-5. DNS (Lucidworks Cloud Ops)**

The `b.lucidworks.cloud` zone is in the `managed-fusion` project and is shared by every customer, so go through the normal review. No new A record or IP is needed: the admin hostname is a CNAME to the consolidated load balancer's existing A record.

```bash
gcloud dns record-sets create "${ADMIN_HOSTNAME}." --zone=lucidworks-cloud --project=managed-fusion \
  --type=CNAME --ttl=300 --rrdatas="$CLB_DNS"

dig +short "$ADMIN_HOSTNAME"        # expect $CLB_DNS, then the consolidated IP
```

**8A-6. Verify**

```bash
export CLB_IP=$(gcloud compute forwarding-rules describe "$CLB_HTTPS_FWD_RULE" --global --project="$PROJECT_ID" --format="value(IPAddress)")

# Admin hostname works: same status as the step 1f baseline (use --resolve before DNS has propagated)
curl -sS -o /dev/null -w "admin host: %{http_code}\n" --resolve "${ADMIN_HOSTNAME}:443:${CLB_IP}" "https://${ADMIN_HOSTNAME}/"

# Bypass test: the MAIN Fusion hostname sent to the consolidated IP must NOT reach Fusion.
# Expect the default service (ArgoCD page or an error), never the Fusion UI.
curl -sk --resolve "${HOSTNAME_FQDN}:443:${CLB_IP}" "https://${HOSTNAME_FQDN}/" | grep -o -i "<title>[^<]*</title>"

# Admin hostname over HTTP redirects to HTTPS
curl -sS -o /dev/null -w "admin http: %{http_code} -> %{redirect_url}\n" --resolve "${ADMIN_HOSTNAME}:80:${CLB_IP}" "http://${ADMIN_HOSTNAME}/"

# No client certificate requested
openssl s_client -connect "${CLB_IP}:443" -servername "${ADMIN_HOSTNAME}" </dev/null 2>&1 \
  | grep -E "subject=|Verify return|Acceptable client certificate CA names|No client certificate CA names"

# The consolidated proxy must still have no server TLS policy
gcloud compute target-https-proxies describe "$CLB_HTTPS_PROXY" --global --project="$PROJECT_ID" --format="value(serverTlsPolicy)"

# Existing applications unchanged
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do
  curl -sS -o /dev/null -w "$h https %{http_code}\n" "https://$h/"
done | diff - "$CLB_BACKUP/baseline-https.txt" && echo "existing hosts identical to baseline"
```

**Verify:** the admin host returns the baseline Fusion status; the main hostname on the consolidated IP does not return Fusion; the admin host's HTTP request redirects; no client certificate is requested; `serverTlsPolicy` is empty; existing hosts match the baseline.

**Rollback for variant A** is in [section 7](#7-rollback) (levels 5 to 7). Review it before starting.

#### Variant B: dedicated proxy (new IP, URL map, HTTPS proxy and forwarding rule)

Use when there is no consolidated load balancer, or when it will later enforce mTLS. This variant creates only new resources and does not touch anything existing.

```
API clients ─TLS + client cert─▶ existing IP ─▶ existing HTTPS proxy (mTLS) ─▶ existing URL map ─┐
                                                                                                 ├─▶ same backend service ─▶ NEG ─▶ api-gateway
People ──────TLS only──────────▶ NEW IP ──────▶ NEW HTTPS proxy (no mTLS) ──▶ NEW URL map ──────┘
```

Why each new piece is needed:
- **New proxy**: the mTLS policy is attached per proxy, so a hostname that must not require certificates needs its own proxy.
- **New IP**: a forwarding rule is unique per IP, port and protocol, and the existing IP already serves port 443.
- **New URL map (not the existing one)**: the existing URL map has no host rules, so it serves any `Host` header. If the admin proxy reused it, anyone could connect to the admin IP, send `Host: <main hostname>` and reach Fusion with no certificate. The new URL map only serves the admin hostname and redirects every other host to it.

Set the names for the new resources (`ADMIN_HOSTNAME` is set at the top of this step):

```bash
export ADMIN_PREFIX="lw-${CUSTOMER}-global-${ENV_NAME}-admin"
export ADMIN_ADDRESS="${ADMIN_PREFIX}-address"
export ADMIN_URL_MAP="${ADMIN_PREFIX}-url-map"
export ADMIN_PROXY="${ADMIN_PREFIX}-https-proxy"
export ADMIN_FWD_RULE="${ADMIN_PREFIX}-https"
export ADMIN_LB_DNS="${CUSTOMER}-global-${ENV_NAME}-admin.b.lucidworks.cloud."   # A-record name, mirrors the existing pattern
```

**8B-1. Mirror the existing proxy's settings and confirm certificate coverage (read-only)**

```bash
export CERT_MAP=$(gcloud compute target-https-proxies describe "$PROXY" --global --project="$PROJECT_ID" --format="value(certificateMap.basename())")
export SSL_POLICY=$(gcloud compute target-https-proxies describe "$PROXY" --global --project="$PROJECT_ID" --format="value(sslPolicy.basename())")
echo "cert map: $CERT_MAP   ssl policy: $SSL_POLICY"

gcloud certificate-manager maps entries list --map="$CERT_MAP" --project="$PROJECT_ID" \
  --format="table(name,hostname,matcher,certificates.basename())"
gcloud certificate-manager certificates describe <certificate-name-from-above> \
  --location=global --project="$PROJECT_ID" --format="yaml(sanDnsnames,expireTime)"

# For reference: settings of the existing HTTPS forwarding rule to mirror
gcloud compute forwarding-rules describe "$FWD_RULE" --global --project="$PROJECT_ID" \
  --format="yaml(loadBalancingScheme,networkTier,portRange)"
```

**Verify:** `ADMIN_HOSTNAME` matches a SAN of the certificate (st-micro: `*.b.lucidworks.cloud`), and the forwarding-rule settings match the commands below (`EXTERNAL_MANAGED`, `PREMIUM`, port 443).

**8B-2. Reserve the IP**

```bash
gcloud compute addresses create "$ADMIN_ADDRESS" --global --ip-version=IPV4 --project="$PROJECT_ID"
export ADMIN_IP=$(gcloud compute addresses describe "$ADMIN_ADDRESS" --global --project="$PROJECT_ID" --format="value(address)")
echo "$ADMIN_IP"
```

**8B-3. Create the admin URL map** (serves only the admin hostname; anything else is redirected to it and never reaches the backend)

```bash
cat > "$WORKDIR/${ADMIN_URL_MAP}.yaml" <<YAML
name: ${ADMIN_URL_MAP}
defaultUrlRedirect:
  hostRedirect: ${ADMIN_HOSTNAME}
  httpsRedirect: true
  redirectResponseCode: FOUND
  stripQuery: true
hostRules:
- hosts:
  - ${ADMIN_HOSTNAME}
  pathMatcher: admin
pathMatchers:
- name: admin
  defaultService: projects/${PROJECT_ID}/global/backendServices/${BACKEND}
YAML

gcloud compute url-maps import "$ADMIN_URL_MAP" --global --project="$PROJECT_ID" \
  --source="$WORKDIR/${ADMIN_URL_MAP}.yaml"
```

The consolidated `*-clb` URL maps use the same host-rule pattern.

**8B-4. Create the admin HTTPS proxy** (same certificate map and SSL policy, **no** `--server-tls-policy`)

```bash
gcloud compute target-https-proxies create "$ADMIN_PROXY" --global --project="$PROJECT_ID" \
  --url-map="$ADMIN_URL_MAP" --global-url-map \
  --certificate-map="$CERT_MAP" \
  --ssl-policy="$SSL_POLICY" --global-ssl-policy
```

If step 1d showed `quicOverride` other than `NONE`, add `--quic-override=` with the same value.

**8B-5. Create the forwarding rule**

```bash
gcloud compute forwarding-rules create "$ADMIN_FWD_RULE" --global --project="$PROJECT_ID" \
  --load-balancing-scheme=EXTERNAL_MANAGED --network-tier=PREMIUM \
  --address="$ADMIN_ADDRESS" \
  --target-https-proxy="$ADMIN_PROXY" --global-target-https-proxy \
  --ports=443
```

**8B-6. Verify before DNS exists** (a new global frontend can take several minutes to start answering)

```bash
# Admin hostname works: same status as the step 1f baseline
curl -sS -o /dev/null -w "admin host:  %{http_code}\n" --resolve "${ADMIN_HOSTNAME}:443:${ADMIN_IP}" "https://${ADMIN_HOSTNAME}/"

# Bypass test: the MAIN hostname sent to the admin IP must be redirected, never served
curl -sS -o /dev/null -w "main host on admin IP: %{http_code} -> %{redirect_url}\n" \
  --resolve "${HOSTNAME_FQDN}:443:${ADMIN_IP}" "https://${HOSTNAME_FQDN}/"

# No client certificate requested, correct server certificate
openssl s_client -connect "${ADMIN_IP}:443" -servername "${ADMIN_HOSTNAME}" </dev/null 2>&1 \
  | grep -E "subject=|Verify return|Acceptable client certificate CA names|No client certificate CA names"

gcloud compute target-https-proxies describe "$ADMIN_PROXY" --global --project="$PROJECT_ID" --format="value(serverTlsPolicy)"   # must be empty
```

**Verify:** the admin host returns the baseline status; the main hostname on the admin IP returns a `302` to `https://${ADMIN_HOSTNAME}/`; no client certificate is requested; `serverTlsPolicy` is empty.

**8B-7. DNS** (Lucidworks Cloud Ops; the `b.lucidworks.cloud` zone is in the `managed-fusion` project and is shared by every customer, so go through the normal review). This follows the existing pattern: an A record named for the load balancer, and a CNAME for the friendly name.

```bash
gcloud dns record-sets create "$ADMIN_LB_DNS" --zone=lucidworks-cloud --project=managed-fusion \
  --type=A --ttl=300 --rrdatas="$ADMIN_IP"
gcloud dns record-sets create "${ADMIN_HOSTNAME}." --zone=lucidworks-cloud --project=managed-fusion \
  --type=CNAME --ttl=300 --rrdatas="$ADMIN_LB_DNS"

dig +short "$ADMIN_HOSTNAME"        # expect the A-record name, then $ADMIN_IP
```

#### Both variants

**8h. Restrict who can reach the admin hostname**

Without a restriction, the admin hostname exposes the Fusion login and `/api` to the whole internet, which is the exposure mTLS is meant to remove. Restrict it to known networks with a Cloud Armor rule that applies **only to the admin hostname**. The allowed ranges are: the customer's corporate and VPN egress (where people use the host), Lucidworks support egress, and the Lucidworks load-test egress `35.188.233.187/32` ([9.2](#92-standard-configuration-every-environment-that-enforces-mtls)). The restriction is an IP allow-list; IAP is the identity-based alternative but is a larger change. Blocking the `/api` path instead does **not** work: the Fusion UI is a single-page app that calls `/api/...` on the same host, so blocking it breaks the UI, and a path rule cannot tell a UI call from a scripted one. If no IP ranges are available, a Cloud Armor country allow-list (`origin.region_code`) is a weaker fallback. Path rules are still useful for paths nobody needs (for example `/actuator`, `swagger-ui`), as hardening on top of the allow-list.

The backend service is shared with the mTLS hostname, so the policy sits on the same backend. The rule's host condition keeps it from affecting API traffic. Check what is already attached:

```bash
gcloud compute backend-services describe "$BACKEND" --global --project="$PROJECT_ID" --format="value(securityPolicy.basename())"
```

Use the expression below in either case. Create the rule in **preview** first so it only logs what it would block:

```bash
export ADMIN_CIDR_EXPR="!(inIpRange(origin.ip, '35.188.233.187/32') || inIpRange(origin.ip, '<customer-cidr-1>') || inIpRange(origin.ip, '<customer-cidr-2>'))"   # first range: Lucidworks load-test egress
export ADMIN_RULE_EXPR="request.headers['host'].lower().contains('${ADMIN_HOSTNAME}') && ${ADMIN_CIDR_EXPR}"
```

*Case A: the backend has no security policy (st-micro prd).* Create one and attach it. A new policy's default rule allows all traffic, so API traffic is unaffected:

```bash
export ARMOR_POLICY="${ADMIN_PREFIX}-allowlist"
gcloud compute security-policies create "$ARMOR_POLICY" --project="$PROJECT_ID" \
  --description="Allow-list for ${ADMIN_HOSTNAME}"
gcloud compute security-policies describe "$ARMOR_POLICY" --project="$PROJECT_ID" \
  --format="table(rules[].priority,rules[].action)"          # default rule must be: 2147483647 allow

gcloud compute security-policies rules create 1000 --security-policy="$ARMOR_POLICY" --project="$PROJECT_ID" \
  --action=deny-403 --preview --expression="$ADMIN_RULE_EXPR" \
  --description="Admin hostname: allow-listed networks only"

gcloud compute backend-services update "$BACKEND" --global --project="$PROJECT_ID" --security-policy="$ARMOR_POLICY"
```

*Case B: the backend already has a policy (st-micro dev and stg use `mf-crs422-waf-policy`: OWASP CRS deny rules at priorities 1000 to 1110, default allow, attached only to the dev and stg backends).* Add the rule to that policy at a lower priority number so it is evaluated first. The CRS rules stay as they are. Check first who else uses the policy:

```bash
export ARMOR_POLICY="<existing-policy-name>"
gcloud compute backend-services list --project="$PROJECT_ID" --filter="securityPolicy~${ARMOR_POLICY}" --format="value(name)"

gcloud compute security-policies rules create 100 --security-policy="$ARMOR_POLICY" --project="$PROJECT_ID" \
  --action=deny-403 --preview --expression="$ADMIN_RULE_EXPR" \
  --description="Admin hostname: allow-listed networks only"
```

Then check what the preview rule would have blocked, from an allowed network and from a non-allowed one, and only then enforce it:

```bash
gcloud logging read \
  "resource.type=\"http_load_balancer\" AND jsonPayload.previewSecurityPolicy.outcome=\"DENY\"" \
  --project="$PROJECT_ID" --freshness=1h --limit=20 \
  --format="table(timestamp,httpRequest.remoteIp,httpRequest.requestUrl)"
# (log field names per the Cloud Armor logging docs; confirm them in dev)

# Enforce (use the priority you created: 1000 for case A, 100 for case B)
gcloud compute security-policies rules update <priority> --security-policy="$ARMOR_POLICY" --project="$PROJECT_ID" --no-preview
```

**Verify:** from an allowed network the admin host returns the baseline status; from a non-allowed network (for example a phone hotspot) it returns `403`; the main hostname's API traffic is unchanged.

**8i. Fusion and people checks (do in dev first)**

- Log in through the admin hostname in a browser. If SSO (OIDC/SAML) is configured, the identity provider must allow the new hostname's redirect URI. Also check any Fusion setting or link that has the old hostname hard-coded.
- Tell administrators the new URL ahead of enforcement; bookmarks and saved links to the main hostname stop working once it enforces certificates.
- Add the admin hostname to the customer's monitoring where the main hostname is monitored.
- Do not give the admin hostname to API clients. It is for people and Lucidworks load tests, and it is not protected by mTLS.
- From the load-test cluster, run the preflight in [9.2](#92-standard-configuration-every-environment-that-enforces-mtls) and confirm the status matches the baseline.

### Step 9: Observe and onboard clients

Minimum bake time (agree with the customer, record the dates): dev 2 business days, stg 1 week, prod 2 weeks.

```bash
# Who is calling now, compared with the pre-work inventory (3.2). Use the callers() function
# defined there, one day at a time, and diff the output against the inventory.
callers 2026-11-10T00:00:00Z 2026-11-11T00:00:00Z

# mTLS-related statuses the LB records
gcloud logging read \
  "resource.type=\"http_load_balancer\" AND resource.labels.forwarding_rule_name=\"${FWD_RULE}\" AND jsonPayload.statusDetails=~\"client_cert\"" \
  --project="$PROJECT_ID" --freshness=1d --limit=50 \
  --format="table(timestamp,httpRequest.remoteIp,jsonPayload.statusDetails)"
```

Failed TLS handshakes are not necessarily logged by the LB, and Google does not document the log shape in observe mode. **Confirm in dev what actually appears** (send a no-cert request and a bad-cert request and look). If the LB logs do not show per-client cert presence, use the forwarded headers via api-gateway logs or the customer's own client inventory instead. Do not enforce on the strength of "nothing in the logs".

**Exit criteria for enforcement**, all required:
- Every client in the customer's inventory has presented a valid cert (confirmed by header/log evidence or customer attestation).
- No unexplained traffic remains (unknown source IPs or user agents are resolved or accepted as blocked).
- Browser/UI question from gate 1 is resolved for this hostname ([3.3](#33-classify-the-callers-and-decide-on-browsers)).
- The longest periodic job cycle (nightly, weekly, month-end) has been observed within the bake time, or its owner has confirmed readiness.
- Where step 8 applies: the admin hostname works, is restricted by the allow-list, administrators have the new URL, and the callers query ([3.2](#32-identify-the-callers-of-each-hostname)) on the **main** hostname shows browser traffic has stopped, apart from scanner probes.
- Monitoring and synthetic checks send client certificates.
- Customer sign-off, the enforcement notice has been sent ([3.9](#39-change-management-and-communication)), and a change window is agreed.

### Step 10: Enforce (`REJECT_INVALID`)

Only after the previous environment in the [rollout order](#8-rollout-order) has run in enforce mode cleanly.

```bash
sed -i.bak 's/clientValidationMode: .*/clientValidationMode: REJECT_INVALID/' "$WORKDIR/${POLICY}.yaml"   # on macOS; GNU sed: -i.bak works the same
grep clientValidationMode "$WORKDIR/${POLICY}.yaml"

gcloud network-security server-tls-policies import "$POLICY" \
  --source="$WORKDIR/${POLICY}.yaml" --location=global --project="$PROJECT_ID"

gcloud network-security server-tls-policies describe "$POLICY" \
  --location=global --project="$PROJECT_ID" --format="value(mtlsPolicy.clientValidationMode)"
```

`import` on an existing policy updates it in place. The attachment to the proxy does not change. (Dev is the first place this is exercised; if import refuses to update, delete-and-recreate is **not** acceptable on an attached policy. Detach first via the rollback, then recreate.)

Wait a few minutes, then test:

```bash
# No cert: must now FAIL at the TLS handshake (curl exit 35 or 56, no HTTP status)
curl -sS -o /dev/null -w "no cert:      %{http_code}\n" "https://${HOSTNAME_FQDN}/"; echo "exit=$?"

# Valid cert: must succeed
curl -sS -o /dev/null -w "valid cert:   %{http_code}\n" --cert client.pem --key client.key "https://${HOSTNAME_FQDN}/"

# Cert from an untrusted CA (Appendix B cert): must FAIL
curl -sS -o /dev/null -w "wrong CA:     %{http_code}\n" --cert untrusted.pem --key untrusted.key "https://${HOSTNAME_FQDN}/"
```

### Step 11: Post-change checks

- Customer confirms their API clients are working.
- Compare request volume against the step 9 baseline for the same hours/weekday. Rejected handshakes may never appear in LB logs, so **a drop in request count is the main signal of blocked clients**.
- Watch the Fusion service dashboards for the hostname for at least the agreed window.
- Update the change ticket with: resource names, commands run, test results, rollback status.

---

## 7. Rollback

Fastest and least disruptive first. Each takes a few minutes to propagate globally.

| Level | When | Command |
|---|---|---|
| **1. Back to observe mode** | Legitimate clients are being rejected | Set `clientValidationMode: ALLOW_INVALID_OR_MISSING_CLIENT_CERT` in `$WORKDIR/${POLICY}.yaml`, then `gcloud network-security server-tls-policies import "$POLICY" --source=... --location=global --project="$PROJECT_ID"` |
| **2. Detach mTLS** | Level 1 is not enough, or the cert map/handshake misbehaves | `gcloud compute target-https-proxies update "$PROXY" --global --project="$PROJECT_ID" --clear-server-tls-policy` |
| **3. Restore proxy exactly as it was** | Anything unexpected on the proxy | `gcloud compute target-https-proxies import "$PROXY" --global --project="$PROJECT_ID" --source="$WORKDIR/backup/${PROXY}.pre-mtls.yaml"` |
| **4. Remove added headers** | After detaching, if requested | `gcloud compute backend-services update "$BACKEND" --global --project="$PROJECT_ID" --no-custom-request-headers` (or import `backup/${BACKEND}.pre-mtls.yaml`) |
| **5. Remove the admin hostname (variant A, consolidated load balancer)** | The admin hostname is no longer wanted, or it misroutes. Do this **only after** the main proxy is back in observe mode or detached (Levels 1 to 2), otherwise people are locked out | `gcloud compute url-maps remove-host-rule "$CLB_URL_MAP" --global --project="$PROJECT_ID" --host="$ADMIN_HOSTNAME" --delete-orphaned-path-matcher`, then DNS: `gcloud dns record-sets delete "${ADMIN_HOSTNAME}." --zone=lucidworks-cloud --project=managed-fusion --type=CNAME`, then Cloud Armor: `gcloud compute security-policies rules delete <priority> --security-policy="$ARMOR_POLICY" --project="$PROJECT_ID"` (the policy can stay attached; its default rule allows all) |
| **6. Revert the port-80 redirect (variant A)** | A client or process that needs plain HTTP on the consolidated load balancer, or ArgoCD/Grafana misbehave after 8A-3 | `gcloud compute target-http-proxies update "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" --url-map="$CLB_URL_MAP" --global-url-map`. This reopens the plain-HTTP exposure, including for an admin hostname still on the map, so do Level 5 first or accept that. Optionally delete the redirect map afterwards: `gcloud compute url-maps delete "$CLB_REDIRECT_URL_MAP" --global --project="$PROJECT_ID"` |
| **7. Restore the consolidated URL map from backup (variant A)** | The consolidated URL map misbehaves, or it is unclear what changed | See the restore commands below. This removes **every** host rule added since the backup (including another environment's admin hostname), so re-add those afterwards |
| **8. Remove the admin hostname (variant B, dedicated proxy)** | The admin hostname is no longer wanted. Same precondition as Level 5 | Delete in reverse order. DNS: `gcloud dns record-sets delete "${ADMIN_HOSTNAME}." --zone=lucidworks-cloud --project=managed-fusion --type=CNAME`, then the same for `"$ADMIN_LB_DNS"` with `--type=A`. Then `gcloud compute forwarding-rules delete "$ADMIN_FWD_RULE" --global`, `gcloud compute target-https-proxies delete "$ADMIN_PROXY" --global`, `gcloud compute url-maps delete "$ADMIN_URL_MAP" --global`, `gcloud compute addresses delete "$ADMIN_ADDRESS" --global` (all with `--project="$PROJECT_ID"`). Cloud Armor as in Level 5 |

**Restoring the consolidated URL map from backup (Level 7).** The exported file contains a `fingerprint:` line. The API rejects an import whose fingerprint no longer matches the live URL map, which it will not once anything has changed since the backup, so remove that line first:

```bash
grep -v '^fingerprint:' "$CLB_BACKUP/${CLB_URL_MAP}.yaml" > "$WORKDIR/${CLB_URL_MAP}.restore.yaml"
gcloud compute url-maps validate --source="$WORKDIR/${CLB_URL_MAP}.restore.yaml" --global --project="$PROJECT_ID"   # loadSucceeded and testPassed must be true
gcloud compute url-maps import "$CLB_URL_MAP" --global --project="$PROJECT_ID" --source="$WORKDIR/${CLB_URL_MAP}.restore.yaml"
```

If the HTTP proxy was also changed (8A-3), restore it with Level 6, or from its backup: `gcloud compute target-http-proxies import "$CLB_HTTP_PROXY" --global --project="$PROJECT_ID" --source="$CLB_BACKUP/${CLB_HTTP_PROXY}.yaml"`. Then check against the baselines:

```bash
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do curl -sS -o /dev/null -w "$h https %{http_code}\n" "https://$h/"; done | diff - "$CLB_BACKUP/baseline-https.txt" && echo "HTTPS back to baseline"
for h in <existing-host-1> <existing-host-2> <existing-host-3>; do curl -sS -o /dev/null -w "$h http %{http_code} %{redirect_url}\n" "http://$h/"; done | diff - "$CLB_BACKUP/baseline-http.txt" && echo "HTTP back to baseline"
```

After Level 2, confirm with `curl` that no-cert requests succeed and `serverTlsPolicy` is empty. The trust config and policy resources can stay in place (they are inert when detached). Delete them only after the attachment is gone:

```bash
gcloud network-security server-tls-policies delete "$POLICY" --location=global --project="$PROJECT_ID"
gcloud certificate-manager trust-configs delete "$TRUST_CONFIG" --location=global --project="$PROJECT_ID"
```

---

## 8. Rollout order

Each proxy gets its own pass through steps 1 to 11 (step 8 only where an admin hostname is needed). Do not start a step in the next row until the row above has met its exit criteria.

| # | Proxy | Mode | Purpose |
|---|---|---|---|
| 1 | dev | observe | Proves the mechanics, incl. cert map + server TLS policy coexistence and flag syntax |
| 2 | stg | observe | Repeats on a second proxy with realistic clients |
| 3 | dev | **enforce** | First enforcement; validates the update-in-place and REJECT behavior with low blast radius |
| 4 | stg | **enforce** | Final non-prod validation; use this to rehearse the prod change and rollback |
| 5 | prod | observe | Same as 1, in prod. Longest bake time |
| 6 | prod | **enforce** | Only with customer sign-off and a change window |

Prefer a low-traffic window for each attach/enforce change, with the rollback owner on the call.

A hostname with browser users cannot move to "enforce" until the decision in [3.3](#33-classify-the-callers-and-decide-on-browsers) is implemented. For option (a) that means step 8 (admin hostname) is complete and tested for that environment first; it can be done during the observe period. That can change this table: for example, rows 3 and 4 may not apply to a hostname that serves people, while prod (rows 5 and 6) can proceed if the inventory shows it is API-only. Record the decision per environment in the change ticket.

Prove the load-test path in dev before it is relied on elsewhere: run the [9.2](#92-standard-configuration-every-environment-that-enforces-mtls) preflight from the load-test cluster against the dev admin hostname, then one short test through the admin hostname and one through the main hostname with a client certificate ([9.4](#94-path-3-load-test-through-the-mtls-hostname)), with dev already enforcing.

---

## 9. Load testing after mTLS

**Requirement:** Lucidworks must be able to load test any Fusion environment after mTLS is enabled, without relaxing mTLS to do it. Load generators run in the `lw-load-test-us-us-east4` cluster (`gke_managed-fusion-dev_us-east4_lw-load-test-us-us-east4`, project `managed-fusion-dev`).

### 9.1 Paths, and when to use each

| Path | Target | Needs | Use for |
|---|---|---|---|
| **1. Admin hostname (default)** | The environment's admin hostname ([step 8](#step-8-create-the-admin-hostname-only-where-people-or-other-non-certificate-clients-must-keep-access)) | The load-test egress IP in the admin hostname's Cloud Armor allow-list (9.2); Fusion credentials for the environment | Fusion and Solr capacity and soak tests. Same backend and same Cloud Armor policy as the real hostname. |
| **2. In-cluster** | api-gateway service from inside the customer cluster | A generator running in that cluster | Component tests where the load balancer should be out of the picture |
| **3. Main hostname with a client certificate** | The mTLS hostname | A load-test client certificate trusted by the trust config (9.4) | Final pre-go-live validation of the real endpoint, and anything that must include the mTLS handshake or the main load balancer frontend |

Path 1 is the standard. It needs no certificate handling and works the same in every environment. It does **not** exercise the main hostname's IP, proxy or mTLS handshake, so use path 3 when those matter.

### 9.2 Standard configuration (every environment that enforces mTLS)

- **Every load balancer that enforces mTLS gets an admin hostname (step 8), even when no people need it.** When only load tests use it, its allow-list contains only the Lucidworks load-test egress range.
- The load-test egress, discovered 2026-11-18 (read-only):

| | |
|---|---|
| Cluster | `lw-load-test-us-us-east4`, region `us-east4`, project `managed-fusion-dev`, private nodes |
| Egress | Cloud NAT `lw-load-test-us-us-east4-cloudnat` on router `lw-load-test-us-us-east4-cloudnat-router`, one manually allocated address |
| **Egress IP** | **`35.188.233.187`** (reserved address `lw-load-test-us-us-east4-ext-ip-0`) |

- Add `35.188.233.187/32` to the allow-list in step 8h for every environment, alongside the customer's ranges. Keep one list of Lucidworks load-test ranges so a change to the NAT address is made everywhere.
- **If load tests also run from other clusters or regions** (for example to test from Europe or Asia), their egress ranges must be added the same way. This runbook only knows about the cluster above.
- **Preflight from the generator cluster** before a test, to prove the path (this runs a one-off pod):

```bash
kubectl --context gke_managed-fusion-dev_us-east4_lw-load-test-us-us-east4 run mtls-preflight \
  --rm -i --restart=Never --image=curlimages/curl --command -- \
  curl -sS -o /dev/null -w "admin host from load-test cluster: %{http_code}\n" "https://${ADMIN_HOSTNAME}/"
```

Expect the same status as the step 1f baseline. A `403` means the egress IP is missing from the allow-list.

### 9.3 Limits of the load-test cluster's egress

- **Single NAT address, static ports.** The NAT has `minPortsPerVm: 128`, no dynamic port allocation. Each generator node can hold at most 128 simultaneous connections to a given destination IP and port. Use HTTP keep-alive and connection pooling, and scale out nodes rather than connections per node. If a test needs more, raise `minPortsPerVm` or enable dynamic port allocation on that NAT (a change in `managed-fusion-dev`).
- The same egress IP is allow-listed on every customer's admin hostname. Anyone who can run workloads in that cluster can reach them (Fusion credentials are still required). Restrict access to the cluster accordingly.
- All test runs share that one IP, so concurrent tests against the same environment are indistinguishable at the load balancer. Coordinate them.

### 9.4 Path 3: load test through the mTLS hostname

1. **Get a client certificate for the load test.**
   - *Preferred:* a dedicated, short-lived certificate for the load-test identity, issued by the customer's CA (the same CA that issues other client certificates). Request it per test campaign. The load balancer does no revocation, so a short lifetime is the control.
   - *Non-prod only, when the customer's CA is not available:* a Lucidworks self-signed certificate pinned in the trust config's allow-list. Google treats an allow-listed certificate as always valid, **including after it has expired**, matched on its exact contents. That makes it a permanent credential until you remove it, so remove it as soon as the test window closes.

   ```bash
   # Create a self-signed load-test client certificate (non-prod allow-list option)
   openssl req -x509 -newkey rsa:2048 -nodes -days 14 -sha256 \
     -keyout loadtest.key -out loadtest.pem -subj "/O=Lucidworks/CN=lw-load-test-${ENV_NAME}" \
     -addext "extendedKeyUsage=clientAuth" -addext "basicConstraints=CA:FALSE"

   # Pin it (adds to the allow-list; existing trust anchors are unchanged)
   gcloud certificate-manager trust-configs update "$TRUST_CONFIG" --project="$PROJECT_ID" --location=global \
     --add-allowlisted-certificates=loadtest.pem

   # After the test window: remove it
   gcloud certificate-manager trust-configs update "$TRUST_CONFIG" --project="$PROJECT_ID" --location=global \
     --remove-allowlisted-certificates=loadtest.pem
   ```

   A trust config shared by dev and stg (st-micro non-prod) accepts the pinned certificate on both. Keep any trust-store settings: `trust-configs update` with `--trust-store` replaces the store, but `--add-allowlisted-certificates` leaves it alone.

2. **Store the key safely** (the load-test team's secret store, mounted into the generator pods), not in the test repository.
3. **Configure the load tool.** JMeter, k6, Gatling and Locust all support client certificates. For example, in k6:

   ```javascript
   export const options = {
     tlsAuth: [{ domains: ['<main hostname>'], cert: open('./loadtest.pem'), key: open('./loadtest.key') }],
   };
   ```

4. **Preflight** with `curl --cert loadtest.pem --key loadtest.key https://<main hostname>/` from a generator pod before the full run.
5. **Reuse connections.** Every new connection performs a certificate handshake and counts toward the 128-connection-per-node limit in 9.3. A tool that opens a new connection per request will measure handshake overhead, not Fusion.

### 9.5 Process for each load test

- Notify the customer and their monitoring owners ahead of time (Datadog Synthetics and uptime checks can alert on the extra load).
- Record environment, path (1, 2 or 3), window, source IP, and, for path 3, the certificate used.
- For path 3 with a pinned certificate, remove it at the end of the window and confirm the trust config no longer lists it.
- Never switch the policy to `ALLOW_INVALID_OR_MISSING_CLIENT_CERT` for a load test.

---

## 10. Follow-up steps

**Immediately after rollout**
1. **Close the HTTP bypass.** Where an HTTP (port 80) forwarding rule shares the URL map (st-micro dev does), add an HTTP-to-HTTPS redirect URL map for the HTTP proxy or delete the port-80 forwarding rule, otherwise mTLS enforcement on 443 can be bypassed.
2. **Log the client-cert headers** in the api-gateway access log (configured through the Fusion values in the customer config repo) so presence/validity is auditable per request. Confirm first that api-gateway can log arbitrary request headers; if not, record them another way.
3. **Commit the CA public certs** (not keys) and the policy YAML to the customer config repo, e.g. `terraform/<env>/mtls/`, so the state is reviewable even though it is not Terraform managed.
4. **Document client onboarding** (how a customer system gets a cert, how to test) and hand it to the customer.

**Ongoing operations**
5. **Certificate expiry alerting**: CA certs (trust config) and client certs per the customer's rotation schedule. The LB does no revocation, so short-lived client certs are the main mitigation.
6. **CA rotation**: add the new CA alongside the old one, then remove the old one after clients migrate. `trust-configs update --trust-store=...` **replaces** the store, so list old and new in the files:
   ```bash
   gcloud certificate-manager trust-configs update "$TRUST_CONFIG" --project="$PROJECT_ID" --location=global \
     --trust-store="trust-anchors=old-root.pem;new-root.pem,intermediate-cas=..."
   ```
   Rehearse in non-prod first. (Quote semicolon-separated lists.)
7. **Customer onboarding of new clients** needs no GCP change as long as their certs chain to a trusted CA.

**Scope expansion and housekeeping**
8. **Other proxies**: the consolidated `non-prod-clb` and `prod-clb` (argocd, grafana) were deliberately left out. `lw-stmicro-global-prd-a-loadbalancer-https-proxy` (prod-a) needs a decision. Each needs its own policy and pass through this runbook.
9. **Terraform drift**: these resources are created outside Terraform. If the LB module is ever re-adopted, import them (or recreate under new names) so Terraform does not try to create duplicates. Before re-adopting, verify the module's server TLS policy resource type is correct for a **global** proxy: this runbook uses `network-security server-tls-policies --location=global`, whereas the module uses `google_compute_region_server_tls_policy` with `location = "global"`.
10. **Fix the Terraform guide**: its `gcloud certificate-manager trust-configs create --trust-store=trust-anchors="$CA_CERT"` example passes PEM content, but gcloud requires file paths.
11. **Reuse for other customers**: copy [Appendix A](#appendix-a-customer-parameter-sheet) and fill it from step 1 discovery.
12. **Admin hostnames** (from step 8): keep the Cloud Armor allow-list current when the customer's egress or VPN ranges, or the Lucidworks load-test egress, change; add the admin hostname to monitoring; record the new IP, proxy, URL map and DNS records in the customer config repo; and treat the admin hostname as a standing exposure that relies on Fusion authentication plus the IP allow-list, not mTLS. Do not attach a server TLS policy to the consolidated HTTPS proxy while it carries admin hostnames, and revisit the 302 on the consolidated HTTP proxy (switch to a permanent redirect once stable). If the customer wants identity-based access instead of an IP list, evaluate IAP on the admin backend.

---

## Appendix A: Customer parameter sheet

### st-micro (project `mf-stmicroelectronics`)

Discovered with read-only gcloud on 2026-11-17. Certificate map (`wildcard-b-certificate-2026-cm`) and SSL policy (`modern-policy`, TLS 1.2, RESTRICTED) are shared by all proxies and are not changed.

| | **dev** | **stg** | **prd** |
|---|---|---|---|
| `ENV_NAME` | `dev` | `stg` | `prd` |
| `PROXY` | `lw-stmicro-global-dev-loadbalancer-https-proxy` | `lw-stmicro-global-stg-loadbalancer-https-proxy` | `lw-stmicro-global-prd-loadbalancer-https-proxy` |
| `URL_MAP` | `lw-stmicro-global-dev-loadbalancer-url-map` | `lw-stmicro-global-stg-loadbalancer-url-map` | `lw-stmicro-global-prd-loadbalancer-url-map` |
| `BACKEND` | `lw-stmicro-global-dev-loadbalancer-backend-default` | `lw-stmicro-global-stg-loadbalancer-backend-default` | `lw-stmicro-global-prd-loadbalancer-backend-default` |
| `FWD_RULE` (HTTPS) | `lw-stmicro-global-dev-loadbalancer-https` | `lw-stmicro-global-stg-loadbalancer-https` | `lw-stmicro-global-prd-loadbalancer-https` |
| IP | 34.149.224.121 | 34.96.109.8 | 34.8.30.112 |
| `HOSTNAME_FQDN` | `stmicro-dev.b.lucidworks.cloud` | `stmicro-stg.b.lucidworks.cloud` | `stmicro.b.lucidworks.cloud` |
| `TRUST_CONFIG` | `stmicro-non-prod-mtls-trust-config` (shared dev + stg) | same | `stmicro-prod-mtls-trust-config` |
| `POLICY` | `stmicro-dev-mtls-policy` | `stmicro-stg-mtls-policy` | `stmicro-prd-mtls-policy` |
| Existing `serverTlsPolicy` | none | none | none |
| Existing backend custom headers | none | none | none |
| Cloud Armor | `mf-crs422-waf-policy` | `mf-crs422-waf-policy` | none |
| HTTP (port 80) listener on same URL map | **yes**: `lw-stmicro-global-dev-loadbalancer` / `...-http-proxy` | no | no |
| **Admin hostname** (step 8) `ADMIN_HOSTNAME` (proposed, confirm naming) | `stmicro-dev-admin.b.lucidworks.cloud` | `stmicro-stg-admin.b.lucidworks.cloud` | `stmicro-admin.b.lucidworks.cloud` |
| **Variant A**: `CLB_PREFIX` (consolidated LB) | `lw-stmicro-non-prod-clb` (shared by dev and stg) | same | `lw-stmicro-prod-clb` |
| `CLB_URL_MAP` / `CLB_HTTPS_PROXY` / `CLB_HTTP_PROXY` | `<CLB_PREFIX>-url-map` / `-https-proxy` / `-http-proxy` | same | same pattern |
| `CLB_HTTP_FWD_RULE` (80) / `CLB_HTTPS_FWD_RULE` (443) | `lw-stmicro-non-prod-clb` / `lw-stmicro-non-prod-clb-https` | same | `lw-stmicro-prod-clb` / `lw-stmicro-prod-clb-https` |
| Consolidated IP and `CLB_DNS` (CNAME target) | 8.232.94.246, `stmicro-non-prod-consolidated.b.lucidworks.cloud.` | same | 8.232.34.108, `stmicro-prod-consolidated.b.lucidworks.cloud.` |
| `ADMIN_MATCHER` | `admin-dev` | `admin-stg` | `admin-prd` |
| Port 80 shares the application URL map (fix in 8A-3, once per consolidated LB) | yes | yes (same LB as dev) | yes |
| **Variant B only**: `ADMIN_PREFIX` (dedicated proxy; not used if variant A is used) | `lw-stmicro-global-dev-admin` | `lw-stmicro-global-stg-admin` | `lw-stmicro-global-prd-admin` |
| `ADMIN_LB_DNS` (variant B only; A record in `managed-fusion`) | `stmicro-global-dev-admin.b.lucidworks.cloud.` | `stmicro-global-stg-admin.b.lucidworks.cloud.` | `stmicro-global-prd-admin.b.lucidworks.cloud.` |
| Cloud Armor case in step 8h | **B**: add rule at priority 100 to `mf-crs422-waf-policy` (shared by the dev and stg backends only) | **B**: same policy | **A**: new policy, backend has none |
| Allowed CIDR ranges (admin hostname) | `35.188.233.187/32` (Lucidworks load test) + *st-micro ranges and Lucidworks support egress, to be provided* | same | same |

st-micro specifics:
- Each LB serves a single hostname through a single default backend, which is the Fusion api-gateway (UI and API on the same host). Gate 1 (browser users) must be answered by the customer before enforcement.
- **Caller evidence from LB logs, sampled 2026-11-17** (starting point for the 3.2 inventory, not a substitute for it: windows were short and cover only the newest requests; periodic jobs may be missing):
  - **dev and stg: people use these hostnames.** Browser user agents (Windows, Linux, macOS) on `/auth`, `/admin` and `/api` are a significant share of requests. `REJECT_INVALID` here would lock out UI users. Apply the 3.3 decision before enforcing in dev or stg.
  - **prod is mostly API traffic, but browser use is not ruled out.** On a full day (2026-11-15, about 16k requests) about 96% was non-browser: `node-fetch` on `/api/.../query-pipelines` (about 10k) and `/api/signals` (about 4k), likely the customer's search application; `Datadog/Synthetics` (about 600, `/api/query`); and a `Python` client on `/api/jobs` and `/api/solr` (about 140). The other ~700 requests had browser user agents: about 480 were 401 probes, but about 136 succeeded, mostly on `/auth` (the Fusion login page and its assets). Find out whether anyone legitimately logs into the Fusion UI on the prod hostname (for example administrators) before treating prod as API-only.
  - **Datadog Synthetics** runs against all three hostnames: its tests must be given a client certificate or they will alert once enforcement starts.
  - **Internet scanners are present** on all three: Censys and Palo Alto user agents, and probes for `/.env`, `actuator`, `swagger-ui`, `remote/login`, `docker/compose`, almost all answered 401. These are the traffic mTLS removes.
  - Log retention on `_Default` is 30 days with no Log Analytics. LB logs are also exported by sinks to `managed-fusion.mf_customers_access_logs` (BigQuery), which is the place for longer history if you have access.
- **Admin hostnames use variant A (the consolidated load balancers).** Consolidated URL maps: default service is the ArgoCD backend; host rules for the Grafana dashboards and ArgoCD; no Cloud Armor or IAP on their backends; the HTTP proxies share the same URL map, so ArgoCD and Grafana are currently served over plain HTTP on port 80. No Terraform state manages any URL map, proxy, forwarding rule, address or security policy in this project (all 24 state files checked 2026-11-18), so editing them with gcloud causes no drift. The consolidated load balancers are assumed to stay without mTLS; if that changes, move the admin hostnames to dedicated proxies (variant B) first. A modified copy of the non-prod consolidated URL map with the dev and stg admin host rules passed `gcloud compute url-maps validate` (dry run).
- **Prod decision:** st-micro people log into the Fusion UI on the prod hostname, so prod uses option (a) from 3.3 and needs step 8 (admin hostname) before enforcement. Dev and stg most likely need it too (browser traffic is heavy there).
- **Wildcard certificate:** the server certificate (`wildcard-b-certificate-2027`, SANs `*.b.lucidworks.cloud` and `b.lucidworks.cloud`) is self-managed and expires **2027-04-22**. It also serves the admin hostnames, so renewing it is now a dependency for both access paths.
- **Ingress bypass is unresolved:** the `stmicro-prod-ingress`, `stmicro-non-prod-ingress` and `stmicro-prod-a-ingress` network LBs are open to `0.0.0.0/0` on 80/443 (see 3.7). Test and, if needed, restrict them before relying on mTLS.
- Project defaults in gcloud are another customer (`mf-costco` on the author's machine); always use `--project=mf-stmicroelectronics`.
- **Network Security API and Secret Manager API are not enabled** in this project at time of writing (step 2 handles the former; the latter is not needed).
- No trust configs or server TLS policies exist yet.
- Out of scope for now: `lw-stmicro-non-prod-clb-*`, `lw-stmicro-prod-clb-*`. Undecided: `lw-stmicro-global-prd-a-loadbalancer-*` (prod-a).
- Client CA: **not yet determined.** Use [section 5](#5-determining-the-client-ca) with the st-micro contact. Until real certs exist, dev can be validated with Appendix B.

---

## Appendix B: Throwaway test CA for dev validation

For mechanics testing only (dev; optionally stg). Do not use in prod or leave the test CA in a trust config that real traffic depends on. Prefer the customer's own test cert when available.

```bash
mkdir -p "$WORKDIR/testca" && cd "$WORKDIR/testca"

# Test root CA
openssl req -x509 -newkey rsa:2048 -nodes -days 30 -sha256 \
  -keyout testca.key -out root.pem -subj "/O=Lucidworks Test/CN=mtls-test-root-ca" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"

# Client cert signed by it (clientAuth EKU is required)
openssl req -newkey rsa:2048 -nodes -keyout client.key -out client.csr -subj "/O=Lucidworks Test/CN=mtls-test-client"
printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature\nextendedKeyUsage=clientAuth\n" > client.ext
openssl x509 -req -in client.csr -CA root.pem -CAkey testca.key -CAcreateserial -days 7 -sha256 -extfile client.ext -out client.pem

# A cert from a DIFFERENT CA, to prove untrusted certs are rejected
openssl req -x509 -newkey rsa:2048 -nodes -days 7 -sha256 -keyout untrusted.key -out untrusted.pem -subj "/CN=untrusted-client"
```

Use `$WORKDIR/testca/root.pem` as the trust anchor in step 4 (use a test-only trust config name such as `${CUSTOMER}-dev-mtls-test-trust-config`), then use `client.pem`/`client.key` and `untrusted.pem`/`untrusted.key` in the step 7 and 10 tests.

When real CA material arrives, swap the policy to the real trust config (edit `clientValidationTrustConfig` in the policy YAML and `import` again), then delete the test trust config.

---

## Appendix C: Verification status of this runbook

- **Executed (read-only) against `mf-stmicroelectronics`:** all discovery in step 1 and Appendix A (proxies, URL maps, forwarding rules, backend services, certificate map and entries, SSL policy, trust configs, enabled APIs), the `callers()` aggregation in 3.2 (dev, stg and one full prod day), and the log bucket and sink checks in 3.6.
- **Checked against `gcloud ... --help` only (not executed):** `trust-configs create/update` and `--trust-store` syntax, `server-tls-policies import`, `target-https-proxies update --server-tls-policy / --clear-server-tls-policy`, `backend-services update --custom-request-header / --no-custom-request-headers`.
- **Taken from Google documentation, not yet exercised:** policy YAML shape, export/import fallback for attaching the policy, custom request header variables, supported client key types and limits, log `statusDetails` values.
- **Not verified, to be proven in dev:** certificate map + server TLS policy on the same proxy; `import` updating an attached policy in place; what the LB logs in observe mode.
- **Section 9 (load testing):** the load-test cluster, its Cloud NAT address and port settings were read with read-only gcloud on 2026-11-18; `trust-configs update --add/--remove-allowlisted-certificates` was checked against `--help` and Google's allow-list description. Nothing was executed from the load-test cluster. To be proven in dev: the preflight from the generator cluster to the dev admin hostname, and a full path 3 run with a client certificate.
- **Step 8 (admin hostname):** nothing was created or changed. Checked read-only: the consolidated URL maps, proxies, forwarding rules, backends and DNS records; all Terraform state files (none manage load balancer resources); port-80 traffic on both consolidated load balancers; and a modified non-prod consolidated URL map (dev and stg admin host rules added) passed `gcloud compute url-maps validate`, which is a dry run. Flag syntax was checked against `--help` for `url-maps add-path-matcher / remove-host-rule / remove-path-matcher / export / import / validate`, `target-http-proxies update`, `addresses create`, `target-https-proxies create`, `forwarding-rules create`, `security-policies rules create / update`, `dns record-sets create`. `url-maps validate` cannot pre-check a URL map that does not exist yet (the redirect map and the variant B map). To be proven in dev: the redirect URL map on the HTTP proxy, `add-path-matcher` on the live consolidated map, the Level 7 restore import (including that the `fingerprint:` line must be removed from the backup), the main hostname falling through to ArgoCD on the consolidated IP, the Cloud Armor host-scoped expression and its preview log field names, and Fusion login through the admin hostname.

Sources: [mTLS overview](https://docs.cloud.google.com/load-balancing/docs/mtls), [Set up mTLS with Certificate Manager](https://docs.cloud.google.com/load-balancing/docs/https/setting-up-mtls-ccm), [LB logging](https://docs.cloud.google.com/load-balancing/docs/https/https-logging-monitoring).
