import { OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';
import { registry } from './openapi.registry';
import * as fs from 'fs';
import * as yaml from 'js-yaml';

// Import module docs to register paths
import '@/modules/auth/auth.docs';
import '@/modules/users/users.docs';

const generator = new OpenApiGeneratorV3(registry.definitions);

const openapi = generator.generateDocument({
  openapi: '3.0.0',
  info: {
    title: 'Nova Travel API',
    version: '1.0.0',
    description: 'API documentation for the Nova Travel application.',
  },
  servers: [{ url: '/api/v1' }],
});

const yamlString = yaml.dump(openapi);

fs.writeFileSync('./docs/api/openapi.yaml', yamlString, 'utf8');

console.log('✅ OpenAPI specification generated successfully.');
