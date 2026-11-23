# shatel-monitor

A small Windows tool that checks how much mobile internet is left on a Shatel Mobile SIM every 30 minutes and shows a Windows notification when it drops below 500 MB.

Unofficial. Not affiliated with or endorsed by Shatel Mobile. It calls the same endpoint the my.shatelmobile.ir self-care page uses, so it can break whenever that site changes.

## Requirements

- Windows 10 or 11 with Windows PowerShell 5.1 and the built-in `curl.exe` (both ship with Windows)
- A Shatel Mobile self-care account

## Setup

1. Clone or download this folder.
2. Log in at https://my.shatelmobile.ir, open DevTools (F12) → Application → Cookies → `https://my.shatelmobile.ir`, and copy the value of the `session` cookie into a file named `session.txt` in this folder.
3. Put your number (as shown in the self-care number selector, without the leading 0, e.g. `9xxxxxxxxx`) into `msisdn.txt`.
4. Check it works. This forces an alert, so you should see a notification:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\check.ps1 -ThresholdMB 999999
   ```
5. Install the scheduled task:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```

`session.txt`, `msisdn.txt` and `log.txt` are git-ignored. The session cookie is a login credential: don't share it.

## What it does

- Runs every 30 minutes, plus 2 minutes after you sign in to Windows. It runs on battery too and catches up after sleep.
- Sums `remained` across all your active internet packages.
- **🚨 Shatel internet low**: total is below the threshold (500 MB by default).
- **❌ Shatel check failed**: the server couldn't be reached, or the session expired. For the second, copy a fresh `session` cookie into `session.txt`.
- Appends one line per run to `log.txt`.

Notifications need a signed-in desktop session, so nothing runs while the PC is off or nobody is signed in.

## Options

```powershell
.\check.ps1 -ThresholdMB 1000   # different threshold, for a manual run
.\check.ps1 -SelfTest           # checks the MB/GB/KB parsing
```

To change the threshold for the scheduled task, change the default in `check.ps1`.

## Uninstall

```powershell
Unregister-ScheduledTask 'Shatel Remaining Check' -Confirm:$false
```

## API notes

`POST https://my.shatelmobile.ir/remained` with headers `X-Requested-With: XMLHttpRequest`, `Content-Type: application/json`, cookie `session=<token>` and body `{"msisdn":"<number>"}`. A GET returns 404 and a POST without the body returns 500. The response JSON has `credit`, `internet_packages[]` (`name`, `remained`, `expire`, `status`, ...) and the same for SMS and voice. Sizes are strings with Persian units, e.g. `"10,240 مگابایت"`.

## License

MIT
