from __future__ import annotations

import os
import threading
import time
from typing import TYPE_CHECKING, Any, Optional
import tomli
import git

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


def get_version() -> str:
    with open("pyproject.toml", "rb") as f:
        pyproject = tomli.load(f)
        pkg_version = pyproject["project"]["version"]
    repo = git.Repo(search_parent_directories=True)
    sha = repo.head.object.hexsha[:7]
    return f"{pkg_version}+{sha}"


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
    if os.getenv("PACT_PUBLISH_VERIFICATION_RESULTS", "").lower() == "true":
        print(f"Publishing verification results to ${os.getenv('PACT_BROKER_URL')}")
        verifier = verifier.set_publish_options(version=get_version())
    yield verifier


def mock_tenant_exists(params: Optional[dict[str, Any]]) -> None:
    tenant_id = params.get("tenantId")
    tenant_storage.add_tenant(tenant_id)


def test_verify_pacts(verifier: Verifier) -> None:
    pact_broker_url = os.getenv("PACT_BROKER_URL")
    if pact_broker_url:
        verifier.broker_source(pact_broker_url)
    else:
        verifier.add_source(f"{PACTS_DIR}/TenantManagementUI-TenantManagementAPI.json")
    

    verifier.state_handler(state_handler)
    verifier.verify()
