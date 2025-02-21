export class TenantService {
  private baseUrl: string;
  private headers = {
    'Accept': 'application/json'
  };

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  async listTenants() {
    const response = await fetch(`${this.baseUrl}/tenants`, {
      headers: this.headers
    });
    if (!response.ok) {
      throw new Error(`HTTP Error: ${response.status}`);
    }
    return response.json();
  }

  async createTenant(tenantId: string) {
    const response = await fetch(`${this.baseUrl}/tenants/${tenantId}`, {
      method: 'POST',
      headers: this.headers
    });
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to create tenant');
    }
    return response.json();
  }

  async deleteTenant(tenantId: string) {
    const response = await fetch(`${this.baseUrl}/tenants/${tenantId}`, {
      method: 'DELETE',
      headers: this.headers
    });
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail || 'Failed to delete tenant');
    }
    return response.json();
  }
}