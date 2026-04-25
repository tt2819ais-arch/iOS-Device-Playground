#!/usr/bin/env python3
"""Edit project.yml in place to remove the widget extension target.

Used by the signed-build CI path because the user's single provisioning
profile does not cover the widget bundle id.
"""
import re
import sys
import pathlib

PATH = pathlib.Path(__file__).resolve().parent.parent / "project.yml"
text = PATH.read_text()

# Drop the dependency block on the main app
text = re.sub(
    r"\n    dependencies:\n      - target: DevicePlaygroundWidgets\n        embed: true\n",
    "\n",
    text,
)

# Drop the widget extension target stanza (everything from the
# "  DevicePlaygroundWidgets:" header to the end of file, since it is the
# last target).
text = re.sub(
    r"\n  DevicePlaygroundWidgets:\n[\s\S]*",
    "\n",
    text,
)

# Strip the live-activity Info.plist keys that imply an embedded widget,
# keeping the build valid even without the extension. We don't need to
# remove DynamicIslandSection.swift — Activity<Attrs>.request() will just
# fail at runtime in the absence of the widget, and the in-app preview
# still works.
PATH.write_text(text)
print("patched", PATH)
