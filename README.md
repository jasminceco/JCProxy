<p align="center">
  <img src="Screenshots/logo.png" alt="JCProxy" width="420"/>
</p>

# JCProxy

A lightweight **in‑app** HTTP proxy/logger for iOS that captures, inspects, and shares network traffic with a clean, developer‑first UI built for mobile teams.

## Why JCProxy
- Capture and inspect every request/response in real time.
- One‑tap sharing and export for collaboration or bug reports.
- Breakpoints to intercept and modify responses before they hit your app.
- Zero backend changes — works entirely on device.

## Highlights
- Live request list with searchable details.
- Rich request/response views (headers, body, cookies, cache data).
- HAR and raw export options.
- Breakpoints for response editing (status/body) and replay.
- Floating overlay launcher (draggable).
- JSON tree viewer with copyable values.
- Localized UI strings (EU languages included).

## Screenshots
- Overlay launcher with unread request badge and drag hint.

  ![Overlay launcher](Screenshots/overlay-drag.png)

- Live request list with status indicators and quick navigation.

  ![Request list](Screenshots/request-list.png)

- Breakpoints manager for response intercepts 

  ![Breakpoints manager](Screenshots/breakpoints-empty.png)

- Breakpoint editor to change status code and response body before continuing.

  ![Breakpoint editor](Screenshots/breakpoint-editor.png)

## Install (Swift Package Manager)
In Xcode: **File → Add Package Dependencies**, then select the product:

```swift
packages:
  JCProxy:
    url: https://github.com/jasminceco/JCProxy
    from: 1.0.0
```

## Usage
Import and enable JCProxy where you bootstrap your app:

```swift
import JCProxy

JCProxyClient.shared.start()
```

## Breakpoints
Set a breakpoint for a specific API and JCProxy will pause the response, letting you:
- Continue as‑is
- Override status code
- Modify response body

This is ideal for testing error states and edge cases without changing the backend.

## Export & Share
From request details you can:
- Share a raw request/response
- Export HAR entries
- Copy large values or full bodies
## Requirements
- iOS 15+
- Xcode 16+

## Coming Soon
- Request breakpoints (edit URL, headers, body).
- Export as cURL.

## Development Status
Under active development. Changes are delivered as time permits.

## License
MIT
