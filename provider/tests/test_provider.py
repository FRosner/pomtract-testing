from __future__ import annotations

import threading
import time
from typing import TYPE_CHECKING, Any, Optional

import pytest
import uvicorn
from pydantic import BaseModel
from yarl import URL

from pact.v3 import Verifier

from main import app, tenant_storage

if TYPE_CHECKING:
    from collections.abc import Generator

PROVIDER_URL = URL("http://localhost:8080")
PACTS_DIR = "pacts"


class ProviderState(BaseModel):
    consumer: str
    state: str


def state_handler(
    state: str,
    params: Optional[dict[str, Any]],
):
    mapping = {
        "a tenant exists": mock_tenant_exists,
    }
    print(f"Setting state '{state}' using params '{params}'")
    mapping[state](params)


class ServerThread(threading.Thread):
    def run(self):
        host = PROVIDER_URL.host if PROVIDER_URL.host else "localhost"
        port = PROVIDER_URL.port if PROVIDER_URL.port else 8080
        uvicorn.run(app, host=host, port=port)


@pytest.fixture(scope="module")
def verifier() -> Generator[Verifier, Any, None]:
    server_thread = ServerThread(daemon=True)
    verifier = Verifier("TenantManagementAPI").add_transport(url="http://localhost:8080")
    server_thread.start()
    time.sleep(2)
    yield verifier


def mock_tenant_exists(params: Optional[dict[str, Any]]) -> None:
    tenant_id = params.get("tenantId")
    tenant_storage.add_tenant(tenant_id)


def test_against_local_pact(verifier: Verifier) -> None:
    pact_file = f"{PACTS_DIR}/TenantManagementUI-TenantManagementAPI.json"
    verifier.add_source(pact_file)
    verifier.state_handler(state_handler)
    verifier.verify()
