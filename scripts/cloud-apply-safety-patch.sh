#!/bin/bash
# Apply Method-1 safety_check patch on cloud (no scp needed). Run in Workbench:
#   cd /root/autoglm-mobile-work && bash cloud-apply-safety-patch.sh
set -eu
cd /root/autoglm-mobile-work

python3 <<'PY'
from pathlib import Path

ROOT = Path("/root/autoglm-mobile-work")
client = ROOT / "Open-AutoGLM/phone_agent/model/client.py"
init_py = ROOT / "Open-AutoGLM/phone_agent/model/__init__.py"
main_py = ROOT / "Open-AutoGLM/main.py"

HELPER = '''
def _env_bool(name: str) -> bool | None:
    raw = os.getenv(name, "").strip().lower()
    if not raw:
        return None
    if raw in ("1", "true", "yes", "on"):
        return True
    if raw in ("0", "false", "no", "off"):
        return False
    return None


def build_model_extra_body(extra: dict[str, Any] | None = None) -> dict[str, Any]:
    """Build Zhipu/AutoGLM extra_body from env (safety_check, sensitive_filter, JSON)."""
    body: dict[str, Any] = dict(extra or {})

    for env_name, key in (
        ("AUTOGLM_SAFETY_CHECK", "safety_check"),
        ("PHONE_AGENT_SAFETY_CHECK", "safety_check"),
        ("AUTOGLM_SENSITIVE_FILTER", "sensitive_filter"),
        ("PHONE_AGENT_SENSITIVE_FILTER", "sensitive_filter"),
    ):
        value = _env_bool(env_name)
        if value is not None:
            body[key] = value

    raw_json = os.getenv("AUTOGLM_MODEL_EXTRA_BODY") or os.getenv(
        "PHONE_AGENT_MODEL_EXTRA_BODY"
    )
    if raw_json:
        body.update(json.loads(raw_json))

    return body


'''

text = client.read_text(encoding="utf-8")
if "build_model_extra_body" not in text:
    anchor = "from phone_agent.config.i18n import get_message\n"
    if anchor not in text:
        raise SystemExit("client.py layout unexpected; upload client.py manually")
    text = text.replace(anchor, anchor + "\n" + HELPER)
    print("patched: added build_model_extra_body to client.py")
else:
    print("skip: build_model_extra_body already in client.py")

if "Observe: model extra_body=" not in text:
    old = "        time_to_thinking_end = None\n\n        stream = self.client.chat.completions.create("
    new = (
        "        time_to_thinking_end = None\n\n"
        "        if self.config.extra_body:\n"
        '            print(f"Observe: model extra_body={self.config.extra_body}")\n\n'
        "        stream = self.client.chat.completions.create("
    )
    if old not in text:
        raise SystemExit("client.py stream block unexpected; upload client.py manually")
    text = text.replace(old, new)
    print("patched: extra_body log in client.py")

if 'finish_reason == "sensitive"' not in text:
    old = "            if len(chunk.choices) == 0:\n                continue\n            if chunk.choices[0].delta.content is not None:"
    new = (
        "            if len(chunk.choices) == 0:\n                continue\n"
        '            finish_reason = getattr(chunk.choices[0], "finish_reason", None)\n'
        '            if finish_reason == "sensitive":\n'
        "                raise ValueError(\n"
        '                    "Model response blocked by content safety (finish_reason=sensitive). "\n'
        '                    "Try AUTOGLM_SAFETY_CHECK=false and AUTOGLM_SENSITIVE_FILTER=false."\n'
        "                )\n"
        "            if chunk.choices[0].delta.content is not None:"
    )
    if old not in text:
        raise SystemExit("client.py chunk loop unexpected; upload client.py manually")
    text = text.replace(old, new)
    print("patched: sensitive finish_reason handling in client.py")

client.write_text(text, encoding="utf-8")

init_py.write_text(
    '"""Model client module for AI inference."""\n\n'
    "from phone_agent.model.client import ModelClient, ModelConfig, build_model_extra_body\n\n"
    '__all__ = ["ModelClient", "ModelConfig", "build_model_extra_body"]\n',
    encoding="utf-8",
)
print("patched: __init__.py")

main_text = main_py.read_text(encoding="utf-8")
if "build_model_extra_body" not in main_text:
    main_text = main_text.replace(
        "from phone_agent.model import ModelConfig\n",
        "from phone_agent.model import ModelConfig, build_model_extra_body\n",
    )
    old_cfg = (
        "    model_config = ModelConfig(\n"
        "        base_url=args.base_url,\n"
        "        model_name=args.model,\n"
        "        api_key=args.apikey,\n"
        "        lang=args.lang,\n"
        "    )"
    )
    new_cfg = (
        "    model_config = ModelConfig(\n"
        "        base_url=args.base_url,\n"
        "        model_name=args.model,\n"
        "        api_key=args.apikey,\n"
        "        lang=args.lang,\n"
        "        extra_body=build_model_extra_body(),\n"
        "    )"
    )
    if old_cfg not in main_text:
        raise SystemExit("main.py ModelConfig block unexpected; upload main.py manually")
    main_text = main_text.replace(old_cfg, new_cfg)
    print("patched: main.py")
else:
    print("skip: main.py already patched")

main_py.write_text(main_text, encoding="utf-8")
print("OK: safety patch applied on disk")
PY

C=autoglm-mobile-copilot
docker cp Open-AutoGLM/phone_agent/model/client.py "$C:/app/Open-AutoGLM/phone_agent/model/client.py"
docker cp Open-AutoGLM/phone_agent/model/__init__.py "$C:/app/Open-AutoGLM/phone_agent/model/__init__.py"
docker cp Open-AutoGLM/main.py "$C:/app/Open-AutoGLM/main.py"

docker compose restart
sleep 10
docker compose ps
docker exec "$C" adb connect "${ADB_CONNECT_ADDRESS:-100.x.x.x:5555}" || true
docker exec "$C" adb devices -l || true

echo "Verify:"
grep build_model_extra_body Open-AutoGLM/phone_agent/model/client.py | head -1
grep -E 'AUTOGLM_SAFETY|AUTOGLM_SENSITIVE' server/.env.cloud || true
echo "Done. Run a REAL task and look for: Observe: model extra_body=..."

