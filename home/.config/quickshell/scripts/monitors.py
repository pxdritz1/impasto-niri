#!/usr/bin/env python3
"""Read connected Niri outputs through the compositor IPC.

Persistent display profiles belong to Kanshi or the user's Niri KDL. This
helper is intentionally read-only: output IPC changes are temporary and this
shell must not overwrite a user's display configuration.
"""
import json
import subprocess
import sys


def refresh_hz(value):
    if value is None:
        return 0.0
    return round(float(value) / 1000.0, 3)


def read_outputs():
    try:
        result = subprocess.run(
            ["niri", "msg", "--json", "outputs"],
            check=True, capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.SubprocessError) as error:
        raise RuntimeError(f"cannot query Niri outputs: {error}") from error

    payload = json.loads(result.stdout)
    if isinstance(payload, dict) and "Err" in payload:
        raise RuntimeError(str(payload["Err"]))
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

        modes = output.get("modes") or []
        current_index = output.get("current_mode")
        current_mode = None
        if isinstance(current_index, int) and 0 <= current_index < len(modes):
            current_mode = modes[current_index]
        elif isinstance(current_index, dict):
            current_mode = current_index

        logical = output.get("logical") or {}
        make = output.get("make") or ""
        model = output.get("model") or ""
        serial = output.get("serial") or ""
        description = " ".join(part for part in (make, model, serial) if part).strip()
        if not description:
            description = name

        physical_width = int((current_mode or {}).get("width") or 0)
        physical_height = int((current_mode or {}).get("height") or 0)
        width = int(logical.get("width") or 0)
        height = int(logical.get("height") or 0)
        refresh = refresh_hz((current_mode or {}).get("refresh_rate"))

        resolutions = {}
        for candidate in modes:
            if not isinstance(candidate, dict):
                continue
            w = int(candidate.get("width") or 0)
            h = int(candidate.get("height") or 0)
            rate = refresh_hz(candidate.get("refresh_rate"))
            if not w or not h:
                continue
            key = f"{w}x{h}"
            resolutions.setdefault(key, {"width": w, "height": h, "refreshes": []})
            if rate:
                resolutions[key]["refreshes"].append(rate)

        mode_label = f"{physical_width}x{physical_height}" if physical_width and physical_height else "off"
        if refresh:
            mode_label += f"@{refresh:.3f}"

        rows.append({
            "name": name,
            "description": description,
            "make": make,
            "model": model,
            "serial": serial or "",
            "x": int(logical.get("x") or 0),
            "y": int(logical.get("y") or 0),
            "width": width,
            "height": height,
            "refreshRate": refresh,
            "mode": mode_label,
            "scale": float(logical.get("scale") or 1),
            "transform": str(logical.get("transform") or "Normal"),
            "disabled": output.get("logical") is None,
            "vrr": bool(output.get("vrr_enabled", False)),
            "vrrSupported": bool(output.get("vrr_supported", False)),
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
