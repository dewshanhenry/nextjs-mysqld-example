Next.js + MySQL Production Deployment

Production-ready setup for a Next.js CRUD app with MySQL, Nginx reverse proxy, Docker Compose, and GitHub Actions deployment to an Ubuntu VM.

Stack

- Next.js (Node.js runtime)
- MySQL 8.4
- Nginx reverse proxy
- Docker + Docker Compose
- GitHub Actions CI/CD

Project Structure

`Dockerfile` - multi-stage production image (`deps` -> `builder` -> `runner`)
`docker-compose.yml` - app + mysql + nginx services
`nginx/default.conf` - reverse proxy config to `app:3000`
`.env.example` - environment variable template
`deploy/setup-server.sh` - Ubuntu server bootstrap
`.github/workflows/ci-cd.yml` - build/test + deploy pipeline

1) Environment Configuration

Create `.env` from template:

```bash
cp .env.example .env
```

Update values:

```env
NODE_ENV=production
PORT=3000

MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE_NAME=nextjs_app
MYSQL_USER=nextjs_user
MYSQL_PASSWORD=REPLACE_WITH_STRONG_PASSWORD
MYSQL_ROOT_PASSWORD=REPLACE_WITH_STRONG_ROOT_PASSWORD
```

Notes:
- `MYSQL_HOST` should remain `mysql` (Compose service name).
- `.env` is ignored by git and must never be committed.

2) Run Production Stack with Docker Compose

```bash
docker compose up -d --build
docker compose ps
```

Services:
- `app`: Next.js production container (non-root runtime user, `NODE_ENV=production`)
- `mysql`: MySQL with persistent volume `mysql_data`
- `nginx`: reverse proxy to `app:3000`

Stop services:

```bash
docker compose down
```

3) Database Setup and Migrations

MySQL DB/user creation from `.env` happens only on first startup when the volume is empty.

Run migrations:

```bash
docker compose exec app npx knex migrate:latest --knexfile knexfile.ts
```

Optional seed:

```bash
docker compose exec app npx knex seed:run --knexfile knexfile.ts
```

If you changed DB credentials after first initialization:
- either manually alter MySQL users/passwords, or
- recreate DB from scratch:

```bash
docker compose down -v
docker compose up -d --build
```

4) Ubuntu VM Setup (Non-root Deployment User)

Run once as root/sudo:

```bash
sudo bash deploy/setup-server.sh deploy
```

This script:
- creates deployment user (default `deploy`)
- installs Docker Engine + Compose plugin + Git + Curl + UFW
- ensures `docker` group exists and adds deploy user to it
- opens firewall for SSH/HTTP/HTTPS

Then relogin as deploy user:

```bash
su - deploy
```

5) Nginx Configuration

Edit `nginx/default.conf`:

```nginx
server_name example.com;
```

Replace `example.com` with your real domain (or server IP for testing).

## 6) GitHub Actions Configuration

Workflow file: `.github/workflows/ci-cd.yml`

Pipeline behavior:
- On `main` push: install dependencies, lint, build.
- Deploy job: SSH deploy to production server (based on workflow conditions).

### Required GitHub Secrets

Set in GitHub repo -> Settings -> Secrets and variables -> Actions:

- `PROD_HOST` - server IP/domain
- `PROD_USER` - deploy user (e.g. `deploy`)
- `PROD_SSH_KEY` - private SSH key content
- `PROD_PORT` - optional SSH port (defaults to 22 in workflow)
- `REPO_URL` - `git@github.com:dewshanhenry/nextjs-mysqld-example.git`
- `APP_DIR` - absolute app path on server (example: `/home/deploy/apps/nextjs-mysql-example`)

SSH Key Setup (Important)

1. Generate deploy key pair (local machine):
   ```bash
   ssh-keygen -t ed25519 -C "gha-deploy" -f ./gha_deploy_key -N ""
   ```
2. Add private key (`gha_deploy_key`) to GitHub secret `PROD_SSH_KEY`.
3. Add public key (`gha_deploy_key.pub`) to server:
   `/home/deploy/.ssh/authorized_keys`
4. Ensure permissions:
   ```bash
   chmod 700 /home/deploy/.ssh
   chmod 600 /home/deploy/.ssh/authorized_keys
   chown -R deploy:deploy /home/deploy/.ssh
   ```

7) Manual Deployment on Server

If you want to deploy without GitHub Actions:

```bash
export REPO_URL="git@github.com:dewshanhenry/nextjs-mysqld-example.git"
export APP_DIR="$HOME/apps/nextjs-mysql-example"
export BRANCH="main"
bash deploy/deploy.sh
```

8) Troubleshooting

- **Deploy job skipped**
  - check workflow trigger/event and deploy job `if` condition
  - ensure workflow file changes are on `main`
- SSH auth failed (`handshake failed`)**
  - wrong `PROD_USER`, wrong `PROD_SSH_KEY`, or missing server `authorized_keys`
- **MySQL env changes not applied**
  - DB init vars are used only on first volume initialization
- **Docker permission denied**
  - relogin after adding user to `docker` group

Security Checklist

- Do not commit `.env`
- Use strong random DB passwords
- Use non-root deploy user
- Restrict firewall to required ports only
- Rotate SSH deploy keys periodically
