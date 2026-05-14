import requests
import json
import uuid
import base64
import binascii
from typing import Any, Generator, Optional

USERNAME = "hak5"
PASSWORD = "zaq1@WSX"
LOGIN_URL = "https://c2.atos-iks.de/api/login"
STREAM_URL_TEMPLATE = "https://c2.atos-iks.de/api/sites/{site_id}/devices/{device_id}/stream"

def _build_login_payload(username: str, password: str) -> dict:
    return {
        "user": {
            "username": username,
            "password": password,
            "passcode": ""
        },
        "changing_pass": False,
        "new_pass": "",
        "new_pass_repeat": "",
        "changing_username": False,
        "newusername": ""
    }


def _build_login_headers() -> dict:
    return {
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "session": uuid.uuid4().hex[:6]
    }


def _build_stream_headers(token: str) -> dict:
    return {
        "Accept": "application/json, text/plain, */*",
        "Authorization": f"Bearer {token}",
        "session": uuid.uuid4().hex[:6]
    }


def authenticate(
    session: Optional[requests.Session] = None,
    username: str = USERNAME,
    password: str = PASSWORD,
    login_url: str = LOGIN_URL,
) -> tuple[requests.Session, str]:
    active_session = session or requests.Session()

    login_response = active_session.post(
        login_url,
        json=_build_login_payload(username, password),
        headers=_build_login_headers(),
    )
    login_response.raise_for_status()

    login_data = login_response.json()
    token = login_data.get("token") or login_data.get("access_token")
    if not token:
        raise ValueError(f"Could not find token in login response: {login_data}")

    return active_session, token


def iter_device_stream(
    site_id: int,
    device_id: int,
    session: Optional[requests.Session] = None,
    token: Optional[str] = None,
    username: str = USERNAME,
    password: str = PASSWORD,
) -> Generator[str, None, None]:
    active_session = session or requests.Session()
    active_token = token

    if not active_token:
        active_session, active_token = authenticate(
            session=active_session,
            username=username,
            password=password,
        )

    stream_url = STREAM_URL_TEMPLATE.format(site_id=site_id, device_id=device_id)
    with active_session.get(
        stream_url,
        headers=_build_stream_headers(active_token),
        stream=True,
    ) as stream_response:
        stream_response.raise_for_status()

        for line in stream_response.iter_lines():
            if line:
                yield line.decode("utf-8")


def _decode_base64_bytes(value: str) -> Optional[bytes]:
    candidate = value.strip()
    if not candidate:
        return None

    if candidate.startswith("data:") and "," in candidate:
        candidate = candidate.split(",", 1)[1].strip()

    try:
        return base64.b64decode(candidate, validate=True)
    except (binascii.Error, ValueError):
        pass

    try:
        return base64.b64decode(candidate)
    except (binascii.Error, ValueError):
        return None


def _find_base64_in_payload(payload: Any) -> Optional[str]:
    if isinstance(payload, str):
        return payload

    if isinstance(payload, dict):
        preferred_keys = (
            "image",
            "frame",
            "snapshot",
            "img",
            "data",
            "payload",
            "content",
        )
        for key in preferred_keys:
            if key in payload:
                found = _find_base64_in_payload(payload[key])
                if found:
                    return found

        for value in payload.values():
            found = _find_base64_in_payload(value)
            if found:
                return found

    if isinstance(payload, list):
        for item in payload:
            found = _find_base64_in_payload(item)
            if found:
                return found

    return None


def extract_image_bytes(decoded_line: str) -> Optional[bytes]:
    raw_bytes = _decode_base64_bytes(decoded_line)
    if raw_bytes:
        return raw_bytes

    try:
        payload = json.loads(decoded_line)
    except json.JSONDecodeError:
        return None

    encoded = _find_base64_in_payload(payload)
    if not encoded:
        return None

    return _decode_base64_bytes(encoded)


def fetch_one_image_bytes(
    site_id: int,
    device_id: int,
    session: Optional[requests.Session] = None,
    token: Optional[str] = None,
    username: str = USERNAME,
    password: str = PASSWORD,
    max_lines: int = 200,
) -> bytes:
    for index, decoded_line in enumerate(
        iter_device_stream(
            site_id=site_id,
            device_id=device_id,
            session=session,
            token=token,
            username=username,
            password=password,
        ),
        start=1,
    ):
        image_bytes = extract_image_bytes(decoded_line)
        if image_bytes:
            return image_bytes

        if index >= max_lines:
            break

    raise ValueError("No base64 image found in stream response.")


def iter_device_stream_json(
    site_id: int,
    device_id: int,
    session: Optional[requests.Session] = None,
    token: Optional[str] = None,
    username: str = USERNAME,
    password: str = PASSWORD,
) -> Generator[dict, None, None]:
    for decoded_line in iter_device_stream(
        site_id=site_id,
        device_id=device_id,
        session=session,
        token=token,
        username=username,
        password=password,
    ):
        try:
            yield json.loads(decoded_line)
        except json.JSONDecodeError:
            continue


def fetch_device_stream(site_id: int = 1, device_id: int = 2) -> None:
    # Backward-compatible helper for direct execution.
    print("Connecting to stream...")
    try:
        for decoded_line in iter_device_stream(site_id=site_id, device_id=device_id):
            print(decoded_line)
    except KeyboardInterrupt:
        print("\nStream reading stopped by user.")
    except requests.exceptions.ChunkedEncodingError:
        print("\nConnection broken by the server.")

if __name__ == "__main__":
    fetch_device_stream()