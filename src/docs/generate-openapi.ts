import { OpenApiGeneratorV3 } from '@asteasolutions/zod-to-openapi';
import { registry } from './openapi.registry';
import * as fs from 'fs';
import * as yaml from 'js-yaml';

// Import all route files to ensure they are registered
import '@/routes/v1';

const generator = new OpenApiGeneratorV3(registry.definitions);

const openapi = generator.generateDocument({
  openapi: '3.0.0',
  info: {
    title: 'NOVA CRM API',
    version: '1.0.0',
    description: 'API documentation for the NOVA CRM application.',
  },
  servers: [{ url: '/api/v1' }],
});

const yamlString = yaml.dump(openapi);

fs.writeFileSync('./docs/api/openapi.yaml', yamlString, 'utf8');

console.log('✅ OpenAPI specification generated successfully.');
