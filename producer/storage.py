from typing import Set
from models import Tenant

class TenantStorage:
    def __init__(self):
        self.tenants: Set[str] = set()

    def add_tenant(self, tenant_id: str) -> Tenant:
        self.tenants.add(tenant_id)
        return Tenant(id=tenant_id)

    def list_tenants(self) -> list[Tenant]:
        return [Tenant(id=tid) for tid in self.tenants]

    def delete_tenant(self, tenant_id: str) -> bool:
        if tenant_id in self.tenants:
            self.tenants.remove(tenant_id)
            return True
        return False

    def tenant_exists(self, tenant_id: str) -> bool:
        return tenant_id in self.tenants