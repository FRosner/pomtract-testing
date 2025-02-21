from fastapi import FastAPI, HTTPException
from storage import TenantStorage
from prometheus_client import Gauge, generate_latest
from fastapi.responses import Response

app = FastAPI(title="Tenant Management API")
tenant_storage = TenantStorage()

TENANT_COUNT = Gauge('tenant_count', 'Number of tenants in the system',
                    labelnames=[])
TENANT_COUNT.set_function(lambda: len(tenant_storage.tenants))

@app.post("/tenants/{tenant_id}")
async def create_tenant(tenant_id: str):
    if tenant_storage.tenant_exists(tenant_id):
        raise HTTPException(status_code=409, detail="Tenant already exists")
    return tenant_storage.add_tenant(tenant_id)

@app.get("/tenants")
async def list_tenants():
    return tenant_storage.list_tenants()

@app.delete("/tenants/{tenant_id}")
async def delete_tenant(tenant_id: str):
    if not tenant_storage.delete_tenant(tenant_id):
        raise HTTPException(status_code=404, detail="Tenant not found")
    return {"status": "success"}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
