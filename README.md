# Deploy and Host Stalwart on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/stalwart-1?utm_medium=integration&utm_source=button&utm_campaign=stalwart-1)

[Stalwart](https://stalw.art/) is an all-in-one mail and collaboration server written in Rust — SMTP, IMAP, POP3, JMAP, CalDAV, CardDAV, and a full web admin in a single binary, with built-in spam filtering, DKIM/SPF/DMARC/ARC, and encryption at rest.

**Read this before deploying: on Railway this is a mailbox server, not an MX.** Inbound mail from the internet cannot reach it — Railway's TCP proxy answers on a port it assigns you, and an MX record cannot carry a port, so other mail servers have no way to connect. Outbound SMTP is blocked entirely below the Pro plan. What works well here is JMAP and the web admin over your Railway domain, IMAP and submission for your own clients through TCP proxies, and CalDAV/CardDAV. For a public mail domain that receives on port 25, run Stalwart somewhere you control the ports.

## About Hosting Stalwart

Stalwart keeps its entire state in two places: `/etc/stalwart` holds the pointer to the store, and `/var/lib/stalwart` holds the RocksDB store itself — accounts, mailboxes, and every setting made in the web UI. Railway attaches one volume per service, so this template relocates both onto a single volume at `/data` before the server starts. Without that, a redeploy would drop the server back into first-run bootstrap mode with the previous mailboxes gone. The web admin is served over plain HTTP on port 8080 both during setup and after, which is exactly what Railway's edge wants to talk to; TLS is terminated at Railway's proxy on your public domain.

## Common Use Cases

- A JMAP backend for a webmail front-end, served over your Railway domain with no extra ports involved.
- A CalDAV/CardDAV server for calendars and contacts, without a second service to run.
- A mailbox host for your own IMAP clients, each configured with the port Railway's TCP proxy hands out.
- An internal mail sink for staging: point an app's SMTP client at the submission proxy and inspect what it sends.

## Dependencies for Stalwart Hosting

- A Railway volume (created by this template) for the mail store.
- A Railway domain for the web admin and JMAP; a TCP proxy per protocol you want to reach from a client.
- The Pro plan, if the server needs to send mail at all.

### Deployment Dependencies

- [Stalwart documentation](https://stalw.art/docs/)
- [Stalwart source](https://github.com/stalwartlabs/stalwart)
- [Railway TCP proxy docs](https://docs.railway.com/networking/tcp-proxy)
- [Railway outbound networking docs](https://docs.railway.com/networking/outbound-networking)

### Implementation Details

**The app lives in a thin wrapper around the official `stalwartlabs/stalwart` image; the wrapper only relocates the two persistent paths onto the single Railway volume mounted at `/data`.**

1. Deploy, then open the generated domain at `/admin`. Sign in with the credentials in the `STALWART_RECOVERY_ADMIN` variable (`admin` plus the generated password).
2. Work through the five-step setup wizard. Set **Server Hostname** to your Railway domain (or your own mail domain if you have one), and turn **Automatically Obtain TLS Certificate** off — Railway already terminates TLS at the edge and the ACME challenge cannot reach this container.
3. On the logging step, choose **Console** as the log destination. The default writes to a file under `/var/log`, which means nothing shows up in Railway's log pane.
4. JMAP and the web admin need nothing further — both are served over the Railway domain. For IMAP or SMTP submission clients, add a TCP proxy per protocol (Settings → Networking → TCP Proxy): 993 for IMAP over TLS, 465 for submission over TLS. Railway answers on a port of its choosing, such as `shuttle.proxy.rlwy.net:15140`, and that port is what your client must use. Pointing a custom domain at the proxy replaces the hostname only — the port stays.

**Limits worth knowing before you deploy:**

- **No inbound mail from the internet.** MX records name a host, and every sending server connects to port 25 on it. Railway's TCP proxy only answers on the port it assigned, so there is no way for an outside mail server to reach this one. A proxy on 25 gets you a public port like `:15140`, which no MTA will ever dial.
- **No outbound mail below Pro.** Railway blocks outbound SMTP on Free, Trial, and Hobby plans; the Pro plan lifts the block. Direct-to-MX delivery on port 25 is not something Railway documents as available even there, so configure a smarthost relay under SMTP → Routing and send through it.
- **One replica.** Everything runs in one container against one volume, and RocksDB will not tolerate two replicas pointed at the same data.

## Why Deploy Stalwart on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Stalwart on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
