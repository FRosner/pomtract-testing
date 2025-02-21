import {MatchersV3, PactV4, SpecificationVersion} from '@pact-foundation/pact';
import {TenantService} from './TenantService';
import * as path from "node:path";

const provider = new PactV4({
  consumer: 'TenantManagementUI',
  provider: 'TenantManagementAPI',
  dir: path.resolve(process.cwd(), 'pacts'),
  logLevel: 'info',
  spec: SpecificationVersion.SPECIFICATION_VERSION_V4,
});

describe('Tenant API Contract Tests', () => {
  describe('GET /tenants', () => {
    it('returns the list of tenants', async () => {
      const tenantId = 'tenant-1';
      await provider
        .addInteraction()
        .given('a tenant exists', { tenantId: tenantId })
        .uponReceiving('a request for all tenants')
        .withRequest('GET', '/tenants', (builder) => {
          builder.headers({'Accept': 'application/json'})
        })
        .willRespondWith(200, (builder) => {
          builder.headers({'Content-Type': 'application/json'})
          builder.jsonBody(
              MatchersV3.eachLike({
                id: tenantId
              })
          );
        })
        .executeTest(async mockServer => {
          const tenantService = new TenantService(mockServer.url);
          const response = await tenantService.listTenants();
          expect(response).toBeDefined()
          expect(Array.isArray(response)).toBeTruthy()
        });
    });
  });
});