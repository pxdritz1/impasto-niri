#!/usr/bin/env python3
"""Read connected Niri outputs through the compositor IPC.

Persistent display profiles belong to Kanshi or the user's Niri KDL. This
helper is intentionally read-only: output IPC changes are temporary and this
shell must not overwrite a user's display configuration.
"""
import json
import subprocess
import sys


def read_outputs():
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "outputs"],
            check=True, capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.SubprocessError) as error:
        raise RuntimeError(f"cannot query Niri outputs: {error}") from error

    payload = json.loads(result.stdout)
    if isinstance(payload, dict) and "Ok" in payload:
        payload = payload["Ok"]
    if isinstance(payload, dict) and "Outputs" in payload:
        payload = payload["Outputs"]
    if not isinstance(payload, dict):
        raise RuntimeError("unexpected response from niri msg outputs")

    rows = []
    for name, output in payload.items():
        if not isinstance(output, dict):
            continue
        logical = output.get("logical") or {}
        mode = output.get("current_mode") or output.get("currentMode") or {}
        modes = output.get("modes") or output.get("available_modes") or []
        make = output.get("make") or ""
        model = output.get("model") or ""
        serial = output.get("serial") or ""
        description = " ".join(part for part in (make, model, serial) if part).strip()
        if not description:
            description = name

        width = int(logical.get("width") or mode.get("width") or 0)
        height = int(logical.get("height") or mode.get("height") or 0)
        refresh = float(mode.get("refresh_rate") or mode.get("refreshRate") or 0)
        resolutions = {}
        for candidate in modes:
            if not isinstance(candidate, dict):
                continue
            w = int(candidate.get("width") or 0)
            h = int(candidate.get("height") or 0)
            rate = float(candidate.get("refresh_rate") or candidate.get("refreshRate") or 0)
            if not w or not h:
                continue
            key = f"{w}x{h}"
            resolutions.setdefault(key, {"width": w, "height": h, "refreshes": []})
            if rate:
                resolutions[key]["refreshes"].append(round(rate / 1_000_000, 3)
                    if rate > 100000 else round(rate, 3))

        rows.append({
            "name": name,
            "description": description,
            "make": make,
            "model": model,
            "serial": serial,
            "x": int(logical.get("x") or 0),
            "y": int(logical.get("y") or 0),
            "width": width,
            "height": height,
            "refreshRate": round(refresh / 1_000_000, 3) if refresh > 100000 else round(refresh, 3),
            "mode": f"{width}x{height}" if width and height else "unknown",
            "scale": float(output.get("scale") or 1),
            "transform": str(output.get("transform") or "Normal"),
            "disabled": False,
            "dpms": True,
            "focused": bool(output.get("is_focused") or output.get("focused")),
            "mirror": "none",
            "resolutions": list(resolutions.values()),
        })
    return rows


def main():
    if len(sys.argv) != 2 or sys.argv[1] != "get":
        print("Usage: monitors.py get", file=sys.stderr)
        return 2
    try:
        print(json.dumps(read_outputs()))
    except (ValueError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
