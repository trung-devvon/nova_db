import { OpenAPIRegistry } from '@asteasolutions/zod-to-openapi';

export const registry = new OpenAPIRegistry();

// The library will automatically register schemas used in `registerPath`.
// Manual registration is only needed for advanced cases or schemas not directly used in a path.
