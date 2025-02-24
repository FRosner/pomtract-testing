# Tenant Management UI

## Local Development

Install the dependencies and build the project.

```bash
npm install
npm build
```

For local development, you can use the pact mock service to mock the API. First, run the pact tests to generate the contracts.

```bash
npm test
```

Then, run the stub server.

```bash
docker run -it -p 8000:8000 \
  -v "$(pwd)/pacts/:/app/pacts" \
  pactfoundation/pact-stub-server -p 8000 -d pacts
```

Then start the UI (in another terminal, unless you are running the container in detached mode).

```bash
npm run dev
```