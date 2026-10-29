# Ubuntu / KDE Neon setup

Scripted setup for a CSW company laptop running KDE Neon (Ubuntu 24.04 LTS
base), covering compliance agents, packages, dotfiles and the PSPS work
environment.

The root `README.md` covers the Arch setup; this directory covers Ubuntu.

## Scope

Two sources feed a new machine:

| | This repo | Backup archive |
|---|---|---|
| Holds | general configs, package lists, these scripts | secrets, credentials, personal files |
| Moves by | `git clone` + `stow` | pendrive, decrypted and copied in |
| Public | yes | kept off the network entirely |

Keys, tokens and internal hostnames belong in the backup archive. The repo is
public.

## Phase 0 - before the wipe

On the machine being replaced:

```sh
./track-configs.sh --dry-run          # review what moves
./track-configs.sh                    # move general configs into the repo
# review the secret scan and the diff, then commit and push

./backup.sh -o /media/$USER/<pendrive>
```

`backup.sh` writes `csw-backup-<date>.tar.zst.gpg` plus a checksum, driven by
`backup-manifest.txt`. Firefox bookmarks are exported to `bookmarks.html`
straight from `places.sqlite`, so Firefox may stay open. Paths prefixed with
`!` in the manifest are left out of the archive; the working repositories under
`~/Code` are cloned from their remotes instead.

Also collect:

- a Ventoy drive holding the KDE Neon ISO

## Phase 1 - installation

Boot Ventoy and pick the Neon ISO. In the live session, read the serial the
hostname is built from:

```sh
sudo dmidecode -s system-serial-number
```

- **Disk setup > Advanced features > Use LVM and encryption.** Required for
  network access. The passphrase is typed at every cold boot and goes into
  Vault; losing it loses the disk.
- **Username = AD UPN prefix** (`f-troitero`, the part before `@` in the
  myaccount.microsoft.com sign-in name).
- **Hostname = `LPT-<serial>-LX`.**

## Phases 2-6 - scripted

```sh
git clone https://github.com/MrFacundo/dotfiles.git ~/dotfiles
cd ~/dotfiles/ubuntu
cp compliance.env.example compliance.env   # fill from the intranet KB
./install.sh --restore /media/$USER/<pendrive>/csw-backup-<date>.tar.zst.gpg
```

| Phase | Script | Does |
|---|---|---|
| 2 | `00-bootstrap.sh` | system update, core tools, hostname check, dotfiles clone |
| 3 | `10-compliance.sh` | FortiClient ZTNA, Rapid7 Insight Agent, Defender for Endpoint |
| 4 | `20-packages.sh` | apt, third-party repos, flatpak, cargo, node, hand-installed binaries, docker group, bluetooth and syncthing services |
| 5 | `30-configure.sh` | oh-my-zsh, LazyVim, stow, kwinrc, Firefox, Claude skills |
| 6 | `40-restore.sh` | unpack the backup, fix permissions, print the remaining checklist |

`install.sh --skip <phase>`, `--only <phase>` and `--list` all work. Every
script is idempotent and re-running one picks up where it left off.

## Phase 7 - PSPS work environment

```sh
./50-psps.sh
```

Clones the CODAC repositories, creates `env.sh` and `.env` from their defaults,
normalises CRLF line endings in the shell scripts, installs the client
certificates into `coa-psps-protocol/secrets`, and installs the webapp
dependencies against node 20.18.0.

It then prints the build commands and the Requestly rule, which need a human.

## Phase 8 - manual checklist

- [ ] reboot
- [ ] FortiClient: enter the Zero Trust Telemetry code, sign in to Azure AD,
      confirm the client reads Connected
- [ ] verify the agents: `systemctl status ir_agent.service`, `mdatp health`
- [ ] KDE Store KWin scripts and effects: krohnkite, geometry change
      (the panel widgets are installed by `30-configure.sh`)
- [ ] apply the Plasma global theme
- [ ] `ccss` for the VS Code custom CSS permissions
- [ ] `gh auth status`
- [ ] printer, bluetooth, kdeconnect pairing
- [ ] first Timeshift snapshot
- [ ] browser sign-ins and the Requestly rule

## Files

| File | Purpose |
|---|---|
| `install.sh` | runs the phases in order |
| `packages-ubuntu.sh` | package lists, split by install source |
| `backup-manifest.txt` | what the backup holds and where each entry is restored |
| `backup.sh` | builds the encrypted archive |
| `export-bookmarks.py` | `places.sqlite` to `bookmarks.html` |
| `track-configs.sh` | moves general configs into the repo and re-stows |
| `../scripts/install-plasmoids.sh` | installs the panel's third-party widgets at pinned tags |
| `compliance.env.example` | template for the agent tokens and URLs |

## Compliance secrets

`10-compliance.sh` reads `ubuntu/compliance.env`: the Rapid7 token, the signed
blob URLs for the Rapid7 `.deb` and the Defender onboarding script, and the
FortiClient registration code. All of it comes from the Help Desk Knowledge
Base, which requires an authenticated session. The file is gitignored.

## Packages

`packages-ubuntu.sh` groups packages by where they come from: the Ubuntu and
Neon archives, third-party apt repositories, PPAs, flatpak, cargo, npm, and a
set installed by hand in `20-packages.sh`.

`zen` and `insomnia` are fetched from their own sources into `~/.local/opt`
or `/opt`. `20-packages.sh` reports which are still missing.

`cliamp` and `nchat` install through their upstream scripts
(`cliamp.stream/install.sh`, `d99kris/nchat/utils/install.sh`), both into
`~/.local/bin`.

cliamp reads its client IDs from `~/.config/cliamp/.env`, gitignored and
backed up:

```env
CLIAMP_SPOTIFY_CLIENT_ID=
CLIAMP_YTMUSIC_CLIENT_ID=
CLIAMP_YTMUSIC_CLIENT_SECRET=
```

## Ubuntu specifics

- `bat` and `fd` ship as `batcat` and `fdfind`. `30-configure.sh` generates
  `~/.oh-my-zsh/custom/ubuntu.zsh` with aliases restoring the usual names;
  that file is generated per machine and stays out of the repo.
- Firefox comes from the mozillateam PPA, pinned above the snap transitional
  package.
- Containers: `docker.io` with `docker-compose`, alongside `podman`.
- The KWin effects and scripts come from the KDE Store.
