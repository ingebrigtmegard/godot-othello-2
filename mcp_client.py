#!/usr/bin/env python3
"""Client for Godot MCP Pro plugin on port 6505."""
import asyncio
import json
import sys
import websockets

MCP_URI = "ws://127.0.0.1:6505"
request_id = 0

async def mcp_call(method, params=None):
    """Send an MCP command and return the parsed response."""
    global request_id
    request_id += 1
    msg = {"jsonrpc": "2.0", "id": request_id, "method": method}
    if params is not None:
        msg["params"] = params
    await ws.send(json.dumps(msg))
    raw = await ws.recv()
    resp = json.loads(raw)
    if "error" in resp:
        raise Exception(f"MCP Error: {resp['error']}")
    return resp.get("result", {})

async def main():
    global ws
    ws = await websockets.connect(MCP_URI)
    try:
        method = sys.argv[1] if len(sys.argv) > 1 else "help"

        if method == "play":
            result = await mcp_call("play_scene", {"mode": "current"})
            print(json.dumps(result, indent=2))
        elif method == "screenshot":
            result = await mcp_call("get_game_screenshot")
            print(f"Screenshot: {result.get('width')}x{result.get('height')} (base64: {len(result.get('image_base64',''))} chars)")
        elif method == "click":
            x = float(sys.argv[2]) if len(sys.argv) > 2 else 0
            y = float(sys.argv[3]) if len(sys.argv) > 3 else 0
            result = await mcp_call("simulate_mouse_click", {"x": x, "y": y})
            print(json.dumps(result, indent=2))
        elif method == "stop":
            result = await mcp_call("stop_scene")
            print(json.dumps(result, indent=2))
        elif method == "scene_tree":
            result = await mcp_call("get_scene_tree", {"max_depth": 5})
            print(json.dumps(result, indent=2))
        elif method == "help":
            print("Usage: python mcp_client.py <command> [args]")
            print("Commands: play, screenshot, click <x> <y>, stop, scene_tree")
        else:
            result = await mcp_call(method)
            print(json.dumps(result, indent=2))
    finally:
        await ws.close()

if __name__ == "__main__":
    asyncio.run(main())
