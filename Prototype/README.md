# Whim UI Prototype

This folder is for exploring Whim UI ideas before the production app target exists.

The prototype lets us sketch screens with hardcoded states and sample data while the core module stays focused on domain, persistence, and presentation behavior.

Current prototype:

- `EntryListPrototypeView.swift` sketches the Entry List screen with static list, empty, loading, and error states.
- It does not depend on production `Whim` types.
- It can change freely as the capture/list experience becomes clearer.

When the SwiftUI app target exists, validated ideas can move into production views wired to `EntryListViewModel`.
