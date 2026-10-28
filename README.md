# Biffy [![CI](https://github.com/winebarrel/Biffy/actions/workflows/ci.yml/badge.svg)](https://github.com/winebarrel/Biffy/actions/workflows/ci.yml) [![AI Generated](https://img.shields.io/badge/AI%20Generated-Claude-orange?logo=anthropic)](https://claude.ai/claude-code)

Biffy is a utility app that shows unread [Gmail](https://mail.google.com/) messages on the menu bar.

The name comes from [biff](https://en.wikipedia.org/wiki/Biff_(Unix)), the Unix mail notification command.

## Features

### Show unread mails in your inbox

![](https://github.com/user-attachments/assets/3cd358e2-6416-41fd-8d78-e3c3a69cfb6c)

Clicking a mail opens the thread in your browser and marks it as read.

### Notifications

![](https://github.com/user-attachments/assets/1b87c2d7-6cc0-4e00-ba58-1b016ac45fd8)

Biffy notifies mails that arrive after launch. Clicking a notification also opens the thread and marks it as read.

### Icon indicates unread mails

| Icon | Status |
| - | - |
| ![](https://github.com/user-attachments/assets/b6b00723-aa3c-46a4-b974-4c5c659494a7) | No unread mails |
| ![](https://github.com/user-attachments/assets/2f09d526-f551-495b-9cb1-4514ac5f22b6) | Unread mails |
| ![](https://github.com/user-attachments/assets/7b54b770-4426-4ef9-9235-5a5fd43bbf9d) | Error |

## Configuration

Biffy connects to Gmail via IMAP with an [app password](https://support.google.com/accounts/answer/185833).

1. Turn on 2-Step Verification for your Google account.
2. Create an app password at https://myaccount.google.com/apppasswords.
3. **Right-click menu** > **Settings**, then enter your Gmail address and the app password.

![](https://github.com/user-attachments/assets/0d8f22ca-64ee-4fc3-b53d-94db7a4cfd80)

| Field | Value |
| - | - |
| Gmail Address | Your Gmail address |
| App Password | The 16-character app password (spaces are removed automatically) |
| Interval (sec) | Polling interval (30 to 3600 seconds) |

The app password is stored in the Keychain.
