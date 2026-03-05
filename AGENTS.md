# Ping

This is a Swift-based macOS app that helps surface notifications. By reading from the Dock app using the accessibility APIs, we can detect when apps have a notification badge applied (i.e. red dot with either a number, dot, or empty). Based on an app state (e.g. when Slack has a red dot) a user can configure an effect in response (e.g. glowing from a screen edge).

Before declaring any changes finished, be sure that all of the following pass:

```
swift format -irp .
swift build
```
