from fastapi import FastAPI, HTTPException
from storage import TenantStorage

app = FastAPI(title="Tenant Management API")
tenant_storage = TenantStorage()

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
