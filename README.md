# Biffy [![CI](https://github.com/winebarrel/Biffy/actions/workflows/ci.yml/badge.svg)](https://github.com/winebarrel/Biffy/actions/workflows/ci.yml)

Biffy is a utility app that shows unread [Gmail](https://mail.google.com/) messages on the menu bar.

The name comes from [biff](https://en.wikipedia.org/wiki/Biff_(Unix)), the Unix mail notification command.

## Features

### Show unread mails in your inbox

![](popover.png)

Clicking a mail opens the thread in your browser and marks it as read.

### Notifications

![](notification.png)

Biffy notifies mails that arrive after launch. Clicking a notification also opens the thread and marks it as read.

### Icon indicates unread mails

| Icon | Status |
| - | - |
| ![](icon-envelope.png) | No unread mails |
| ![](icon-envelope.fill.png) | Unread mails |
| ![](icon-exclamationmark.triangle.png) | Error |

## Configuration

Biffy connects to Gmail via IMAP with an [app password](https://support.google.com/accounts/answer/185833).

1. Turn on 2-Step Verification for your Google account.
2. Create an app password at https://myaccount.google.com/apppasswords.
3. **Right-click menu** > **Settings**, then enter your Gmail address and the app password.

![](settings.png)

| Field | Value |
| - | - |
| Gmail Address | Your Gmail address |
| App Password | The 16-character app password (spaces are removed automatically) |
| Interval (sec) | Polling interval (30 to 3600 seconds) |

The app password is stored in the Keychain.
