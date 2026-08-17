# Deploy and Host Stalwart on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/stalwart-1?utm_medium=integration&utm_source=button&utm_campaign=stalwart-1)

[Stalwart](https://stalw.art/) is an all-in-one mail and collaboration server written in Rust — SMTP, IMAP, POP3, JMAP, CalDAV, CardDAV, and a full web admin in a single binary, with built-in spam filtering, DKIM/SPF/DMARC/ARC, and encryption at rest.

## About Hosting Stalwart

Stalwart keeps its entire state in two places: `/etc/stalwart` holds the pointer to the store, and `/var/lib/stalwart` holds the RocksDB store itself — accounts, mailboxes, and every setting made in the web UI. Railway attaches one volume per service, so this template relocates both onto a single volume at `/data` before the server starts. Without that, a redeploy would drop the server back into first-run bootstrap mode with the previous mailboxes gone. The web admin is served over plain HTTP on port 8080 both during setup and after, which is exactly what Railway's edge wants to talk to; TLS is terminated at Railway's proxy on your public domain.

## Common Use Cases

- A self-hosted mailbox host for a personal or small-team domain, with IMAP/JMAP clients connecting through TCP proxies.
- A CalDAV/CardDAV server for calendars and contacts alongside mail, without a second service to run.
- An internal mail sink for staging environments — receive and inspect application mail without touching a production mail provider.

## Dependencies for Stalwart Hosting

- A Railway volume (created by this template) for the mail store.
- A public domain, plus DNS records (MX, SPF, DKIM, DMARC) pointing at the server for real mail delivery.

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
4. For IMAP and SMTP clients, add a TCP proxy per port you need (Settings → Networking → TCP Proxy): 993 for IMAP over TLS, 465 for submission over TLS, 25 for inbound mail. Railway assigns a random public port to each, so point your clients and MX records at the proxy address it gives you.

**Limits worth knowing before you deploy:** Railway blocks outbound SMTP (ports 25, 465, 587, 2525) on Free, Trial, and Hobby plans, and port 25 egress is restricted in general — so this server can receive and store mail, but direct-to-MX sending needs a Pro plan or a smarthost relay configured under SMTP → Routing. Everything is served from one container on one volume, so scale is bounded by that volume and a single replica; RocksDB will not tolerate two replicas pointed at the same data.

## Why Deploy Stalwart on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Stalwart on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
