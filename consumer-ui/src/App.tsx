import { useState, useEffect } from 'react'
import './App.css'
import { TenantService } from './services/TenantService'

interface Tenant {
  id: string
}

const tenantService = new TenantService(''); // Empty base URL for same-origin requests

function App() {
  const [tenants, setTenants] = useState<Tenant[]>([])
  const [newTenantId, setNewTenantId] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    fetchTenants()
  }, [])

  const fetchTenants = async () => {
    try {
      const data = await tenantService.listTenants()
      setTenants(data)
      setError('')
    } catch (err) {
      setError('Failed to load tenants')
      console.error(err)
    }
  }

  const addTenant = async () => {
    if (!newTenantId.trim()) {
      setError('Please enter a tenant ID')
      return
    }

    try {
      await tenantService.createTenant(newTenantId)
      await fetchTenants()
      setNewTenantId('')
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create tenant')
      console.error(err)
    }
  }

  const deleteTenant = async (tenantId: string) => {
    try {
      await tenantService.deleteTenant(tenantId)
      await fetchTenants()
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete tenant')
      console.error(err)
    }
  }

  return (
    <div className="container">
      <h1>Tenant Management</h1>
      
      <div className="add-tenant-form">
        <input
          type="text"
          value={newTenantId}
          onChange={(e) => setNewTenantId(e.target.value)}
          placeholder="Enter tenant ID"
        />
        <button onClick={addTenant}>Add Tenant</button>
      </div>

      {error && <div className="error-message">{error}</div>}

      <div className="tenants-list">
        <h2>Tenants</h2>
        {tenants.length === 0 ? (
          <p>No tenants found</p>
        ) : (
          <ul>
            {tenants.map((tenant) => (
              <li key={tenant.id}>
                {tenant.id}
                <button 
                  onClick={() => deleteTenant(tenant.id)}
                  className="delete-button"
                >
                  Delete
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}

export default App
