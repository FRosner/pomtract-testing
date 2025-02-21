import { useState, useEffect } from 'react'
import './App.css'

interface Tenant {
  id: string
  // Add other tenant properties if they exist in your API response
}

function App() {
  const [tenants, setTenants] = useState<Tenant[]>([])
  const [newTenantId, setNewTenantId] = useState('')
  const [error, setError] = useState('')

  // Fetch tenants on component mount
  useEffect(() => {
    fetchTenants()
  }, [])

  const fetchTenants = async () => {
    try {
      const response = await fetch('/tenants')
      if (!response.ok) throw new Error('Failed to fetch tenants')
      const data = await response.json()
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
      const response = await fetch(`/tenants/${newTenantId}`, {
        method: 'POST',
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.detail || 'Failed to create tenant')
      }

      await fetchTenants() // Refresh the list
      setNewTenantId('') // Clear the input
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create tenant')
      console.error(err)
    }
  }

  const deleteTenant = async (tenantId: string) => {
    try {
      const response = await fetch(`/tenants/${tenantId}`, {
        method: 'DELETE',
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.detail || 'Failed to delete tenant')
      }

      await fetchTenants() // Refresh the list
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete tenant')
      console.error(err)
    }
  }

  return (
    <div className="container">
      <h1>Tenant Management</h1>
      
      {/* Add Tenant Form */}
      <div className="add-tenant-form">
        <input
          type="text"
          value={newTenantId}
          onChange={(e) => setNewTenantId(e.target.value)}
          placeholder="Enter tenant ID"
        />
        <button onClick={addTenant}>Add Tenant</button>
      </div>

      {/* Error Display */}
      {error && <div className="error-message">{error}</div>}

      {/* Tenants List */}
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
